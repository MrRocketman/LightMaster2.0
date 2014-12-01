//
//  SequenceChannelHeaderView.m
//  LightMaster
//
//  Created by James Adams on 11/30/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import "SequenceChannelHeaderView.h"

@implementation SequenceChannelHeaderView

- (void)awakeFromNib
{
    
}

- (BOOL)isFlipped
{
    return YES;
}

- (void)scrollViewBoundsChange:(NSNotification *)notification
{
    NSView *changedContentView = [notification object];
    [self setBounds:NSMakeRect([self bounds].origin.x, [changedContentView bounds].origin.y, [self bounds].size.width, [changedContentView bounds].size.height)];
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    // clear the background
    [[NSColor redColor] set];
    NSRectFill(dirtyRect);
    
    // basic beat line
    NSBezierPath *basicBeatLine = [NSBezierPath bezierPath];
    
    int largestX = NSMaxX(self.bounds);
    for (int i = 0; i < largestX; i += 50)
    {
        NSPoint startPoint = NSMakePoint(NSMinX(dirtyRect), i);
        NSPoint endPoint = NSMakePoint(NSMaxX(dirtyRect), i);
        
        [basicBeatLine moveToPoint:startPoint];
        [basicBeatLine lineToPoint:endPoint];
    }
    
    [[NSColor whiteColor] set];
    [basicBeatLine setLineWidth:1.0];
    [basicBeatLine stroke];
}

@end
