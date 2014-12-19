//
//  SequenceListViewController.m
//  LightMaster
//
//  Created by James Adams on 11/25/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import "SequenceListViewController.h"
#import "CoreDataManager.h"
#import "SequenceLogic.h"
#import "Sequence.h"
#import "Audio.h"
#import "AudioLyric.h"
#import "ControlBox.h"
#import "Channel.h"
#import "ChannelColorTableCellView.h"

@interface SequenceListViewController ()

@property (strong, nonatomic) SNRFetchedResultsController *sequenceFetchedResultsController;
@property (strong, nonatomic) SNRFetchedResultsController *trackFetchedResultsController;
@property (strong, nonatomic) SNRFetchedResultsController *trackChannelFetchedResultsController;
@property (strong, nonatomic) SNRFetchedResultsController *audioLyricFetchedResultsController;

@property (strong, nonatomic) NSOpenPanel *openPanel;
@property (strong, nonatomic) Audio *currentAudio;

@end

@implementation SequenceListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateAudioAnlysisProgressLabel:) name:@"AudioAnalysisProgress" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioNameChange:) name:@"AudioNameChange" object:nil];
    
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
    
    // Track Channels
    error = nil;
    if (![[self audioLyricFetchedResultsController] performFetch:&error])
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
    [self.lyricTableView reloadData];
    
    [self updateAudioTitleLabelForSequenceAtRow:(int)self.sequenceTableView.selectedRow];
    [self updateAudioAnlysisProgressLabel:nil];
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (void)updateAudioTitleLabelForSequenceAtRow:(int)row
{
    Sequence *sequence = [self.sequenceFetchedResultsController objectAtIndex:row];
    self.currentAudio = sequence.audio;
    if(sequence.audio.title.length > 0)
    {
        self.audioDescriptionTextField.stringValue = sequence.audio.title;
    }
    else
    {
        self.audioDescriptionTextField.stringValue = @"";
    }
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
                ControlBox *controlBox = [self.trackFetchedResultsController objectAtIndex:self.trackTableView.selectedRow];
                [[[CoreDataManager sharedManager] managedObjectContext] deleteObject:controlBox];
                [[CoreDataManager sharedManager] saveContext];
                
                if(self.trackFetchedResultsController.count == 0)
                {
                    self.createTrackChannelButton.enabled = NO;
                }
            }
            // Delete track channel
            else if (self.trackChannelTableView == self.trackChannelTableView.window.firstResponder)
            {
                Channel *channel = [self.trackChannelFetchedResultsController objectAtIndex:self.trackChannelTableView.selectedRow];
                [[[CoreDataManager sharedManager] managedObjectContext] deleteObject:channel];
                [[CoreDataManager sharedManager] saveContext];
            }
            // Delete lyric
            else if (self.lyricTableView == self.lyricTableView.window.firstResponder)
            {
                AudioLyric *lyric = [self.audioLyricFetchedResultsController objectAtIndex:self.lyricTableView.selectedRow];
                [[[CoreDataManager sharedManager] managedObjectContext] deleteObject:lyric];
                [[CoreDataManager sharedManager] saveContext];
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"CurrentSequenceChange" object:nil];
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
    [[CoreDataManager sharedManager] newSequence];
}

- (IBAction)createTrackButtonPress:(id)sender
{
    [[CoreDataManager sharedManager] newAnalysisControlBoxForSequence:[self.sequenceFetchedResultsController objectAtIndex:self.sequenceTableView.selectedRow]];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CurrentSequenceChange" object:nil];
}

- (IBAction)createTrackChannelButtonPress:(id)sender
{
    [[CoreDataManager sharedManager] newChannelForControlBox:[self.trackFetchedResultsController objectAtIndex:self.trackTableView.selectedRow]];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CurrentSequenceChange" object:nil];
}

- (IBAction)createLyricButtonPress:(id)sender
{
    [[CoreDataManager sharedManager] newAudioLyricForSequence:[self.sequenceFetchedResultsController objectAtIndex:self.sequenceTableView.selectedRow]];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CurrentSequenceChange" object:nil];
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
             Sequence *selectedSequence = (Sequence *)[self.sequenceFetchedResultsController objectAtIndex:self.sequenceTableView.selectedRow];
             Audio *audio;
             if(!selectedSequence.audio)
             {
                 audio = [NSEntityDescription insertNewObjectForEntityForName:@"Audio" inManagedObjectContext:[CoreDataManager sharedManager].managedObjectContext];
                 audio.sequence = selectedSequence;
             }
             else
             {
                 audio = selectedSequence.audio;
             }
             
             // Set the data
             audio.audioFilePath = [filePath lastPathComponent];
             audio.audioFile = [NSData dataWithContentsOfFile:filePath];
             self.currentAudio = audio;
             
             [[CoreDataManager sharedManager] saveContext];
             
             // Search EchoNest for analysis
             [[SequenceLogic sharedInstance] fetchEchoNestAnalysisForCurrentSequenceAudio];
         }
     }];
}

