//
//  SequenceCurrentTimeView.m
//  LightMaster
//
//  Created by James Adams on 12/11/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import "SequenceCurrentTimeView.h"

@implementation SequenceCurrentTimeView

- (void)awakeFromNib
{
    self.shouldDraw = YES;
}

- (BOOL)isFlipped
{
    return YES;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    // Draw the line
    NSRect markerLineFrame = NSMakeRect(0, 0, 2, self.frame.size.height);
    if(self.shouldDraw)
    {
        [[NSColor redColor] set];
    }
    else
    {
        [[NSColor clearColor] set];
    }
    NSRectFill(markerLineFrame);
}

@end
