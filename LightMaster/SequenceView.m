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

@property (assign, nonatomic) NSRect mouseGroupSelectionRect;
@property (assign, nonatomic) BOOL mouseGroupSelect;

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
    
    // Draw channel seperators
    [self drawChannelLines];
    
    // Draw Sequence Tatums
    [self drawSequenceTatums];
    
    // Draw the currentTimeMarker
    [self drawCurrentTimeMarker];
    
    // Draw mouse selection box
    [self drawMouseGroupSelectionBox];
}

- (void)drawChannelLines
{
    NSBezierPath *linesPath = [NSBezierPath bezierPath];
    
    int largestY = NSMaxY(self.bounds);
    for (int i = 0; i < largestY; i += CHANNEL_HEIGHT)
    {
        NSPoint startPoint = NSMakePoint(NSMinX(self.bounds), i);
        NSPoint endPoint = NSMakePoint(NSMaxX(self.bounds), i);
        
        [linesPath moveToPoint:startPoint];
        [linesPath lineToPoint:endPoint];
    }
    
    [[NSColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1.0] set];
    [linesPath setLineWidth:1.0];
    [linesPath stroke];
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
            
            // Start a mouse group select
            if(self.mouseGroupSelect)
            {
                float nextStartPointX;
                if(i < visibleTatums.count - 1)
                {
                    nextStartPointX = [[SequenceLogic sharedInstance] timeToX:[((SequenceTatum *)visibleTatums[i + 1]).startTime floatValue]];
                }
                else
                {
                    nextStartPointX = startPoint.x + 20;
                }
                if(self.currentMousePoint.x >= startPoint.x && self.currentMousePoint.x < nextStartPointX)
                {
                    if(self.mouseGroupSelectionRect.origin.x == -1)
                    {
                        self.mouseGroupSelectionRect = NSMakeRect(startPoint.x, ((int)(self.currentMousePoint.y / CHANNEL_HEIGHT)) * CHANNEL_HEIGHT, nextStartPointX - startPoint.x, CHANNEL_HEIGHT);
                    }
                    else
                    {
                        self.mouseGroupSelectionRect = NSMakeRect(self.mouseGroupSelectionRect.origin.x, self.mouseGroupSelectionRect.origin.y, nextStartPointX - self.mouseGroupSelectionRect.origin.x, ((int)(self.currentMousePoint.y / CHANNEL_HEIGHT) + 1) * CHANNEL_HEIGHT - self.mouseGroupSelectionRect.origin.y);
                    }
                }
            }
        }
    }
    [[NSColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1.0] set];
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

- (void)drawMouseGroupSelectionBox
{
    if(self.mouseGroupSelect && self.mouseGroupSelectionRect.origin.x >= 0)
    {
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(self.mouseGroupSelectionRect.origin.x, self.mouseGroupSelectionRect.origin.y)];
        [path lineToPoint:NSMakePoint(self.mouseGroupSelectionRect.origin.x, self.mouseGroupSelectionRect.origin.y + self.mouseGroupSelectionRect.size.height)];
        [path lineToPoint:NSMakePoint(self.mouseGroupSelectionRect.origin.x + self.mouseGroupSelectionRect.size.width, self.mouseGroupSelectionRect.origin.y + self.mouseGroupSelectionRect.size.height)];
        [path lineToPoint:NSMakePoint(self.mouseGroupSelectionRect.origin.x + self.mouseGroupSelectionRect.size.width, self.mouseGroupSelectionRect.origin.y)];
        [path lineToPoint:NSMakePoint(self.mouseGroupSelectionRect.origin.x, self.mouseGroupSelectionRect.origin.y)];
        
        [[NSColor redColor] set];
        [path setLineWidth:3.0];
        [path stroke];
    }
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
    else
    {
        self.mouseGroupSelect = YES;
        self.mouseGroupSelectionRect = NSMakeRect(-1, -1, -1, -1);
    }
    
    [self setNeedsDisplay:YES];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    NSPoint eventLocation = [theEvent locationInWindow];
    self.currentMousePoint = [self convertPoint:eventLocation fromView:nil];
    self.mouseEvent = theEvent;
    
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
    else if(self.mouseGroupSelect)
    {
        self.mouseGroupSelect = NO;
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
