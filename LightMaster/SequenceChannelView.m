//
//  SequenceChannelView.m
//  LightMaster
//
//  Created by James Adams on 11/30/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import "SequenceChannelView.h"

@implementation SequenceChannelView

- (void)awakeFromNib
{
    
}

- (BOOL)isFlipped
{
    return YES;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    self.frame = NSMakeRect(0, 0, self.frame.size.width, 1000);
    
    // clear the background
    //[[NSColor yellowColor] set];
    //NSRectFill(dirtyRect);
    
    // basic beat line
    NSBezierPath *basicBeatLine = [NSBezierPath bezierPath];
    
    int largestY = NSMaxY(self.bounds);
    for (int i = 0; i < largestY; i += 20)
    {
        NSPoint startPoint = NSMakePoint(NSMinX(dirtyRect), i);
        NSPoint endPoint = NSMakePoint(NSMaxX(dirtyRect), i);
        
        [basicBeatLine moveToPoint:startPoint];
        [basicBeatLine lineToPoint:endPoint];
    }
    
    [[NSColor blackColor] set];
    [basicBeatLine setLineWidth:1.0];
    [basicBeatLine stroke];
}

@end
