//
//  SequenceScrollView.m
//  LightMaster
//
//  Created by James Adams on 11/30/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//


#import "SequenceScrollView.h"
#import "SequenceView.h"
#import "SequenceChannelScrollView.h"
#import "SequenceTimelineScrollView.h"
#import "SequenceLogic.h"

@interface SequenceScrollView()

@property (assign, nonatomic) BOOL ignoreBoundsChanges;

@end

@implementation SequenceScrollView

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
    //[self.sequenceView setNeedsDisplay:YES];
    
    if(!self.ignoreBoundsChanges)
    {
         NSLog(@"bbx:%f", self.documentVisibleRect.origin.x);
        
        self.ignoreBoundsChanges = YES;
        float previousMag = [SequenceLogic sharedInstance].magnification;
        [[SequenceLogic sharedInstance] updateMagnification:self.magnification];
        if(fabs(self.magnification - 1.0) > 0.0001)
        {
            NSPoint visibleOrigin = [self documentVisibleRect].origin;
            float widthChange = [SequenceLogic sharedInstance].magnification * 10000 - previousMag * 10000;
            NSLog(@"delta:%f", widthChange);
            NSPoint scrollPoint = NSMakePoint(visibleOrigin.x + widthChange / 2, visibleOrigin.y);
            [[self contentView] scrollPoint:scrollPoint];
            [self reflectScrolledClipView:[self contentView]];
            
            [self.sequenceView setNeedsDisplay:YES];
            [SequenceLogic sharedInstance].needsDisplay = YES;
        }
        self.magnification = 1.0;
        self.ignoreBoundsChanges = NO;
        
        [self.channelScrollView otherScrollViewBoundsChange:notification];
        [self.timelineScrollView otherScrollViewBoundsChange:notification];
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
    
    // if our synced position is different from our current position, reposition our content view
    if (!NSEqualPoints(curOffset, changedBoundsOrigin))
    {
        // note that a scroll view watching this one will get notified here
        self.ignoreBoundsChanges = YES;
        [[self contentView] scrollToPoint:changedBoundsOrigin];
        // we have to tell the NSScrollView to update its
        // scrollers
        [self reflectScrolledClipView:[self contentView]];
        self.ignoreBoundsChanges = NO;
    }
    
    // Redraw if magnification changed
    if([SequenceLogic sharedInstance].needsDisplay)
    {
        [self.sequenceView setNeedsDisplay:YES];
        [SequenceLogic sharedInstance].needsDisplay = NO;
    }
}

- (void)updateViews
{
    [self.sequenceView setNeedsDisplay:YES];
}

/*- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}*/

@end
