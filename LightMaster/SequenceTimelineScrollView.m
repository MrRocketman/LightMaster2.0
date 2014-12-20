//
//  SequenceTimelineScrollView.m
//  LightMaster
//
//  Created by James Adams on 11/30/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import "SequenceTimelineScrollView.h"
#import "SequenceTimelineView.h"
#import "SequenceChannelScrollView.h"
#import "SequenceScrollView.h"
#import "SequenceLogic.h"
#import "SequenceAudioAnalysisScrollView.h"
#import "SequenceCurrentTimeView.h"
#import "SequenceChannelScrollView.h"

@interface SequenceTimelineScrollView()

@property (assign, nonatomic) BOOL ignoreBoundsChanges;
@property (assign, nonatomic) BOOL previousCurrentTimeShouldDraw;

@end


@implementation SequenceTimelineScrollView

- (void)awakeFromNib
{
    [self.contentView setPostsBoundsChangedNotifications:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollViewBoundsChange:) name:NSViewBoundsDidChangeNotification object:self.contentView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentTimeChange:) name:@"CurrentTimeChange" object:nil];
    [self updateCurrentTimePosition];
    self.previousCurrentTimeShouldDraw = YES;
}

- (BOOL)isFlipped
{
    return YES;
}

- (void)currentTimeChange:(NSNotification *)notification
{
    [self updateCurrentTimePosition];
}

- (void)updateCurrentTimePosition
{
    // Set the currentTimeView Position
    NSPoint point = NSMakePoint([[SequenceLogic sharedInstance] timeToX:[SequenceLogic sharedInstance].currentTime] + self.channelScrollView.frame.size.width - self.documentVisibleRect.origin.x, 0);
    self.currentTimeView.frame = NSMakeRect(point.x, point.y, self.currentTimeView.frame.size.width, self.currentTimeView.frame.size.height);
    if(point.x < self.channelScrollView.frame.size.width && self.previousCurrentTimeShouldDraw)
    {
        self.currentTimeView.shouldDraw = NO;
        self.previousCurrentTimeShouldDraw = NO;
        [self.currentTimeView setNeedsDisplay:YES];
    }
    else if(point.x >= self.channelScrollView.frame.size.width && !self.previousCurrentTimeShouldDraw)
    {
        self.currentTimeView.shouldDraw = YES;
        self.previousCurrentTimeShouldDraw = YES;
        [self.currentTimeView setNeedsDisplay:YES];
    }
}

- (void)scrollViewBoundsChange:(NSNotification *)notification
{
    [self updateCurrentTimePosition];
    
    if(!self.ignoreBoundsChanges)
    {
        self.ignoreBoundsChanges = YES;
        [[SequenceLogic sharedInstance] updateMagnification:self.magnification];
        // Only redraw every 50% width change, since the view draws 200% width
        if(fabs(self.magnification - 1.0) > 0.0001)
        {
            [self updateViews];
            [self.sequenceScrollView updateViews];
            [self.audioAnalysisScrollView updateViews];
        }
        self.magnification = 1.0;
        self.ignoreBoundsChanges = NO;
        
        [self.sequenceScrollView otherScrollViewBoundsChange:notification scrollX:YES scrollY:NO];
        [self.audioAnalysisScrollView otherScrollViewBoundsChange:notification scrollX:YES scrollY:NO];
    }
}

- (void)otherScrollViewBoundsChange:(NSNotification *)notification
{
    [self updateCurrentTimePosition];
    
    // get the changed content view from the notification
    NSClipView *changedContentView=[notification object];
    
    // get the origin of the NSClipView of the scroll view that we're watching
    NSPoint changedBoundsOrigin = [changedContentView documentVisibleRect].origin;;
    
    // get our current origin
    NSPoint curOffset = [[self contentView] bounds].origin;
    NSPoint newOffset = curOffset;
    
    // scrolling is synchronized in the horizontal plane so only modify the x component of the offset
    newOffset.x = changedBoundsOrigin.x;
    
    // if our synced position is different from our current position, reposition our content view
    if (!NSEqualPoints(curOffset, changedBoundsOrigin))
    {
        // note that a scroll view watching this one will get notified here
        self.ignoreBoundsChanges = YES;
        [[self contentView] scrollToPoint:newOffset];
        self.ignoreBoundsChanges = NO;
    }
}

- (void)updateViews
{
    [self.timelineView setNeedsDisplay:YES];
}

/*- (void)drawRect:(NSRect)dirtyRect {
 [super drawRect:dirtyRect];
 
 // Drawing code here.
 }*/

@end
