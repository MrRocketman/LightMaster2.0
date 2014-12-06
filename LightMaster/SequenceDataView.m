//
//  SequenceDataView.m
//  LightMaster
//
//  Created by James Adams on 12/5/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import "SequenceDataView.h"
#import "SequenceLogic.h"
#import "CoreDataManager.h"
#import "NSManagedObjectContext+Queryable.h"
#import "Sequence.h"
#import "SequenceTatum.h"

@interface SequenceDataView()

@property (strong, nonatomic) NSBezierPath *sequenceTatumPaths;
@property (assign, nonatomic) NSPoint currentMousePoint;
@property (strong, nonatomic) NSEvent *mouseEvent;
@property (strong, nonatomic) NSTimer *autoScrollTimer;
@property (strong, nonatomic) NSTrackingArea *trackingArea;

@property (assign, nonatomic) BOOL sequenceTatumIsSelected;
@property (strong, nonatomic) SequenceTatum *selectedSequenceTatum;

@property (assign, nonatomic) float mouseBoxSelectStartTime;
@property (assign, nonatomic) float mouseBoxSelectEndTime;
@property (assign, nonatomic) int mouseBoxSelectTopChannel;
@property (assign, nonatomic) int mouseBoxSelectBottomChannel;
@property (assign, nonatomic) BOOL mouseGroupSelect;
@property (assign, nonatomic) BOOL retainMouseGroupSelect;

@property (assign, nonatomic) BOOL shiftKey;
@property (assign, nonatomic) BOOL commandKey;
@property (assign, nonatomic) BOOL optionKey;
@property (assign, nonatomic) BOOL newTatum;

@end

@implementation SequenceDataView

