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

@interface SequenceView()

@property (strong, nonatomic) NSBezierPath *sequenceTatumPaths;
@property (assign, nonatomic) NSPoint currentMousePoint;
@property (strong, nonatomic) NSEvent *mouseEvent;
@property (strong, nonatomic) NSTimer *autoScrollTimer;
@property (strong, nonatomic) NSTrackingArea *trackingArea;

@property (assign, nonatomic) BOOL sequenceTatumIsSelected;
@property (strong, nonatomic) SequenceTatum *selectedSequenceTatum;

@end

@implementation SequenceView

- (void)awakeFromNib
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentTimeChange:) name:@"CurrentTimeChange" object:nil];
}

- (void)currentTimeChange:(NSNotification *)notification
{
    [self setNeedsDisplay:YES];
}

- (BOOL)isFlipped
{
    return YES;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    self.frame = NSMakeRect(0, 0, [[SequenceLogic sharedInstance] timeToX:[[CoreDataManager sharedManager].currentSequence.endTime floatValue] + 1.0], [[SequenceLogic sharedInstance] numberOfChannels] * CHANNEL_HEIGHT);
    
    if(self.trackingArea)
    {
        [self removeTrackingArea:self.trackingArea];
    }
    self.trackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds] options:(NSTrackingActiveAlways | NSTrackingInVisibleRect | NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved) owner:self userInfo:nil];
    [self addTrackingArea:self.trackingArea];
    
    // clear the background
    [[NSColor blackColor] set];
    NSRectFill(self.bounds);
    
    // Horizontal lines
    NSBezierPath *basicBeatLine = [NSBezierPath bezierPath];
    
    int largestY = NSMaxY(self.bounds);
    for (int i = 0; i < largestY; i += CHANNEL_HEIGHT)
    {
        NSPoint startPoint = NSMakePoint(NSMinX(dirtyRect), i);
        NSPoint endPoint = NSMakePoint(NSMaxX(dirtyRect), i);
        
        [basicBeatLine moveToPoint:startPoint];
        [basicBeatLine lineToPoint:endPoint];
    }
    
    [[NSColor darkGrayColor] set];
    [basicBeatLine setLineWidth:1.0];
    [basicBeatLine stroke];
    
    // Draw Sequence Tatums
    [self drawSequenceTatums];
    
    // Draw the currentTimeMarker
    [self drawCurrentTimeMarker];
    
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

- (void)drawSequenceTatums
{
    NSRect visibleRect = [(NSScrollView *)self.superview.superview documentVisibleRect];
    //NSLog(@"startTime:%f endTime:%f", [[SequenceLogic sharedInstance] xToTime:visibleRect.origin.x], [[SequenceLogic sharedInstance] xToTime:visibleRect.origin.x + visibleRect.size.width]);
    NSArray *visibleTatums = [[[[[CoreDataManager sharedManager].managedObjectContext ofType:@"SequenceTatum"] where:@"sequence == %@ AND startTime >= %f AND startTime <= %f", [CoreDataManager sharedManager].currentSequence, [[SequenceLogic sharedInstance] xToTime:visibleRect.origin.x - visibleRect.size.width / 2], [[SequenceLogic sharedInstance] xToTime:visibleRect.origin.x + visibleRect.size.width * 1.5]] orderBy:@"startTime"] toArray];
    //NSArray *visibleTatums = [[[[[CoreDataManager sharedManager].managedObjectContext ofType:@"SequenceTatum"] where:@"sequence == %@", [CoreDataManager sharedManager].currentSequence] orderBy:@"startTime"] toArray];
    //NSLog(@"visiableTatums:%d", (int)visibleTatums.count);
    
    self.sequenceTatumPaths = [NSBezierPath bezierPath];
    for(int i = 0; i < visibleTatums.count; i ++)
    {
        // Update the tatum position if it's selected
        if(self.sequenceTatumIsSelected && self.selectedSequenceTatum == (SequenceTatum *)visibleTatums[i])
        {
            ((SequenceTatum *)visibleTatums[i]).startTime = @([[SequenceLogic sharedInstance] xToTime:self.currentMousePoint.x]);
            NSBezierPath *selectedTatumPath = [NSBezierPath bezierPath];
            [self addSequenceTatum:(SequenceTatum *)visibleTatums[i] toBezierPath:selectedTatumPath];
            [[NSColor yellowColor] set];
            [selectedTatumPath fill];
        }
        else
        {
            // Draw the normal sequence Tatums
            NSPoint startPoint = [self addSequenceTatum:(SequenceTatum *)visibleTatums[i] toBezierPath:self.sequenceTatumPaths];
            
            // Select a sequenceTatum
            if(self.sequenceTatumIsSelected && !self.selectedSequenceTatum && self.currentMousePoint.x >= startPoint.x - 1 && self.currentMousePoint.x <= startPoint.x + 1)
            {
                self.selectedSequenceTatum = (SequenceTatum *)visibleTatums[i];
            }
        }
    }
    [[NSColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0] set];
    //[self.sequenceTatumPaths setLineWidth:1.0];
    [self.sequenceTatumPaths fill];
}

