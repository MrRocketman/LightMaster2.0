//
//  SequenceTimelineView.m
//  LightMaster
//
//  Created by James Adams on 11/30/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import "SequenceTimelineView.h"
#import "SequenceLogic.h"

@implementation SequenceTimelineView

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
    
    self.frame = NSMakeRect(0, 0, 10000 * [SequenceLogic sharedInstance].magnification, self.frame.size.height);
    
    // clear the background
    [[NSColor darkGrayColor] set];
    NSRectFill(dirtyRect);
    
    // basic beat line
    NSBezierPath *basicBeatLine = [NSBezierPath bezierPath];
    
    int largestX = NSMaxX(self.bounds);
    for (int i = 0; i < largestX; i += 10)
    {
        NSPoint startPoint = NSMakePoint(i * [SequenceLogic sharedInstance].magnification, NSMinY(dirtyRect));
        NSPoint endPoint = NSMakePoint(i * [SequenceLogic sharedInstance].magnification, NSMaxY(dirtyRect));
        
        [basicBeatLine moveToPoint:startPoint];
        [basicBeatLine lineToPoint:endPoint];
    }
    
    [[NSColor whiteColor] set];
    [basicBeatLine setLineWidth:1.0];
    [basicBeatLine stroke];
}

@end
