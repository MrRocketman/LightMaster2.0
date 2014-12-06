//
//  SequenceListViewController.m
//  LightMaster
//
//  Created by James Adams on 11/25/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import "SequenceListViewController.h"
#import "CoreDataManager.h"
#import "Sequence.h"
#import "UserAudioAnalysisTrack.h"
#import "UserAudioAnalysisTrackChannel.h"
#import "Audio.h"

@interface SequenceListViewController ()

@property (strong, nonatomic) SNRFetchedResultsController *sequenceFetchedResultsController;
@property (strong, nonatomic) SNRFetchedResultsController *trackFetchedResultsController;
@property (strong, nonatomic) SNRFetchedResultsController *trackChannelFetchedResultsController;

@property (strong, nonatomic) NSOpenPanel *openPanel;

@end

@implementation SequenceListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Sequences
    NSError *error;
    if (![[self sequenceFetchedResultsController] performFetch:&error])
    {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        [[NSApplication sharedApplication] presentError:error];
    }
    
    // Tracks
    error = nil;
    if (![[self trackFetchedResultsController] performFetch:&error])
    {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        [[NSApplication sharedApplication] presentError:error];
    }
    
    // Track Channels
    error = nil;
    if (![[self trackChannelFetchedResultsController] performFetch:&error])
    {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (void)viewWillAppear
{
    [self.sequenceTableView reloadData];
    [self.trackTableView reloadData];
    [self.trackChannelTableView reloadData];
    
    if((Audio *)[[CoreDataManager sharedManager].currentSequence.audio anyObject])
    {
        self.audioDescriptionTextField.stringValue = ((Audio *)[[CoreDataManager sharedManager].currentSequence.audio anyObject]).title;
    }
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (void)keyDown:(NSEvent*)event
{
    NSString* pressedChars = [event characters];
    if([pressedChars length] == 1)
    {
        unichar pressedUnichar =
        [pressedChars characterAtIndex:0];
        
        // Delete key
        if(pressedUnichar == NSDeleteCharacter)
        {
            // Delete sequence
            if (self.sequenceTableView == self.sequenceTableView.window.firstResponder)
            {
                Sequence *sequence = [self.sequenceFetchedResultsController objectAtIndex:self.sequenceTableView.selectedRow];
                [[[CoreDataManager sharedManager] managedObjectContext] deleteObject:sequence];
                [[CoreDataManager sharedManager] saveContext];
                
                if(self.sequenceFetchedResultsController.count == 0)
                {
                    self.createTrackButton.enabled = NO;
                    self.createTrackChannelButton.enabled = NO;
                }
            }
            // Delete track
            else if (self.trackTableView == self.trackTableView.window.firstResponder)
            {
                UserAudioAnalysisTrack *track = [self.trackFetchedResultsController objectAtIndex:self.trackTableView.selectedRow];
                [[[CoreDataManager sharedManager] managedObjectContext] deleteObject:track];
                [[CoreDataManager sharedManager] saveContext];
                
                if(self.trackFetchedResultsController.count == 0)
                {
                    self.createTrackChannelButton.enabled = NO;
                }
            }
            // Delete track channel
            else if (self.trackChannelTableView == self.trackChannelTableView.window.firstResponder)
            {
                UserAudioAnalysisTrackChannel *track = [self.trackChannelFetchedResultsController objectAtIndex:self.trackChannelTableView.selectedRow];
                [[[CoreDataManager sharedManager] managedObjectContext] deleteObject:track];
                [[CoreDataManager sharedManager] saveContext];
            }
        }
        else
        {
            [super keyDown:event];
        }
    }
}

#pragma mark - Buttons

- (IBAction)createSequenceButtonPress:(id)sender
{
    [[CoreDataManager sharedManager] newControlBox];
}

- (IBAction)loadSequenceButtonPress:(id)sender
{
    Sequence *sequence = [self.sequenceFetchedResultsController objectAtIndex:self.sequenceTableView.selectedRow];
    [CoreDataManager sharedManager].currentSequence = sequence;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CurrentSequenceChange" object:nil];
    [self dismissViewController:self];
}

- (IBAction)createTrackButtonPress:(id)sender
{
    [[CoreDataManager sharedManager] newAudioAnalysisTrackForSequence:[self.sequenceFetchedResultsController objectAtIndex:self.sequenceTableView.selectedRow]];
}

- (IBAction)createTrackChannelButtonPress:(id)sender
{
    [[CoreDataManager sharedManager] newAudioAnalysisChannelForTrack:[self.trackFetchedResultsController objectAtIndex:self.trackTableView.selectedRow]];
}

- (IBAction)chooseAudioFileButtonPress:(id)sender
{
    // Load the open panel if neccessary
    if(!self.openPanel)
    {
        self.openPanel = [NSOpenPanel openPanel];
        self.openPanel.canChooseDirectories = NO;
        self.openPanel.canChooseFiles = YES;
        self.openPanel.resolvesAliases = YES;
        self.openPanel.allowsMultipleSelection = NO;
        self.openPanel.allowedFileTypes = @[@"aac", @"aif", @"aiff", @"alac", @"mp3", @"m4a", @"wav"];
        //self.openPanel.directoryURL = [NSURL fileURLWithPathComponents:@[@"~", @"Music"]];
    }
    
    [self.openPanel beginWithCompletionHandler:^(NSInteger result)
     {
         if(result == NSFileHandlingPanelOKButton)
         {
             NSString *filePath = [[self.openPanel URL] path];
             //NSLog(@"filePath:%@", filePath);
             Audio *audio = [NSEntityDescription insertNewObjectForEntityForName:@"Audio" inManagedObjectContext:[CoreDataManager sharedManager].managedObjectContext];
             audio.title = [filePath lastPathComponent];
             self.audioDescriptionTextField.stringValue = audio.title;
             // Make a copy of the audioClip file and store it in the library
             NSString *newFilePath = [NSString stringWithFormat:@"%@/%@", [[[CoreDataManager sharedManager] applicationDocumentsDirectory] path], [filePath lastPathComponent]];
             NSFileManager *fileManager = [NSFileManager defaultManager];
             NSError *error = nil;
             [fileManager copyItemAtPath:filePath toPath:newFilePath error:&error];
             NSLog(@"Copy Audio error error %@, %@", error, [error userInfo]);
             //[[NSApplication sharedApplication] presentError:error];
             // Set the data
             audio.audioFilePath = [filePath lastPathComponent];
             audio.sequence = [CoreDataManager sharedManager].currentSequence;
             
             [[CoreDataManager sharedManager] saveContext];
             
             [[NSNotificationCenter defaultCenter] postNotificationName:@"CurrentSequenceChange" object:nil];
             
             // Search EchoNest for analysis
             if([filePath length] > 1)
             {
                 if([audio.echoNestUploadProgress floatValue] < 0.99)
                 {   
                     /*ENAPIRequest *enRequest = [ENAPIRequest requestWithEndpoint:@"track/profile"];
                     NSData *fileData = [NSData dataWithContentsOfFile:filePath];
                     [enRequest setValue:[fileData enapi_MD5] forParameter:@"md5"];
                     [enRequest setValue:@"audio_summary" forParameter:@"bucket"];
                     [enRequest setUserInfo:@{@"filePath" : audio.audioFilePath}];
                     //[enRequests addObject:enRequest];
                     [enRequest setDelegate:self];
                     [enRequest startAsynchronous];*/
                 }
             }
         }
     }
     ];
}

#pragma mark - NSTextFieldDelegate Methods

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
    if([control.identifier isEqualToString:@"sequenceTitleTextField"])
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [(Sequence *)[self.sequenceFetchedResultsController objectAtIndex:self.sequenceTableView.selectedRow] setTitle:[(NSTextField *)control stringValue]];
            [[CoreDataManager sharedManager] saveContext];
        });
    }
    else if([control.identifier isEqualToString:@"trackTitleTextField"])
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [(UserAudioAnalysisTrack *)[self.trackFetchedResultsController objectAtIndex:self.trackTableView.selectedRow] setTitle:[(NSTextField *)control stringValue]];
            [[CoreDataManager sharedManager] saveContext];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"CurrentSequenceChange" object:nil];
        });
    }
    else if([control.identifier isEqualToString:@"trackChannelTextField"])
    {
        [(UserAudioAnalysisTrackChannel *)[self.trackChannelFetchedResultsController objectAtIndex:self.trackChannelTableView.selectedRow] setTitle:[(NSTextField *)control stringValue]];
        [[CoreDataManager sharedManager] saveContext];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"CurrentSequenceChange" object:nil];
    }
    else if([control.identifier isEqualToString:@"trackChannelPitchTextField"])
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [(UserAudioAnalysisTrackChannel *)[self.trackChannelFetchedResultsController objectAtIndex:self.trackChannelTableView.selectedRow] setPitch:@([(NSTextField *)control intValue])];
            [[CoreDataManager sharedManager] saveContext];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"CurrentSequenceChange" object:nil];
        });
    }
    
    return YES;
}