- (IBAction)autoGenButtonPress:(id)sender
{
    [[SequenceLogic sharedInstance] echoNestAutoGenForCurrentSequence];
}

- (void)updateAudioAnlysisProgressLabel:(NSNotification *)notification
{
    self.audioAnlysisProgress.stringValue = [NSString stringWithFormat:@"%.1f%%", 100 * [self.currentAudio.echoNestUploadProgress floatValue]];
}

- (void)audioNameChange:(NSNotification *)notification
{
    self.audioDescriptionTextField.stringValue = [CoreDataManager sharedManager].currentSequence.audio.title;
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
            [(ControlBox *)[self.trackFetchedResultsController objectAtIndex:self.trackTableView.selectedRow] setTitle:[(NSTextField *)control stringValue]];
            [[CoreDataManager sharedManager] saveContext];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"CurrentSequenceChange" object:nil];
        });
    }
    else if([control.identifier isEqualToString:@"trackChannelTextField"])
    {
        [(Channel *)[self.trackChannelFetchedResultsController objectAtIndex:self.trackChannelTableView.selectedRow] setTitle:[(NSTextField *)control stringValue]];
        [[CoreDataManager sharedManager] saveContext];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"CurrentSequenceChange" object:nil];
    }
    else if([control.identifier isEqualToString:@"trackChannelPitchTextField"])
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [(Channel *)[self.trackChannelFetchedResultsController objectAtIndex:self.trackChannelTableView.selectedRow] setIdNumber:@([(NSTextField *)control intValue])];
            [[CoreDataManager sharedManager] saveContext];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"CurrentSequenceChange" object:nil];
        });
    }
    else if([control.identifier isEqualToString:@"timeTextField"])
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [(AudioLyric *)[self.audioLyricFetchedResultsController objectAtIndex:self.lyricTableView.selectedRow] setTime:@([(NSTextField *)control floatValue])];
            [[CoreDataManager sharedManager] saveContext];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"CurrentSequenceChange" object:nil];
        });
    }
    else if([control.identifier isEqualToString:@"lyricTextField"])
    {
        [(AudioLyric *)[self.audioLyricFetchedResultsController objectAtIndex:self.lyricTableView.selectedRow] setText:[(NSTextField *)control stringValue]];
        [[CoreDataManager sharedManager] saveContext];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"CurrentSequenceChange" object:nil];
    }
    
    return YES;
}

