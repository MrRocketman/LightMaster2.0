//
//  TabbingTableView.m
//  LightMaster
//
//  Created by James Adams on 12/9/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import "TabbingTableView.h"

@implementation TabbingTableView

- (void)awakeFromNib
{
    NSLog(@"awake");
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidEndEditing:) name:@"NSTextDidEndEditingNotification" object:nil];
}

- (void)textDidEndEditing:(NSNotification *) notification
{
    NSLog(@"edit");
    NSInteger editedColumn = [self editedColumn];
    NSInteger editedRow = [self editedRow];
    NSInteger lastRow = [self numberOfRows];
    NSInteger lastCol = [self numberOfColumns];
    NSDictionary *userInfo = [notification userInfo];
    int textMovement = [(NSNumber *)[userInfo valueForKey:@"NSTextMovement"] intValue];
    [super textDidEndEditing: notification];
    
    if (textMovement == NSTabTextMovement)
    {
        if (editedColumn != lastCol - 1 )
        {
            [self selectRowIndexes:[NSIndexSet indexSetWithIndex:editedRow] byExtendingSelection:NO];
            [self editColumn: editedColumn+1 row: editedRow withEvent: nil select: YES];
        }
        else
        {
            if (editedRow !=lastRow-1)
            {
                [self editColumn:0 row:editedRow + 1 withEvent:nil select:YES];
            }
            else
            {
                [self editColumn:0 row:0 withEvent:nil select:YES]; // Go to the first cell
            }
        }
    }
    else if (textMovement == NSReturnTextMovement)
    {
        if(editedRow !=lastRow-1)
        {
            [self selectRowIndexes:[NSIndexSet indexSetWithIndex:editedRow+1] byExtendingSelection:NO];
            [self editColumn: editedColumn row: editedRow+1 withEvent: nil select: YES];
        }
        else
        {
            if (editedColumn !=lastCol - 1)
            {
                [self editColumn:editedColumn+1 row:0 withEvent:nil select:YES];
            }
            else
            {
                [self editColumn:0 row:0 withEvent:nil select:YES]; //Go to the first cell
            }
        }
    }
}

@end
