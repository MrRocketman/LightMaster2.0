//
//  ControlBoxViewController.m
//  LightMaster
//
//  Created by James Adams on 11/25/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import "ControlBoxViewController.h"
#import "CoreDataManager.h"
#import "ControlBox.h"
#import "Channel.h"
#import "ChannelColorTableCellView.h"

@interface ControlBoxViewController ()

@property (strong, nonatomic) SNRFetchedResultsController *controlBoxFetchedResultsController;
@property (strong, nonatomic) SNRFetchedResultsController *channelFetchedResultsController;

@end

@implementation ControlBoxViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    // Control Boxes
    NSError *error;
    if (![[self controlBoxFetchedResultsController] performFetch:&error])
    {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        [[NSApplication sharedApplication] presentError:error];
    }
    
    // Channels
    error = nil;
    if (![[self channelFetchedResultsController] performFetch:&error])
    {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (void)viewWillAppear
{
    [self.controlBoxTableView reloadData];
    [self.channelsTableView reloadData];
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
            // Delete control box
            if (self.controlBoxTableView == self.controlBoxTableView.window.firstResponder)
            {
                ControlBox *controlBox = [self.controlBoxFetchedResultsController objectAtIndex:self.controlBoxTableView.selectedRow];
                [[[CoreDataManager sharedManager] managedObjectContext] deleteObject:controlBox];
                [[CoreDataManager sharedManager] saveContext];
                // Disable channel button if all boxes have been deleted
                if(self.controlBoxFetchedResultsController.count == 0)
                {
                    self.createChannelButton.enabled = NO;
                }
            }
            // Delete channel
            else if (self.channelsTableView == self.channelsTableView.window.firstResponder)
            {
                Channel *channel = [self.channelFetchedResultsController objectAtIndex:self.channelsTableView.selectedRow];
                [[[CoreDataManager sharedManager] managedObjectContext] deleteObject:channel];
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

- (IBAction)createControlBoxButtonPress:(id)sender
{
    [[CoreDataManager sharedManager] newControlBox];
}

- (IBAction)createChannelButtonPress:(id)sender
{
    [[CoreDataManager sharedManager] newChannelForControlBox:(ControlBox *)[self.controlBoxFetchedResultsController objectAtIndex:self.controlBoxTableView.selectedRow]];
}

- (IBAction)colorChange:(id)sender
{
    int tableRow = [(ChannelColorTableCellView *)[(NSColorWell *)sender superview] tableRow];
    [(Channel *)[self.channelFetchedResultsController objectAtIndex:tableRow] setColor:[(NSColorWell *)sender color]];
    [[CoreDataManager sharedManager] saveContext];
}

#pragma mark - NSTextFieldDelegate Methods

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
    if([control.identifier isEqualToString:@"boxIDTextField"])
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [(ControlBox *)[self.controlBoxFetchedResultsController objectAtIndex:self.controlBoxTableView.selectedRow] setIdNumber:@([(NSTextField *)control intValue])];
            [[CoreDataManager sharedManager] saveContext];
        });
    }
    else if([control.identifier isEqualToString:@"boxTitleTextField"])
    {
        [(ControlBox *)[self.controlBoxFetchedResultsController objectAtIndex:self.controlBoxTableView.selectedRow] setTitle:[(NSTextField *)control stringValue]];
        [[CoreDataManager sharedManager] saveContext];
    }
    else if([control.identifier isEqualToString:@"channelIDTextField"])
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [(Channel *)[self.channelFetchedResultsController objectAtIndex:self.channelsTableView.selectedRow] setIdNumber:@([(NSTextField *)control intValue])];
            [[CoreDataManager sharedManager] saveContext];
        });
    }
    else if([control.identifier isEqualToString:@"channelWattsTextField"])
    {
        [(Channel *)[self.channelFetchedResultsController objectAtIndex:self.channelsTableView.selectedRow] setWatts:@([(NSTextField *)control intValue])];
        [[CoreDataManager sharedManager] saveContext];
    }
    else if([control.identifier isEqualToString:@"channelLightsTextField"])
    {
        [(Channel *)[self.channelFetchedResultsController objectAtIndex:self.channelsTableView.selectedRow] setNumberOfLights:@([(NSTextField *)control intValue])];
        [[CoreDataManager sharedManager] saveContext];
    }
    else if([control.identifier isEqualToString:@"channelTitleTextField"])
    {
        [(Channel *)[self.channelFetchedResultsController objectAtIndex:self.channelsTableView.selectedRow] setTitle:[(NSTextField *)control stringValue]];
        [[CoreDataManager sharedManager] saveContext];
    }
    
    return YES;
}