- (IBAction)colorChange:(id)sender
{
    int tableRow = [(ChannelColorTableCellView *)[(NSColorWell *)sender superview] tableRow];
    [(Channel *)[self.trackChannelFetchedResultsController objectAtIndex:tableRow] setColor:[(NSColorWell *)sender color]];
    [[CoreDataManager sharedManager] saveContext];
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
    else if(aTableView == self.lyricTableView)
    {
        return [self.audioLyricFetchedResultsController count];
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
            result.textField.stringValue = [(ControlBox *)[self.trackFetchedResultsController objectAtIndex:row] title];
            return result;
        }
    }
    else if(tableView == self.trackChannelTableView)
    {
        // ID column
        if([tableColumn.identifier isEqualToString:@"trackChannelPitch"])
        {
            NSTableCellView *result = [tableView makeViewWithIdentifier:@"trackChannelPitchView" owner:self];
            result.textField.integerValue = [[(Channel *)[self.trackChannelFetchedResultsController objectAtIndex:row] idNumber] integerValue];
            return result;
        }
        // Title column
        else if([tableColumn.identifier isEqualToString:@"trackChannelTitle"])
        {
            NSTableCellView *result = [tableView makeViewWithIdentifier:@"trackChannelTitleView" owner:self];
            result.textField.stringValue = [(Channel *)[self.trackChannelFetchedResultsController objectAtIndex:row] title];
            return result;
        }
        // Color column
        else if([tableColumn.identifier isEqualToString:@"color"])
        {
            ChannelColorTableCellView *result = [tableView makeViewWithIdentifier:@"channelColor" owner:self];
            result.colorWell.color = [(Channel *)[self.trackChannelFetchedResultsController objectAtIndex:row] color];
            result.tableRow = (int)row;
            return  result;
        }
    }
    else if(tableView == self.lyricTableView)
    {
        // Time column
        if([tableColumn.identifier isEqualToString:@"time"])
        {
            NSTableCellView *result = [tableView makeViewWithIdentifier:@"timeView" owner:self];
            result.textField.floatValue = [[(AudioLyric *)[self.audioLyricFetchedResultsController objectAtIndex:row] time] floatValue];
            return result;
        }
        // Lyric column
        else if([tableColumn.identifier isEqualToString:@"lyric"])
        {
            NSTableCellView *result = [tableView makeViewWithIdentifier:@"lyricView" owner:self];
            result.textField.stringValue = [(AudioLyric *)[self.audioLyricFetchedResultsController objectAtIndex:row] text];
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
        self.createLyricButton.enabled = YES;
        
        Sequence *sequence = (Sequence *)[self.sequenceFetchedResultsController objectAtIndex:row];
        [CoreDataManager sharedManager].currentSequence = sequence;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"CurrentSequenceChange" object:nil];
        [self updateTrackFetchedResultsControllerForSequence:sequence];
        [self updateAudioLyricFetchedResultsControllerForAudio:sequence.audio];
        
        NSError *error = nil;
        if (![[self trackFetchedResultsController] performFetch:&error])
        {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            [[NSApplication sharedApplication] presentError:error];
        }
        error = nil;
        if (![[self audioLyricFetchedResultsController] performFetch:&error])
        {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            [[NSApplication sharedApplication] presentError:error];
        }
        
        [self.trackTableView reloadData];
        [self.lyricTableView reloadData];
        
        // Show the audio data
        if(self.sequenceFetchedResultsController.count > row)
        {
            if(sequence.audio.title.length > 0)
            {
                self.audioDescriptionTextField.stringValue = sequence.audio.title;
            }
            self.currentAudio = sequence.audio;
            [self updateAudioAnlysisProgressLabel:nil];
            [self updateAudioTitleLabelForSequenceAtRow:(int)row];
        }
    }
    else if(tableView == self.trackTableView)
    {
        self.createTrackChannelButton.enabled = YES;
        
        [self updateTrackChannelFetchedResultsControllerForTrack:(ControlBox *)[self.trackFetchedResultsController objectAtIndex:row]];
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
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"ControlBox"];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"idNumber" ascending:YES]];
    
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
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Channel"];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"idNumber" ascending:YES]];
    
    // Create and initialize the fetch results controller.
    _trackChannelFetchedResultsController = [[SNRFetchedResultsController alloc] initWithManagedObjectContext:[[CoreDataManager sharedManager] managedObjectContext] fetchRequest:fetchRequest];
    _trackChannelFetchedResultsController.delegate = self;
    
    return _trackChannelFetchedResultsController;
}

// Returns the fetched results controller. Creates and configures the controller if necessary.
- (SNRFetchedResultsController *)audioLyricFetchedResultsController
{
    if (_audioLyricFetchedResultsController != nil)
    {
        return _audioLyricFetchedResultsController;
    }
    
    // Create and configure a fetch request with the Book entity.
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"AudioLyric"];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"time" ascending:YES]];
    
    // Create and initialize the fetch results controller.
    _audioLyricFetchedResultsController = [[SNRFetchedResultsController alloc] initWithManagedObjectContext:[[CoreDataManager sharedManager] managedObjectContext] fetchRequest:fetchRequest];
    _audioLyricFetchedResultsController.delegate = self;
    
    return _audioLyricFetchedResultsController;
}

- (void)updateTrackFetchedResultsControllerForSequence:(Sequence *)sequence
{
    self.trackFetchedResultsController.fetchRequest.predicate = [NSPredicate predicateWithFormat:@"analysisSequence == %@", sequence];
}

- (void)updateTrackChannelFetchedResultsControllerForTrack:(ControlBox *)track
{
    self.trackChannelFetchedResultsController.fetchRequest.predicate = [NSPredicate predicateWithFormat:@"controlBox == %@", track];
}

- (void)updateAudioLyricFetchedResultsControllerForAudio:(Audio *)audio
{
    self.audioLyricFetchedResultsController.fetchRequest.predicate = [NSPredicate predicateWithFormat:@"audio == %@", audio];
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
    else if(controller == self.audioLyricFetchedResultsController)
    {
        // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
        [self.lyricTableView beginUpdates];
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
    else if(controller == self.audioLyricFetchedResultsController)
    {
        tableView = self.lyricTableView;
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
    else if(controller == self.audioLyricFetchedResultsController)
    {
        // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
        [self.lyricTableView endUpdates];
    }
}

@end
