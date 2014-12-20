//
//  SequenceAudioAnalysisTracksScrollView.m
//  LightMaster
//
//  Created by James Adams on 12/4/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import "SequenceAudioAnalysisChannelScrollView.h"
#import "SequenceAudioAnalysisChannelView.h"
#import "SequenceAudioAnalysisScrollView.h"
#import "SequenceLogic.h"

@interface SequenceAudioAnalysisChannelScrollView()

@property (assign, nonatomic) BOOL ignoreBoundsChanges;

@end

@implementation SequenceAudioAnalysisChannelScrollView

- (void)awakeFromNib
{
    [self.contentView setPostsBoundsChangedNotifications:YES];
    [self setHorizontalLineScroll:0.0];
    [self setHorizontalPageScroll:0.0];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollViewBoundsChange:) name:NSViewBoundsDidChangeNotification object:self.contentView];
}

- (BOOL)isFlipped
{
    return YES;
}

- (void)scrollViewBoundsChange:(NSNotification *)notification
{
    if(!self.ignoreBoundsChanges)
    {
        [self.audioAnalysisScrollView otherScrollViewBoundsChange:notification scrollX:NO scrollY:YES];
    }
}

- (void)otherScrollViewBoundsChange:(NSNotification *)notification
{
    // get the changed content view from the notification
    NSClipView *changedContentView = [notification object];
    
    // get the origin of the NSClipView of the scroll view that we're watching
    NSPoint changedBoundsOrigin = [changedContentView documentVisibleRect].origin;;
    
    // get our current origin
    NSPoint curOffset = [[self contentView] bounds].origin;
    NSPoint newOffset = curOffset;
    
    // scrolling is synchronized in the vertical plane so only modify the y component of the offset
    newOffset.y = changedBoundsOrigin.y;
    
    // if our synced position is different from our current position, reposition our content view
    if (!NSEqualPoints(curOffset, changedBoundsOrigin))
    {
        // note that a scroll view watching this one will get notified here
        self.ignoreBoundsChanges = YES;
        [[self contentView] scrollToPoint:newOffset];
        self.ignoreBoundsChanges = NO;
    }
}

- (void)otherScrollViewMagnificationChange:(float)magnification
{
    self.ignoreBoundsChanges = YES;
    self.magnification = magnification;
    self.ignoreBoundsChanges = NO;
}

- (void)updateViews
{
    [self.audioAnalysisChannelView setNeedsDisplay:YES];
}

/*- (void)drawRect:(NSRect)dirtyRect {
 [super drawRect:dirtyRect];
 
 // Drawing code here.
 }*/

@end
