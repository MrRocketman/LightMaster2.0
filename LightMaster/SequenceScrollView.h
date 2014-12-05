//
//  SequenceScrollView.h
//  LightMaster
//
//  Created by James Adams on 11/30/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SequenceView;
@class SequenceChannelScrollView, SequenceTimelineScrollView, SequenceAudioAnalysisScrollView;

@interface SequenceScrollView : NSScrollView

@property (strong, nonatomic) IBOutlet SequenceView *sequenceView;

@property (strong, nonatomic) IBOutlet SequenceChannelScrollView *channelScrollView;
@property (strong, nonatomic) IBOutlet SequenceTimelineScrollView *timelineScrollView;
@property (strong, nonatomic) IBOutlet SequenceAudioAnalysisScrollView *audioAnalysisScrollView;

- (void)otherScrollViewBoundsChange:(NSNotification *)notification scrollX:(BOOL)x scrollY:(BOOL)y;
- (void)updateViews;

@end