- (void)awakeFromNib
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentTimeChange:) name:@"CurrentTimeChange" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentTimeChange:) name:@"SequenceTatumChange" object:nil];
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
    //self.frame = NSMakeRect(0, 0, [[SequenceLogic sharedInstance] timeToX:[[CoreDataManager sharedManager].currentSequence.endTime floatValue] + 1.0], [[SequenceLogic sharedInstance] numberOfChannels] * CHANNEL_HEIGHT);
    
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
    NSArray *visibleTatums = [[[[[CoreDataManager sharedManager].managedObjectContext ofType:@"SequenceTatum"] where:@"sequence == %@ AND time >= %f AND time <= %f", [CoreDataManager sharedManager].currentSequence, [[SequenceLogic sharedInstance] xToTime:visibleRect.origin.x - visibleRect.size.width / 2], [[SequenceLogic sharedInstance] xToTime:visibleRect.origin.x + visibleRect.size.width * 1.5]] orderBy:@"time"] toArray];
    
    self.sequenceTatumPaths = [NSBezierPath bezierPath];
    for(int i = 0; i < visibleTatums.count; i ++)
    {
        // Update the tatum position if it's selected
        if(self.sequenceTatumIsSelected && self.selectedSequenceTatum == (SequenceTatum *)visibleTatums[i])
        {
            if(self.optionKey && !self.newTatum)
            {
                [[[CoreDataManager sharedManager] managedObjectContext] deleteObject:visibleTatums[i]];
            }
            else
            {
                ((SequenceTatum *)visibleTatums[i]).time = @([[SequenceLogic sharedInstance] xToTime:self.currentMousePoint.x]);
                NSBezierPath *selectedTatumPath = [NSBezierPath bezierPath];
                [self addSequenceTatum:(SequenceTatum *)visibleTatums[i] toBezierPath:selectedTatumPath];
                [[NSColor yellowColor] set];
                [selectedTatumPath fill];
            }
            
            // Tell any other views to update
            [[NSNotificationCenter defaultCenter] postNotificationName:@"SequenceTatumChange" object:nil];
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
                float nextStartPointX, currentStartPointX;
                if(i < visibleTatums.count - 1)
                {
                    nextStartPointX = [[SequenceLogic sharedInstance] timeToX:[((SequenceTatum *)visibleTatums[i + 1]).time floatValue]];
                }
                else
                {
                    nextStartPointX = startPoint.x;
                }
                if(i >= 0)
                {
                    currentStartPointX = [[SequenceLogic sharedInstance] timeToX:[((SequenceTatum *)visibleTatums[i]).time floatValue]];
                }
                else
                {
                    currentStartPointX = 0;
                }
                if(self.currentMousePoint.x >= startPoint.x && self.currentMousePoint.x < nextStartPointX)
                {
                    if(self.mouseBoxSelectStartTime < 0)
                    {
                        self.mouseBoxSelectStartTime = [((SequenceTatum *)visibleTatums[i]).time floatValue];
                        self.mouseBoxSelectEndTime = [[SequenceLogic sharedInstance] xToTime:nextStartPointX];
                        self.mouseBoxSelectTopChannel = ((int)(self.currentMousePoint.y / CHANNEL_HEIGHT));
                        self.mouseBoxSelectBottomChannel = self.mouseBoxSelectTopChannel + 1;
                    }
                    else
                    {
                        float nextStartPointTime = [[SequenceLogic sharedInstance] xToTime:nextStartPointX];
                        self.mouseBoxSelectEndTime = (nextStartPointTime > self.mouseBoxSelectStartTime ? nextStartPointTime : [[SequenceLogic sharedInstance] xToTime:currentStartPointX]);
                        if(self.currentMousePoint.y / CHANNEL_HEIGHT < self.mouseBoxSelectTopChannel)
                        {
                            self.mouseBoxSelectBottomChannel = (int)((self.currentMousePoint.y < 0 ? 0 : self.currentMousePoint.y / CHANNEL_HEIGHT));
                        }
                        else
                        {
                            self.mouseBoxSelectBottomChannel = (int)((self.currentMousePoint.y > self.frame.size.height ? self.frame.size.height / CHANNEL_HEIGHT : self.currentMousePoint.y / CHANNEL_HEIGHT + 1));
                        }
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
    NSPoint startPoint = NSMakePoint([[SequenceLogic sharedInstance] timeToX:[tatum.time floatValue]], NSMinY(self.bounds));
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
    if((self.mouseGroupSelect || self.retainMouseGroupSelect) && self.mouseBoxSelectStartTime >= 0)
    {
        float leftX = [[SequenceLogic sharedInstance] timeToX:self.mouseBoxSelectStartTime];
        float rightX = [[SequenceLogic sharedInstance] timeToX:self.mouseBoxSelectEndTime];
        float topY = self.mouseBoxSelectTopChannel * CHANNEL_HEIGHT;
        float bottomY = self.mouseBoxSelectBottomChannel * CHANNEL_HEIGHT;
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(leftX, topY)];
        [path lineToPoint:NSMakePoint(leftX, bottomY)];
        [path lineToPoint:NSMakePoint(rightX, bottomY)];
        [path lineToPoint:NSMakePoint(rightX, topY)];
        [path lineToPoint:NSMakePoint(leftX, topY)];
        
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
    else if(self.optionKey)
    {
        [[CoreDataManager sharedManager] addSequenceTatumToSequence:[CoreDataManager sharedManager].currentSequence atTime:[[SequenceLogic sharedInstance] xToTime:self.currentMousePoint.x]];
        [[CoreDataManager sharedManager] saveContext];
        self.sequenceTatumIsSelected = YES;
        self.newTatum = YES;
    }
    else
    {
        self.mouseGroupSelect = YES;
        self.mouseBoxSelectStartTime = -1;
        self.mouseBoxSelectEndTime = -1;
    }
    
    if(self.shiftKey || self.commandKey)
    {
        self.retainMouseGroupSelect = YES;
    }
    else
    {
        self.retainMouseGroupSelect = NO;
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

#pragma mark - Keyboard Methods

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (void) flagsChanged:(NSEvent *)event
{
    self.shiftKey = ([event modifierFlags] & NSShiftKeyMask ? YES : NO);
    self.commandKey = ([event modifierFlags] & NSCommandKeyMask ? YES : NO);
    self.optionKey = ([event modifierFlags] & NSAlternateKeyMask ? YES : NO);
    if(!self.optionKey)
    {
        self.newTatum = NO;
    }
}

/*- (void)keyDown:(NSEvent *)keyboardEvent
 {
 // Check for new command clicks
 if(keyboardEvent.keyCode == 40 && ![keyboardEvent isARepeat])
 {
 
 }
 else if(keyboardEvent.keyCode != 40)
 {
 [super keyDown:keyboardEvent];
 }
 }
 
 - (void)keyUp:(NSEvent *)keyboardEvent
 {
 // Check for new command clicks
 if(keyboardEvent.keyCode == 40 && ![keyboardEvent isARepeat])
 {
 //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(){
 NSMutableDictionary *commandCluster = [data commandClusterForCurrentSequenceAtIndex:data.mostRecentlySelectedCommandClusterIndex];
 float time = [data currentTime];
 int newCommandIndex = [data commandsCountForCommandCluster:commandCluster] - 1;
 [data setEndTime:time forCommandAtIndex:newCommandIndex whichIsPartOfCommandCluster:commandCluster];
 //});
 }
 }*/

@end
