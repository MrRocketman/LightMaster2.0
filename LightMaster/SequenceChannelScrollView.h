//
//  SequenceChannelScrollView.h
//  LightMaster
//
//  Created by James Adams on 11/30/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SequenceChannelView, SequenceScrollView, SequenceTimelineScrollView;

@interface SequenceChannelScrollView : NSScrollView

@property (strong, nonatomic) IBOutlet SequenceChannelView *channelView;

@property (strong, nonatomic) IBOutlet SequenceScrollView *sequenceScrollView;
@property (strong, nonatomic) IBOutlet SequenceTimelineScrollView *timelineScrollView;

- (void)otherScrollViewBoundsChange:(NSNotification *)notification;
- (void)updateViews;

@end
