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

@interface SequenceTimelineScrollView()

@property (assign, nonatomic) BOOL ignoreBoundsChanges;
@property (assign, nonatomic) NSRect lastRefreshVisibleRect;

@end


@implementation SequenceTimelineScrollView

- (void)awakeFromNib
{
    [self.contentView setPostsBoundsChangedNotifications:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollViewBoundsChange:) name:NSViewBoundsDidChangeNotification object:self.contentView];
    self.lastRefreshVisibleRect = NSMakeRect(0, 0, 0, 0);
}

- (BOOL)isFlipped
{
    return YES;
}

- (void)scrollViewBoundsChange:(NSNotification *)notification
{
    // Only redraw every 50% width change, since the view draws 200% width
    if(self.documentVisibleRect.origin.x > self.lastRefreshVisibleRect.origin.x + self.lastRefreshVisibleRect.size.width / 2 || self.documentVisibleRect.origin.x < self.lastRefreshVisibleRect.origin.x - self.lastRefreshVisibleRect.size.width / 2)
    {
        self.lastRefreshVisibleRect = self.documentVisibleRect;
        
        [self updateViews];
    }
    
    if(!self.ignoreBoundsChanges)
    {
        self.ignoreBoundsChanges = YES;
        [[SequenceLogic sharedInstance] updateMagnification:self.magnification];
        // Only redraw every 50% width change, since the view draws 200% width
        if(fabs(self.magnification - 1.0) > 0.0001)
        {
            [self updateViews];
            [self.sequenceScrollView updateViews];
        }
        self.magnification = 1.0;
        self.ignoreBoundsChanges = NO;
        
        [self.sequenceScrollView otherScrollViewBoundsChange:notification scrollX:YES scrollY:NO];
        [self.audioAnalysisScrollView otherScrollViewBoundsChange:notification scrollX:YES scrollY:NO];
    }
}

- (void)otherScrollViewBoundsChange:(NSNotification *)notification
{
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
        // we have to tell the NSScrollView to update its
        // scrollers
        [self reflectScrolledClipView:[self contentView]];
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
