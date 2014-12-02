//
//  SequenceTimelineView.m
//  LightMaster
//
//  Created by James Adams on 11/30/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import "SequenceTimelineView.h"
#import "SequenceLogic.h"
#import "Sequence.h"
#import "CoreDataManager.h"
#import "SequenceTimelineScrollView.h"
#import "SequenceScrollView.h"

#define AUTO_SCROLL_REFRESH_RATE 0.03

@interface SequenceTimelineView()

@property (assign, nonatomic) BOOL currentTimeMarkerIsSelected;
@property (assign, nonatomic) BOOL endTimeMarkerIsSelected;
@property (strong, nonatomic) NSBezierPath *endTimePath;
@property (strong, nonatomic) NSTimer *autoScrollTimer;
@property (strong, nonatomic) NSEvent *mouseEvent;

@end

@implementation SequenceTimelineView

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
    self.frame = NSMakeRect(0, 0, [[SequenceLogic sharedInstance] timeToX:[[CoreDataManager sharedManager].currentSequence.endTime floatValue] + 1.0], self.frame.size.height);
    
    // clear the background
    //[[NSColor darkGrayColor] set];
    //NSRectFill(dirtyRect);
    
    [self drawTimeline];
}

- (void)drawTimeline
{
    // Determine the grid spacing
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    NSFont *font = [NSFont fontWithName:@"Helvetica" size:10];
    [attributes setObject:font forKey:NSFontAttributeName];
    NSRect visibleRect = [(NSScrollView *)self.superview.superview documentVisibleRect];
    float timeSpan = [[SequenceLogic sharedInstance] xToTime:visibleRect.size.width];
    float timeMarkerDifference = 0.0;
    if(timeSpan >= 60.0)
    {
        timeMarkerDifference = 6.0;
    }
    else if(timeSpan >= 50.0)
    {
        timeMarkerDifference = 5.0;
    }
    else if(timeSpan >= 40.0)
    {
        timeMarkerDifference = 4.0;
    }
    else if(timeSpan >= 30.0)
    {
        timeMarkerDifference = 3.0;
    }
    else if(timeSpan >= 20.0)
    {
        timeMarkerDifference = 2.0;
    }
    else if(timeSpan >= 15.0)
    {
        timeMarkerDifference = 1.5;
    }
    else if(timeSpan >= 10.0)
    {
        timeMarkerDifference = 1.0;
    }
    else if(timeSpan >= 5.0)
    {
        timeMarkerDifference = 0.5;
    }
    else if(timeSpan >= 2.5)
    {
        timeMarkerDifference = 0.25;
    }
    else if(timeSpan >= 1.0)
    {
        timeMarkerDifference = 0.10;
    }
    else
    {
        timeMarkerDifference = 0.0625;
    }
    
    // Draw the grid (+ 5 extras so the user doesn't see blank areas)
    float leftEdgeNearestTimeMaker = [self roundUpNumber:[[SequenceLogic sharedInstance] xToTime:visibleRect.origin.x] toNearestMultipleOfNumber:timeMarkerDifference];
    NSBezierPath *timeLines = [NSBezierPath bezierPath];
    for(int i = 0; i < timeSpan / timeMarkerDifference + 6; i ++)
    {
        float timeMarker = (leftEdgeNearestTimeMaker + i * timeMarkerDifference);
        // Draw the time text
        NSString *time = [NSString stringWithFormat:@"%.02f", timeMarker];
        NSRect textFrame = NSMakeRect([[SequenceLogic sharedInstance] timeToX:timeMarker] - 10, 0, 40, self.frame.size.height / 2);
        [time drawInRect:textFrame withAttributes:attributes];
        
        // Add timelines
        float x = [[SequenceLogic sharedInstance] timeToX:timeMarker];
        [timeLines moveToPoint:NSMakePoint(x, self.frame.size.height / 2)];
        [timeLines lineToPoint:NSMakePoint(x, self.frame.size.height)];
    }
    
    // Draw the time lines
    [[NSColor blackColor] set];
    [timeLines setLineWidth:1.0];
    [timeLines stroke];
    
    // Draw the currentTime marker
    [self drawCurrentTimeMarker];
    
    // Draw the endTime marker
    [self drawEndTimeMarker];
}

