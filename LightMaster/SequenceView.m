//
//  SequenceView.m
//  LightMaster
//
//  Created by James Adams on 11/30/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import "SequenceView.h"
#import "SequenceLogic.h"

@implementation SequenceView

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
    
    self.frame = NSMakeRect(0, 0, 10000 * [SequenceLogic sharedInstance].magnification, 1000);
    
    // clear the background
    [[NSColor greenColor] set];
    NSRectFill(dirtyRect);
    
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
    
    [[NSColor whiteColor] set];
    [basicBeatLine setLineWidth:1.0];
    [basicBeatLine stroke];
    
    // basic beat line
    basicBeatLine = [NSBezierPath bezierPath];
    
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
    
    /*
    NSBezierPath *keyRollLine = [NSBezierPath bezierPath];
    
    int firstKeyRollLine = 0;
    int currentKeyRollLine = 0;
    int lastKeyRollLine = NSMaxY(self.editorArea);
    
    for (currentKeyRollLine = firstKeyRollLine; currentKeyRollLine <= lastKeyRollLine; currentKeyRollLine += keyRollUnit) {
        
        NSPoint startPoint = NSMakePoint([[OCConstantsLib sharedLib] pixelExact:NSMinX(self.editorArea)], [[OCConstantsLib sharedLib] pixelExact:currentKeyRollLine]);
        NSPoint endPoint = NSMakePoint([[OCConstantsLib sharedLib] pixelExact:NSMaxX(self.editorArea)], [[OCConstantsLib sharedLib] pixelExact:currentKeyRollLine]);
        
        [keyRollLine moveToPoint:startPoint];
        [keyRollLine lineToPoint:endPoint];
        
        // draw the black key background if needed
        // This is a filled rect as opposed to a simple line.
        
        BOOL blackKeyFlag = [[OCMusicLib sharedLib] isBlackKey:currentKeyRollLine / keyRollUnit];
        NSBezierPath *blackKey = [NSBezierPath bezierPath];
        
        NSPoint bottomLeft = startPoint;
        NSPoint bottomRight = endPoint;
        NSPoint topRight = NSMakePoint(bottomRight.x, (float)currentKeyRollLine + keyRollUnit);
        NSPoint topLeft = NSMakePoint(bottomLeft.x, topRight.y);
        
        [blackKey moveToPoint:bottomLeft];
        [blackKey lineToPoint:bottomRight];
        [blackKey lineToPoint:topRight];
        [blackKey lineToPoint:topLeft];
        [blackKey lineToPoint:bottomLeft];
        if (blackKeyFlag)
        {
            [[NSColor blueColor] set];
        }
        else
        {
            [[NSColor grayColor] set];
        }
        [blackKey fill];
    }
    
    [[NSColor redColor] set];
    [keyRollLine setLineWidth:1.0];
    [keyRollLine stroke];
     */
}

@end
