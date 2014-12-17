//
//  PlaylistViewController.m
//  LightMaster
//
//  Created by James Adams on 12/16/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import "PlaylistViewController.h"
#import "CoreDataManager.h"
#import "Sequence.h"
#import "Playlist.h"
#import "SequenceLogic.h"

@interface PlaylistViewController ()

@property (strong, nonatomic) SNRFetchedResultsController *playlistFetchedResultsController;
@property (strong, nonatomic) SNRFetchedResultsController *currentSequenceFetchedResultsController;
@property (strong, nonatomic) SNRFetchedResultsController *sequenceFetchedResultsController;

@property (assign, nonatomic) int currentSequenceIndex;
@property (assign, nonatomic) BOOL isPlayButton;

@end

@implementation PlaylistViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.isPlayButton = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sequenceComplete:) name:@"SequenceComplete" object:nil];
    
    // Playlists
    NSError *error;
    if (![[self playlistFetchedResultsController] performFetch:&error])
    {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        [[NSApplication sharedApplication] presentError:error];
    }
    
    // Current sequences
    error = nil;
    if (![[self currentSequenceFetchedResultsController] performFetch:&error])
    {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        [[NSApplication sharedApplication] presentError:error];
    }
    
    // All sequences
    error = nil;
    if (![[self sequenceFetchedResultsController] performFetch:&error])
    {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (void)viewWillAppear
{
    [self.playlistTableView reloadData];
    [self.currentSequencesTableView reloadData];
    [self.sequenceTableView reloadData];
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
            // Delete playlist
            if(self.playlistTableView == self.playlistTableView.window.firstResponder)
            {
                Playlist *playlist = [self.playlistFetchedResultsController objectAtIndex:self.playlistTableView.selectedRow];
                [[[CoreDataManager sharedManager] managedObjectContext] deleteObject:playlist];
                [[CoreDataManager sharedManager] saveContext];
                
                if(self.playlistFetchedResultsController.count == 0)
                {
                    self.addSequenceToPlaylistButton.enabled = NO;
                    self.playPlaylistButton.enabled = NO;
                }
            }
            // Delete currentSequence
            else if(self.currentSequencesTableView == self.currentSequencesTableView.window.firstResponder)
            {
                Sequence *sequence = [self.currentSequenceFetchedResultsController objectAtIndex:self.currentSequencesTableView.selectedRow];
                Playlist *playlist = [self.playlistFetchedResultsController objectAtIndex:self.playlistTableView.selectedRow];
                [playlist removeSequencesObject:sequence];
                
                [[CoreDataManager sharedManager] saveContext];
            }
        }
        else
        {
            [super keyDown:event];
        }
    }
}

- (void)sequenceComplete:(NSNotification *)notification
{
    self.currentSequenceIndex ++;
    // Loop back to the first one
    if(self.currentSequenceIndex >= self.currentSequenceFetchedResultsController.count)
    {
        self.currentSequenceIndex = 0;
    }
    
    [self loadNextSequence];
}

- (void)loadNextSequence
{
    // Load the sequence
    Sequence *sequence = [self.currentSequenceFetchedResultsController objectAtIndex:self.currentSequenceIndex];
    [CoreDataManager sharedManager].currentSequence = sequence;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CurrentSequenceChange" object:nil];
    [[SequenceLogic sharedInstance] skipBack];
}

#pragma mark - Buttons

- (IBAction)createPlaylistButtonPress:(id)sender
{
    [[CoreDataManager sharedManager] newPlaylist];
}

- (IBAction)playPlaylistButtonPress:(id)sender
{
    if(self.isPlayButton)
    {
        self.playPlaylistButton.title = @"Stop";
        
        self.currentSequenceIndex = 0;
        [self loadNextSequence];
        
        [SequenceLogic sharedInstance].drawCurrentSequence = NO;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"PlayPause" object:nil];
    }
    else
    {
        self.playPlaylistButton.title = @"Play";
        
        [SequenceLogic sharedInstance].drawCurrentSequence = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"PlayPause" object:nil];
    }
    
    self.isPlayButton = !self.isPlayButton;
}

- (IBAction)addSequenceToPlaylistButtonPress:(id)sender
{
    Sequence *sequence = [self.sequenceFetchedResultsController objectAtIndex:self.sequenceTableView.selectedRow];
    Playlist *playlist = [self.playlistFetchedResultsController objectAtIndex:self.playlistTableView.selectedRow];
    [playlist addSequencesObject:sequence];
    
    [[CoreDataManager sharedManager] saveContext];
}

#pragma mark - NSTextFieldDelegate Methods

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
    if([control.identifier isEqualToString:@"playlistTitleTextField"])
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [(Playlist *)[self.playlistFetchedResultsController objectAtIndex:self.playlistTableView.selectedRow] setTitle:[(NSTextField *)control stringValue]];
            [[CoreDataManager sharedManager] saveContext];
        });
    }
    
    return YES;
}

