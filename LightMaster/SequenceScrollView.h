//
//  SequenceScrollView.h
//  LightMaster
//
//  Created by James Adams on 11/30/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SequenceView, SequenceChannelHeaderView, SequenceChannelView, SequenceUserTatumsView, SequenceTimelineView;

@interface SequenceScrollView : NSScrollView

@property (strong, nonatomic) IBOutlet SequenceView *sequenceView;
@property (strong, nonatomic) IBOutlet SequenceChannelHeaderView *channelHeaderView;
@property (strong, nonatomic) IBOutlet SequenceChannelView *channelView;
@property (strong, nonatomic) IBOutlet SequenceTimelineView *timelineView;
@property (strong, nonatomic) IBOutlet SequenceUserTatumsView *userTatumsView;

- (void)updateViews;

@end