#pragma mark - NSTableViewDataSource Methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    if(aTableView == self.sequenceTableView)
    {
        return [self.sequenceFetchedResultsController count];
    }
    else if(aTableView == self.trackTableView)
    {
        return [self.trackFetchedResultsController count];
    }
    else if(aTableView == self.trackChannelTableView)
    {
        return [self.trackChannelFetchedResultsController count];
    }
    
    return 0;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if(tableView == self.sequenceTableView)
    {
        // Title column
        if([tableColumn.identifier isEqualToString:@"sequenceTitle"])
        {
            NSTableCellView *result = [tableView makeViewWithIdentifier:@"sequenceTitleView" owner:self];
            result.textField.stringValue = [(Sequence *)[self.sequenceFetchedResultsController objectAtIndex:row] title];
            return result;
        }
    }
    else if(tableView == self.trackTableView)
    {
        // Title column
        if([tableColumn.identifier isEqualToString:@"trackTitle"])
        {
            NSTableCellView *result = [tableView makeViewWithIdentifier:@"trackTitleView" owner:self];
            result.textField.stringValue = [(UserAudioAnalysisTrack *)[self.trackFetchedResultsController objectAtIndex:row] title];
            return result;
        }
    }
    else if(tableView == self.trackChannelTableView)
    {
        // ID column
        if([tableColumn.identifier isEqualToString:@"trackChannelPitch"])
        {
            NSTableCellView *result = [tableView makeViewWithIdentifier:@"trackChannelPitchView" owner:self];
            result.textField.integerValue = [[(UserAudioAnalysisTrackChannel *)[self.trackChannelFetchedResultsController objectAtIndex:row] pitch] integerValue];
            return result;
        }
        // Title column
        else if([tableColumn.identifier isEqualToString:@"trackChannelTitle"])
        {
            NSTableCellView *result = [tableView makeViewWithIdentifier:@"trackChannelTitleView" owner:self];
            result.textField.stringValue = [(UserAudioAnalysisTrackChannel *)[self.trackChannelFetchedResultsController objectAtIndex:row] title];
            return result;
        }
    }
    
    // Return the result
    return nil;
}

