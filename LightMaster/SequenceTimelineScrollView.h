//
//  SequenceTimelineScrollView.h
//  LightMaster
//
//  Created by James Adams on 11/30/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SequenceTimelineView, SequenceScrollView, SequenceChannelScrollView;

@interface SequenceTimelineScrollView : NSScrollView

@property (strong, nonatomic) IBOutlet SequenceTimelineView *timelineView;

@property (strong, nonatomic) IBOutlet SequenceChannelScrollView *channelScrollView;
@property (strong, nonatomic) IBOutlet SequenceScrollView *sequenceScrollView;

- (void)otherScrollViewBoundsChange:(NSNotification *)notification;
- (void)updateViews;

@end
