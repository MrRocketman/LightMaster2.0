//
//  SequenceAudioAnalysisScrollView.m
//  LightMaster
//
//  Created by James Adams on 12/4/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import "SequenceAudioAnalysisScrollView.h"
#import "SequenceScrollView.h"
#import "SequenceAudioAnalysisChannelScrollView.h"
#import "SequenceTimelineScrollView.h"
#import "SequenceAudioAnalysisView.h"
#import "SequenceLogic.h"

@interface SequenceAudioAnalysisScrollView()

@property (assign, nonatomic) BOOL ignoreBoundsChanges;
@property (assign, nonatomic) NSRect lastRefreshVisibleRect;

@end

@implementation SequenceAudioAnalysisScrollView

- (void)awakeFromNib
{
    [self.contentView setPostsBoundsChangedNotifications:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollViewBoundsChange:) name:NSViewBoundsDidChangeNotification object:self.contentView];
}

- (BOOL)isFlipped
{
    return YES;
}

- (void)scrollViewBoundsChange:(NSNotification *)notification
{
    // Only redraw every 50% width change, since the view draws 200% width
    if(self.documentVisibleRect.origin.x > self.lastRefreshVisibleRect.origin.x + self.lastRefreshVisibleRect.size.width / 2 || self.documentVisibleRect.origin.x < self.lastRefreshVisibleRect.origin.x - self.lastRefreshVisibleRect.size.width / 2 || self.documentVisibleRect.origin.y > self.lastRefreshVisibleRect.origin.y + self.lastRefreshVisibleRect.size.height / 2 || self.documentVisibleRect.origin.y < self.lastRefreshVisibleRect.origin.y - self.lastRefreshVisibleRect.size.height / 2)
    {
        self.lastRefreshVisibleRect = self.documentVisibleRect;
        
        [self updateViews];
    }
    
    // If the scroll happened from the user mouse within this view, update
    if(!self.ignoreBoundsChanges)
    {
        self.ignoreBoundsChanges = YES;
        [[SequenceLogic sharedInstance] updateMagnification:self.magnification];
        // Only redraw every 50% width change, since the view draws 200% width
        if(fabs(self.magnification - 1.0) > 0.0001)
        {
            [self updateViews];
            [self.timelineScrollView updateViews];
            [self.sequenceScrollView updateViews];
        }
        self.magnification = 1.0;
        self.ignoreBoundsChanges = NO;
        
        [self.sequenceScrollView otherScrollViewBoundsChange:notification scrollX:YES scrollY:NO];
        [self.timelineScrollView otherScrollViewBoundsChange:notification];
        [self.audioAnalysisChannelScrollView otherScrollViewBoundsChange:notification];
    }
}

- (void)otherScrollViewBoundsChange:(NSNotification *)notification scrollX:(BOOL)x scrollY:(BOOL)y
{
    // get the changed content view from the notification
    NSClipView *changedContentView = [notification object];
    
    // get the origin of the NSClipView of the scroll view that we're watching
    NSPoint changedBoundsOrigin = [changedContentView documentVisibleRect].origin;;
    
    // get our current origin
    NSPoint curOffset = [[self contentView] bounds].origin;
    NSPoint newOffset = curOffset;
    
    // Only scroll the requested axis
    if(x)
    {
        newOffset.x = changedBoundsOrigin.x;
    }
    if(y)
    {
        newOffset.y = changedBoundsOrigin.y;
    }
    
    // if our synced position is different from our current position, reposition our content view
    if (!NSEqualPoints(curOffset, changedBoundsOrigin))
    {
        // note that a scroll view watching this one will get notified here
        self.ignoreBoundsChanges = YES;
        [[self contentView] scrollToPoint:newOffset];
        // we have to tell the NSScrollView to update its
        // scrollers
        [self reflectScrolledClipView:[self contentView]];
        self.ignoreBoundsChanges = NO;
    }
}

- (void)updateViews
{
    [self.audioAnalysisView setNeedsDisplay:YES];
    [self.audioAnalysisView fetchCommandData];
}

/*- (void)drawRect:(NSRect)dirtyRect {
 [super drawRect:dirtyRect];
 
 // Drawing code here.
 }*/

@end
