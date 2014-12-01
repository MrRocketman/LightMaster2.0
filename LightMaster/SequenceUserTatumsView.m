//
//  SequenceUserTatumsView.m
//  LightMaster
//
//  Created by James Adams on 11/30/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import "SequenceUserTatumsView.h"

@implementation SequenceUserTatumsView

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
    NSPoint changedBoundsOrigin = [changedContentView bounds].origin;
    [self setBounds:NSMakeRect(changedBoundsOrigin.x - 30.0f, [self bounds].origin.y, [self bounds].size.width, [self bounds].size.height)];
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    // clear the background
    [[NSColor blueColor] set];
    NSRectFill(dirtyRect);
    
    // basic beat line
    NSBezierPath *basicBeatLine = [NSBezierPath bezierPath];
    
    int largestX = NSMaxX(self.bounds);
    for (int i = 0; i < largestX; i += 20)
    {
        NSPoint startPoint = NSMakePoint(i, NSMinY(dirtyRect));
        NSPoint endPoint = NSMakePoint(i, NSMaxY(dirtyRect));
        
        [basicBeatLine moveToPoint:startPoint];
        [basicBeatLine lineToPoint:endPoint];
    }
    
    [[NSColor whiteColor] set];
    [basicBeatLine setLineWidth:1.0];
    [basicBeatLine stroke];
}

@end
