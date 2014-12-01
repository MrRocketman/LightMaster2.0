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

@interface SequenceListViewController ()

@property (strong, nonatomic) SNRFetchedResultsController *fetchedResultsController;

@end

@implementation SequenceListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do view setup here.
    NSError *error;
    if (![[self fetchedResultsController] performFetch:&error])
    {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        [[NSApplication sharedApplication] presentError:error];
    }
    
    [self.tableView setDoubleAction:@selector(doubleClick)];
}

- (void)viewWillAppear
{
    // Update our table view
    [self.tableView reloadData];
}

- (IBAction)createSequenceButtonPress:(id)sender
{
    [[CoreDataManager sharedManager] newSequence];
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
            Sequence *sequence = [self.fetchedResultsController objectAtIndex:self.tableView.selectedRow];
            [[[CoreDataManager sharedManager] managedObjectContext] deleteObject:sequence];
            [[CoreDataManager sharedManager] saveContext];
        }
        // Enter key
        else if (pressedUnichar == 13 || pressedUnichar == 3)
        {
            // Set the item
            Sequence *sequence = [self.fetchedResultsController objectAtIndex:self.tableView.selectedRow];
            [CoreDataManager sharedManager].currentSequence = sequence;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"CurrentSequenceChange" object:nil];
            [self dismissViewController:self];
        }
        else
        {
            [super keyDown:event];
        }
    }
}

- (void)doubleClick
{
    Sequence *sequence = [self.fetchedResultsController objectAtIndex:self.tableView.selectedRow];
    [CoreDataManager sharedManager].currentSequence = sequence;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CurrentSequenceChange" object:nil];
    [self dismissViewController:self];
}

#pragma mark - NSTableViewDataSource Methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    
    return [self.fetchedResultsController count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    
    // Retrieve to get the @"MyView" from the pool or,
    // if no version is available in the pool, load the Interface Builder version
    NSTableCellView *result = [tableView makeViewWithIdentifier:@"MyView" owner:self];
    
    // Set the stringValue of the cell's text field to the nameArray value at row
    result.textField.stringValue = [(Sequence *)[self.fetchedResultsController objectAtIndex:row] title];
    
    // Return the result
    return result;
}

/*- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    return [self.fetchedResultsController objectAtIndex:rowIndex];
}*/

#pragma mark - NSTableViewDelegate Methods

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    //if([controlBoxesTableView selectedRow] > -1)
    //{
      //  [deleteControlBoxFromSequenceButton setEnabled:YES];
    //}
}

#pragma mark - Fetched results controller

// Returns the fetched results controller. Creates and configures the controller if necessary.
- (SNRFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil)
    {
        return _fetchedResultsController;
    }
    
    // Create and configure a fetch request with the Book entity.
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Sequence"];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"modifiedDate" ascending:YES]];
    //fetchRequest.predicate = [NSPredicate predicateWithFormat:@"parentItem == %@", nil];
    
    // Create and initialize the fetch results controller.
    _fetchedResultsController = [[SNRFetchedResultsController alloc] initWithManagedObjectContext:[[CoreDataManager sharedManager] managedObjectContext] fetchRequest:fetchRequest];
    _fetchedResultsController.delegate = self;
    
    return _fetchedResultsController;
}

// NSFetchedResultsController delegate methods to respond to additions, removals and so on.
- (void)controllerWillChangeContent:(SNRFetchedResultsController *)controller
{
    // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
    [self.tableView beginUpdates];
}

- (void)controller:(SNRFetchedResultsController *)controller didChangeObject:(id)anObject atIndex:(NSUInteger)index forChangeType:(SNRFetchedResultsChangeType)type newIndex:(NSUInteger)newIndex
{
    switch (type)
    {
        case SNRFetchedResultsChangeDelete:
            [self.tableView removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:index] withAnimation:NSTableViewAnimationSlideLeft];
            break;
        case SNRFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:newIndex] withAnimation:NSTableViewAnimationSlideDown];
            break;
        case SNRFetchedResultsChangeUpdate:
            [self.tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:index] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
            break;
        case SNRFetchedResultsChangeMove:
            [self.tableView removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:index] withAnimation:NSTableViewAnimationSlideLeft];
            [self.tableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:newIndex] withAnimation:NSTableViewAnimationSlideDown];
            break;
        default:
            break;
    }
}

- (void)controllerDidChangeContent:(SNRFetchedResultsController *)controller
{
    // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
    [self.tableView endUpdates];
}

@end
