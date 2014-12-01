//
//  SequenceView.m
//  LightMaster
//
//  Created by James Adams on 11/30/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import "SequenceView.h"
#import "SequenceLogic.h"
#import "CoreDataManager.h"
#import "NSManagedObjectContext+Queryable.h"
#import "Sequence.h"
#import "SequenceTatum.h"

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
    
    // Horizontal lines
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
    
    
    
    
    [self drawTatumGrid];
    
    // Vertical lines
    /*basicBeatLine = [NSBezierPath bezierPath];
    
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
    [basicBeatLine stroke];*/
    
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

- (void)drawTatumGrid
{
    NSRect visibleRect = [(NSScrollView *)self.superview.superview documentVisibleRect];
    NSLog(@"startTime:%f endTime:%f", [[SequenceLogic sharedInstance] xToTime:visibleRect.origin.x], [[SequenceLogic sharedInstance] xToTime:visibleRect.origin.x + visibleRect.size.width]);
    NSArray *visibleTatums = [[[[[CoreDataManager sharedManager].managedObjectContext ofType:@"SequenceTatum"] where:@"sequence == %@ AND startTime >= %f AND startTime <= %f", [CoreDataManager sharedManager].currentSequence, [[SequenceLogic sharedInstance] xToTime:visibleRect.origin.x], [[SequenceLogic sharedInstance] xToTime:visibleRect.origin.x + visibleRect.size.width]] orderBy:@"startTime"] toArray];
    //NSArray *visibleTatums = [[[[[CoreDataManager sharedManager].managedObjectContext ofType:@"SequenceTatum"] where:@"sequence == %@", [CoreDataManager sharedManager].currentSequence] orderBy:@"startTime"] toArray];
    NSLog(@"visiableTatums:%d", (int)visibleTatums.count);
    
    NSBezierPath *tatumLinesPaths = [NSBezierPath bezierPath];
    for(int i = 0; i < visibleTatums.count; i ++)
    {
        NSLog(@"Tatum:%f", [((SequenceTatum *)visibleTatums[i]).startTime floatValue]);
        NSPoint startPoint = NSMakePoint([[SequenceLogic sharedInstance] timeToX:[((SequenceTatum *)visibleTatums[i]).startTime floatValue]], NSMinY(self.bounds));
        NSPoint endPoint = NSMakePoint([[SequenceLogic sharedInstance] timeToX:[((SequenceTatum *)visibleTatums[i]).startTime floatValue]], NSMaxY(self.bounds));
        
        [tatumLinesPaths moveToPoint:startPoint];
        [tatumLinesPaths lineToPoint:endPoint];
    }
    [[NSColor whiteColor] set];
    [tatumLinesPaths setLineWidth:1.0];
    [tatumLinesPaths stroke];
}

@end