#pragma mark - NSTableViewDataSource Methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    if(aTableView == self.controlBoxTableView)
    {
        return [self.controlBoxFetchedResultsController count];
    }
    else if(aTableView == self.channelsTableView)
    {
        return [self.channelFetchedResultsController count];
    }
    
    return 0;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if(tableView == self.controlBoxTableView)
    {
        // ID column
        if([tableColumn.identifier isEqualToString:@"id"])
        {
            NSTableCellView *result = [tableView makeViewWithIdentifier:@"boxID" owner:self];
            result.textField.integerValue = [[(ControlBox *)[self.controlBoxFetchedResultsController objectAtIndex:row] idNumber] integerValue];
            return result;
        }
        // Description column
        else if([tableColumn.identifier isEqualToString:@"title"])
        {
            NSTableCellView *result = [tableView makeViewWithIdentifier:@"boxTitle" owner:self];
            result.textField.stringValue = [(ControlBox *)[self.controlBoxFetchedResultsController objectAtIndex:row] title];
            return result;
        }
    }
    else if(tableView == self.channelsTableView)
    {
        // ID column
        if([tableColumn.identifier isEqualToString:@"id"])
        {
            NSTableCellView *result = [tableView makeViewWithIdentifier:@"channelID" owner:self];
            result.textField.integerValue = [[(Channel *)[self.channelFetchedResultsController objectAtIndex:row] idNumber] integerValue];
            return result;
        }
        // Watts column
        if([tableColumn.identifier isEqualToString:@"watts"])
        {
            NSTableCellView *result = [tableView makeViewWithIdentifier:@"channelWatts" owner:self];
            result.textField.integerValue = [[(Channel *)[self.channelFetchedResultsController objectAtIndex:row] watts] integerValue];
            return result;
        }
        // Lights column
        if([tableColumn.identifier isEqualToString:@"lights"])
        {
            NSTableCellView *result = [tableView makeViewWithIdentifier:@"channelLights" owner:self];
            result.textField.integerValue = [[(Channel *)[self.channelFetchedResultsController objectAtIndex:row] numberOfLights] integerValue];
            return result;
        }
        // Description column
        else if([tableColumn.identifier isEqualToString:@"title"])
        {
            NSTableCellView *result = [tableView makeViewWithIdentifier:@"channelTitle" owner:self];
            result.textField.stringValue = [(Channel *)[self.channelFetchedResultsController objectAtIndex:row] title];
            return result;
        }
        // Color column
        else if([tableColumn.identifier isEqualToString:@"color"])
        {
            ChannelColorTableCellView *result = [tableView makeViewWithIdentifier:@"channelColor" owner:self];
            result.colorWell.color = [(Channel *)[self.channelFetchedResultsController objectAtIndex:row] color];
            result.tableRow = (int)row;
            return  result;
        }
    }
    
    // Return the result
    return nil;
}

#pragma mark - NSTableViewDelegate Methods

-(BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
    if(tableView == self.controlBoxTableView)
    {
        self.createChannelButton.enabled = YES;
        
        [self updateChannelFetchedResultsControllerForControlBox:(ControlBox *)[self.controlBoxFetchedResultsController objectAtIndex:row]];
        NSError *error = nil;
        if (![[self channelFetchedResultsController] performFetch:&error])
        {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            [[NSApplication sharedApplication] presentError:error];
        }
        [self.channelsTableView reloadData];
    }
    
    return YES;
}

#pragma mark - Fetched results controller

// Returns the fetched results controller. Creates and configures the controller if necessary.
- (SNRFetchedResultsController *)controlBoxFetchedResultsController
{
    if (_controlBoxFetchedResultsController != nil)
    {
        return _controlBoxFetchedResultsController;
    }
    
    // Create and configure a fetch request with the Book entity.
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"ControlBox"];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"idNumber" ascending:YES]];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"analysisSequence == %@", nil];
    
    // Create and initialize the fetch results controller.
    _controlBoxFetchedResultsController = [[SNRFetchedResultsController alloc] initWithManagedObjectContext:[[CoreDataManager sharedManager] managedObjectContext] fetchRequest:fetchRequest];
    _controlBoxFetchedResultsController.delegate = self;
    
    return _controlBoxFetchedResultsController;
}

// Returns the fetched results controller. Creates and configures the controller if necessary.
- (SNRFetchedResultsController *)channelFetchedResultsController
{
    if (_channelFetchedResultsController != nil)
    {
        return _channelFetchedResultsController;
    }
    
    // Create and configure a fetch request with the Book entity.
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Channel"];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"idNumber" ascending:YES]];
    //fetchRequest.predicate = [NSPredicate predicateWithFormat:@"controlBox == %@", (ControlBox *)[self.controlBoxFetchedResultsController objectAtIndex:(self.controlBoxTableView.selectedRow >= 0 ? self.controlBoxTableView.selectedRow : 0)]];
    
    // Create and initialize the fetch results controller.
    _channelFetchedResultsController = [[SNRFetchedResultsController alloc] initWithManagedObjectContext:[[CoreDataManager sharedManager] managedObjectContext] fetchRequest:fetchRequest];
    _channelFetchedResultsController.delegate = self;
    
    return _channelFetchedResultsController;
}

- (void)updateChannelFetchedResultsControllerForControlBox:(ControlBox *)controlBox
{
    self.channelFetchedResultsController.fetchRequest.predicate = [NSPredicate predicateWithFormat:@"controlBox == %@", controlBox];
}

// NSFetchedResultsController delegate methods to respond to additions, removals and so on.
- (void)controllerWillChangeContent:(SNRFetchedResultsController *)controller
{
    if(controller == self.controlBoxFetchedResultsController)
    {
        // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
        [self.controlBoxTableView beginUpdates];
    }
    else if(controller == self.channelFetchedResultsController)
    {
        // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
        [self.channelsTableView beginUpdates];
    }
}

- (void)controller:(SNRFetchedResultsController *)controller didChangeObject:(id)anObject atIndex:(NSUInteger)index forChangeType:(SNRFetchedResultsChangeType)type newIndex:(NSUInteger)newIndex
{
    NSTableView *tableView;
    if(controller == self.controlBoxFetchedResultsController)
    {
        tableView = self.controlBoxTableView;
    }
    else if(controller == self.channelFetchedResultsController)
    {
        tableView = self.channelsTableView;
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
    if(controller == self.controlBoxFetchedResultsController)
    {
        // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
        [self.controlBoxTableView endUpdates];
    }
    else if(controller == self.channelFetchedResultsController)
    {
        // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
        [self.channelsTableView endUpdates];
    }
}

@end