#pragma mark - NSTableViewDataSource Methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    if(aTableView == self.playlistTableView)
    {
        return [self.playlistFetchedResultsController count];
    }
    else if(aTableView == self.currentSequencesTableView)
    {
        return [self.currentSequenceFetchedResultsController count];
    }
    else if(aTableView == self.sequenceTableView)
    {
        //NSLog(@"%d sequences", [self.sequenceFetchedResultsController count]);
        return [self.sequenceFetchedResultsController count];
    }
    
    return 0;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if(tableView == self.playlistTableView)
    {
        // Title column
        if([tableColumn.identifier isEqualToString:@"playlistTitle"])
        {
            NSTableCellView *result = [tableView makeViewWithIdentifier:@"playlistTitleView" owner:self];
            result.textField.stringValue = [(Playlist *)[self.playlistFetchedResultsController objectAtIndex:row] title];
            return result;
        }
    }
    else if(tableView == self.currentSequencesTableView)
    {
        // Title column
        if([tableColumn.identifier isEqualToString:@"currentSequenceTitle"])
        {
            NSTableCellView *result = [tableView makeViewWithIdentifier:@"currentSequenceTitleView" owner:self];
            result.textField.stringValue = [(Sequence *)[self.currentSequenceFetchedResultsController objectAtIndex:row] title];
            return result;
        }
    }
    else if(tableView == self.sequenceTableView)
    {
        // Title column
        if([tableColumn.identifier isEqualToString:@"sequenceTitle"])
        {
            NSTableCellView *result = [tableView makeViewWithIdentifier:@"sequenceTitleView" owner:self];
            result.textField.stringValue = [(Sequence *)[self.sequenceFetchedResultsController objectAtIndex:row] title];
            return result;
        }
    }
    
    // Return the result
    return nil;
}

#pragma mark - NSTableViewDelegate Methods

-(BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
    if(tableView == self.playlistTableView)
    {
        self.addSequenceToPlaylistButton.enabled = YES;
        self.playPlaylistButton.enabled = YES;
        
        Playlist *playlist = (Playlist *)[self.playlistFetchedResultsController objectAtIndex:row];
        [self updateCurrentSequenceFetchedResultsControllerForPlaylist:playlist];
        
        NSError *error = nil;
        if (![[self currentSequenceFetchedResultsController] performFetch:&error])
        {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            [[NSApplication sharedApplication] presentError:error];
        }
        
        [self.currentSequencesTableView reloadData];
    }
    
    return YES;
}

#pragma mark - Fetched results controller

// Returns the fetched results controller. Creates and configures the controller if necessary.
- (SNRFetchedResultsController *)playlistFetchedResultsController
{
    if (_playlistFetchedResultsController != nil)
    {
        return _playlistFetchedResultsController;
    }
    
    // Create and configure a fetch request with the Book entity.
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Playlist"];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES]];
    
    // Create and initialize the fetch results controller.
    _playlistFetchedResultsController = [[SNRFetchedResultsController alloc] initWithManagedObjectContext:[[CoreDataManager sharedManager] managedObjectContext] fetchRequest:fetchRequest];
    _playlistFetchedResultsController.delegate = self;
    
    return _playlistFetchedResultsController;
}

// Returns the fetched results controller. Creates and configures the controller if necessary.
- (SNRFetchedResultsController *)currentSequenceFetchedResultsController
{
    if (_currentSequenceFetchedResultsController != nil)
    {
        return _currentSequenceFetchedResultsController;
    }
    
    // Create and configure a fetch request with the Book entity.
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Sequence"];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES]];
    
    // Create and initialize the fetch results controller.
    _currentSequenceFetchedResultsController = [[SNRFetchedResultsController alloc] initWithManagedObjectContext:[[CoreDataManager sharedManager] managedObjectContext] fetchRequest:fetchRequest];
    _currentSequenceFetchedResultsController.delegate = self;
    
    return _currentSequenceFetchedResultsController;
}

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

- (void)updateCurrentSequenceFetchedResultsControllerForPlaylist:(Playlist *)playlist
{
    self.currentSequenceFetchedResultsController.fetchRequest.predicate = [NSPredicate predicateWithFormat:@"playlists CONTAINS %@", playlist];
}

// NSFetchedResultsController delegate methods to respond to additions, removals and so on.
- (void)controllerWillChangeContent:(SNRFetchedResultsController *)controller
{
    if(controller == self.playlistFetchedResultsController)
    {
        // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
        [self.playlistTableView beginUpdates];
    }
    else if(controller == self.currentSequenceFetchedResultsController)
    {
        // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
        [self.currentSequencesTableView beginUpdates];
    }
    else if(controller == self.sequenceFetchedResultsController)
    {
        // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
        [self.sequenceTableView beginUpdates];
    }
}

- (void)controller:(SNRFetchedResultsController *)controller didChangeObject:(id)anObject atIndex:(NSUInteger)index forChangeType:(SNRFetchedResultsChangeType)type newIndex:(NSUInteger)newIndex
{
    NSTableView *tableView;
    if(controller == self.playlistFetchedResultsController)
    {
        tableView = self.playlistTableView;
    }
    else if(controller == self.currentSequenceFetchedResultsController)
    {
        tableView = self.currentSequencesTableView;
    }
    else if(controller == self.sequenceFetchedResultsController)
    {
        tableView = self.sequenceTableView;
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
    if(controller == self.playlistFetchedResultsController)
    {
        // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
        [self.playlistTableView endUpdates];
    }
    else if(controller == self.currentSequenceFetchedResultsController)
    {
        // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
        [self.currentSequencesTableView endUpdates];
    }
    else if(controller == self.sequenceFetchedResultsController)
    {
        // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
        [self.sequenceTableView endUpdates];
    }
}

@end