#pragma mark - NSTableViewDelegate Methods

-(BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
    if(tableView == self.sequenceTableView)
    {
        self.createTrackButton.enabled = YES;
        
        [self updateTrackFetchedResultsControllerForSequence:(Sequence *)[self.sequenceFetchedResultsController objectAtIndex:row]];
        NSError *error = nil;
        if (![[self trackFetchedResultsController] performFetch:&error])
        {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            [[NSApplication sharedApplication] presentError:error];
        }
        [self.trackTableView reloadData];
    }
    else if(tableView == self.trackTableView)
    {
        self.createTrackChannelButton.enabled = YES;
        
        [self updateTrackChannelFetchedResultsControllerForTrack:(UserAudioAnalysisTrack *)[self.trackFetchedResultsController objectAtIndex:row]];
        NSError *error = nil;
        if (![[self trackChannelFetchedResultsController] performFetch:&error])
        {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            [[NSApplication sharedApplication] presentError:error];
        }
        [self.trackChannelTableView reloadData];
    }
    
    return YES;
}

#pragma mark - Fetched results controller

// Returns the fetched results controller. Creates and configures the controller if necessary.
- (SNRFetchedResultsController *)sequenceFetchedResultsController
{
    if (_sequenceFetchedResultsController != nil)
    {
        return _sequenceFetchedResultsController;
    }
    
    // Create and configure a fetch request with the Book entity.
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Sequence"];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES]];
    
    // Create and initialize the fetch results controller.
    _sequenceFetchedResultsController = [[SNRFetchedResultsController alloc] initWithManagedObjectContext:[[CoreDataManager sharedManager] managedObjectContext] fetchRequest:fetchRequest];
    _sequenceFetchedResultsController.delegate = self;
    
    return _sequenceFetchedResultsController;
}