- (NSPoint)addSequenceTatum:(SequenceTatum *)tatum toBezierPath:(NSBezierPath *)path
{
    NSPoint startPoint = NSMakePoint([[SequenceLogic sharedInstance] timeToX:[tatum.startTime floatValue]], NSMinY(self.bounds));
    NSPoint endPoint = NSMakePoint(startPoint.x, NSMaxY(self.bounds));
    
    [path moveToPoint:NSMakePoint(startPoint.x - 1, startPoint.y)];
    [path lineToPoint:NSMakePoint(endPoint.x - 1, endPoint.y)];
    [path lineToPoint:NSMakePoint(endPoint.x + 1, endPoint.y)];
    [path lineToPoint:NSMakePoint(startPoint.x + 1, startPoint.y)];
    
    return startPoint;
}

- (void)drawCurrentTimeMarker
{
    NSRect markerLineFrame = NSMakeRect([[SequenceLogic sharedInstance] timeToX:[SequenceLogic sharedInstance].currentTime], 0, 1, self.frame.size.height);
    [[NSColor redColor] set];
    NSRectFill(markerLineFrame);
}

#pragma mark Mouse Methods

- (void)rightMouseDown:(NSEvent*)theEvent
{
    // !!!: Add/delete/redo sequence tatums
}

- (void)mouseDown:(NSEvent *)theEvent
{
    NSPoint eventLocation = [theEvent locationInWindow];
    self.currentMousePoint = [self convertPoint:eventLocation fromView:nil];
    
    if([self.sequenceTatumPaths containsPoint:self.currentMousePoint])
    {
        // Select tatum
        self.sequenceTatumIsSelected = YES;
    }
    
    [self setNeedsDisplay:YES];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    NSPoint eventLocation = [theEvent locationInWindow];
    self.currentMousePoint = [self convertPoint:eventLocation fromView:nil];
    self.mouseEvent = theEvent;
    
    /*if(self.currentTimeMarkerIsSelected)
    {
        // Update the currentTime
        float newCurrentTime = [[SequenceLogic sharedInstance] xToTime:currentMousePoint.x];
        // Bind the minimum time to 0
        if(newCurrentTime < 0.0)
        {
            newCurrentTime = 0.0;
        }
        [SequenceLogic sharedInstance].currentTime = newCurrentTime;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"CurrentTimeChange" object:nil];
    }*/
    
    if(self.autoScrollTimer == nil)
    {
        [self.autoScrollTimer invalidate];
        self.autoScrollTimer = nil;
        self.autoScrollTimer = [NSTimer scheduledTimerWithTimeInterval:AUTO_SCROLL_REFRESH_RATE target:self selector:@selector(autoScroll:) userInfo:nil repeats:YES];
    }
    
    [self setNeedsDisplay:YES];
}

- (void)mouseUp:(NSEvent *)theEvent
{
    if(self.sequenceTatumIsSelected)
    {
        self.sequenceTatumIsSelected = NO;
        self.selectedSequenceTatum = nil;
        // Save the sequenceTatum time change
        [[CoreDataManager sharedManager] saveContext];
    }
    
    [self.autoScrollTimer invalidate];
    self.autoScrollTimer = nil;
    
    [self setNeedsDisplay:YES];
}

- (void)mouseMoved:(NSEvent *)theEvent
{
    NSPoint eventLocation = [theEvent locationInWindow];
    NSPoint currentMousePoint = [self convertPoint:eventLocation fromView:nil];
    
    if([self.sequenceTatumPaths containsPoint:currentMousePoint])
    {
        [[NSCursor resizeLeftRightCursor] set];
    }
    else
    {
        [[NSCursor arrowCursor] set];
    }
}

- (void)autoScroll:(NSTimer *)theTimer;
{
    BOOL didAutoscroll = [self autoscroll:self.mouseEvent];
    if(didAutoscroll)
    {
        [self setNeedsDisplay:YES];
    }
}

@end