- (void)drawCurrentTimeMarker
{
    NSPoint point = NSMakePoint([[SequenceLogic sharedInstance] timeToX:[SequenceLogic sharedInstance].currentTime], self.frame.size.height);
    float width = self.frame.size.height;
    float height = self.frame.size.height;
    
    NSBezierPath *triangle = [NSBezierPath bezierPath];
    
    [triangle moveToPoint:point];
    [triangle lineToPoint:NSMakePoint(point.x - width / 2,  point.y - height)];
    [triangle lineToPoint:NSMakePoint(point.x + width / 2, point.y - height)];
    [triangle closePath];
    
    // Set the color according to whether it is clicked or not
    if(!self.currentTimeMarkerIsSelected)
    {
        [[NSColor colorWithDeviceRed:1.0 green:0.0 blue:0.0 alpha:0.5] setFill];
    }
    else
    {
        [[NSColor colorWithDeviceRed:1.0 green:0.0 blue:0.0 alpha:0.1] setFill];
    }
    [triangle fill];
    [[NSColor whiteColor] setStroke];
    [triangle stroke];
}

- (void)drawEndTimeMarker
{
    NSPoint point = NSMakePoint([[SequenceLogic sharedInstance] timeToX:[[CoreDataManager sharedManager].currentSequence.endTime floatValue]], self.frame.size.height);
    float width = self.frame.size.height;
    float height = self.frame.size.height;
    
    self.endTimePath = [NSBezierPath bezierPath];
    
    [self.endTimePath moveToPoint:point];
    [self.endTimePath lineToPoint:NSMakePoint(point.x - width / 2,  point.y - height)];
    [self.endTimePath lineToPoint:NSMakePoint(point.x + width / 2, point.y - height)];
    [self.endTimePath closePath];
    
    // Set the color according to whether it is clicked or not
    if(!self.endTimeMarkerIsSelected)
    {
        [[NSColor colorWithDeviceRed:0.0 green:0.0 blue:1.0 alpha:0.5] setFill];
    }
    else
    {
        [[NSColor colorWithDeviceRed:0.0 green:0.0 blue:1.0 alpha:0.1] setFill];
    }
    [self.endTimePath fill];
    [[NSColor whiteColor] setStroke];
    [self.endTimePath stroke];
}

- (float)roundUpNumber:(float)numberToRound toNearestMultipleOfNumber:(float)multiple
{
    // Only works to the nearest thousandth
    int intNumberToRound = (int)(numberToRound * 1000000);
    int intMultiple = (int)(multiple * 1000000);
    
    if(multiple == 0)
    {
        return intNumberToRound / 1000000;
    }
    
    int remainder = intNumberToRound % intMultiple;
    if(remainder == 0)
    {
        return intNumberToRound / 1000000;
    }
    
    return (intNumberToRound + intMultiple - remainder) / 1000000.0;
}

#pragma mark Mouse Methods

- (void)mouseDown:(NSEvent *)theEvent
{
    NSPoint eventLocation = [theEvent locationInWindow];
    NSPoint currentMousePoint = [self convertPoint:eventLocation fromView:nil];
    
    if([self.endTimePath containsPoint:currentMousePoint])
    {
        self.endTimeMarkerIsSelected = YES;
    }
    else
    {
        // Update the currentTime
        self.currentTimeMarkerIsSelected = YES;
        [SequenceLogic sharedInstance].currentTime = [[SequenceLogic sharedInstance] xToTime:currentMousePoint.x];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"CurrentTimeChange" object:nil];
    }
    
    [self setNeedsDisplay:YES];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    NSPoint eventLocation = [theEvent locationInWindow];
    NSPoint currentMousePoint = [self convertPoint:eventLocation fromView:nil];
    self.mouseEvent = theEvent;
    
    if(self.endTimeMarkerIsSelected)
    {
        [[CoreDataManager sharedManager] updateSequenceTatumsForNewEndTime:[[SequenceLogic sharedInstance] xToTime:currentMousePoint.x]];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"CurrentTimeChange" object:nil];
    }
    else if(self.currentTimeMarkerIsSelected)
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
    }
    
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
    if(self.endTimeMarkerIsSelected)
    {
        self.endTimeMarkerIsSelected = NO;
    }
    if(self.currentTimeMarkerIsSelected)
    {
        self.currentTimeMarkerIsSelected = NO;
    }
    
    [self.autoScrollTimer invalidate];
    self.autoScrollTimer = nil;
    
    [self setNeedsDisplay:YES];
}

- (void)autoScroll:(NSTimer *)theTimer;
{
    BOOL didAutoscroll = [[self superview] autoscroll:self.mouseEvent];
    if(didAutoscroll)
    {
        [SequenceLogic sharedInstance].currentTime = [[SequenceLogic sharedInstance] xToTime:[SequenceLogic sharedInstance].currentTime + self.mouseEvent.deltaX];
        [self setNeedsDisplay:YES];
    }
}

@end