// Returns the fetched results controller. Creates and configures the controller if necessary.
- (SNRFetchedResultsController *)trackFetchedResultsController
{
    if (_trackFetchedResultsController != nil)
    {
        return _trackFetchedResultsController;
    }
    
    // Create and configure a fetch request with the Book entity.
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"UserAudioAnalysisTrack"];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES]];
    
    // Create and initialize the fetch results controller.
    _trackFetchedResultsController = [[SNRFetchedResultsController alloc] initWithManagedObjectContext:[[CoreDataManager sharedManager] managedObjectContext] fetchRequest:fetchRequest];
    _trackFetchedResultsController.delegate = self;
    
    return _trackFetchedResultsController;
}

// Returns the fetched results controller. Creates and configures the controller if necessary.
- (SNRFetchedResultsController *)trackChannelFetchedResultsController
{
    if (_trackChannelFetchedResultsController != nil)
    {
        return _trackChannelFetchedResultsController;
    }
    
    // Create and configure a fetch request with the Book entity.
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"UserAudioAnalysisTrackChannel"];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"pitch" ascending:YES]];
    
    // Create and initialize the fetch results controller.
    _trackChannelFetchedResultsController = [[SNRFetchedResultsController alloc] initWithManagedObjectContext:[[CoreDataManager sharedManager] managedObjectContext] fetchRequest:fetchRequest];
    _trackChannelFetchedResultsController.delegate = self;
    
    return _trackChannelFetchedResultsController;
}

- (void)updateTrackFetchedResultsControllerForSequence:(Sequence *)sequence
{
    self.trackFetchedResultsController.fetchRequest.predicate = [NSPredicate predicateWithFormat:@"sequence == %@", sequence];
}

- (void)updateTrackChannelFetchedResultsControllerForTrack:(UserAudioAnalysisTrack *)track
{
    self.trackChannelFetchedResultsController.fetchRequest.predicate = [NSPredicate predicateWithFormat:@"track == %@", track];
}

// NSFetchedResultsController delegate methods to respond to additions, removals and so on.
- (void)controllerWillChangeContent:(SNRFetchedResultsController *)controller
{
    if(controller == self.sequenceFetchedResultsController)
    {
        // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
        [self.sequenceTableView beginUpdates];
    }
    else if(controller == self.trackFetchedResultsController)
    {
        // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
        [self.trackTableView beginUpdates];
    }
    else if(controller == self.trackChannelFetchedResultsController)
    {
        // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
        [self.trackChannelTableView beginUpdates];
    }
}

- (void)controller:(SNRFetchedResultsController *)controller didChangeObject:(id)anObject atIndex:(NSUInteger)index forChangeType:(SNRFetchedResultsChangeType)type newIndex:(NSUInteger)newIndex
{
    NSTableView *tableView;
    if(controller == self.sequenceFetchedResultsController)
    {
        tableView = self.sequenceTableView;
    }
    else if(controller == self.trackFetchedResultsController)
    {
        tableView = self.trackTableView;
    }
    else if(controller == self.trackChannelFetchedResultsController)
    {
        tableView = self.trackChannelTableView;
    }
    
    switch (type)
    {
        case SNRFetchedResultsChangeDelete:
            [tableView removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:index] withAnimation:NSTableViewAnimationSlideLeft];
            break;
        case SNRFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:newIndex] withAnimation:NSTableViewAnimationSlideDown];
            break;
        case SNRFetchedResultsChangeUpdate:
            [tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:index] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
            break;
        case SNRFetchedResultsChangeMove:
            [tableView removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:index] withAnimation:NSTableViewAnimationSlideLeft];
            [tableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:newIndex] withAnimation:NSTableViewAnimationSlideDown];
            break;
        default:
            break;
    }
}

- (void)controllerDidChangeContent:(SNRFetchedResultsController *)controller
{
    if(controller == self.sequenceFetchedResultsController)
    {
        // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
        [self.sequenceTableView endUpdates];
    }
    else if(controller == self.trackFetchedResultsController)
    {
        // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
        [self.trackTableView endUpdates];
    }
    else if(controller == self.trackChannelFetchedResultsController)
    {
        // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
        [self.trackChannelTableView endUpdates];
    }
}

@end
