//
//  SequenceAudioAnalysisScrollView.h
//  LightMaster
//
//  Created by James Adams on 12/4/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SequenceAudioAnalysisView;
@class SequenceScrollView, SequenceTimelineScrollView, SequenceAudioAnalysisChannelScrollView;

@interface SequenceAudioAnalysisScrollView : NSScrollView

@property (strong, nonatomic) IBOutlet SequenceAudioAnalysisView *audioAnalysisView;

@property (strong, nonatomic) IBOutlet SequenceTimelineScrollView *timelineScrollView;
@property (strong, nonatomic) IBOutlet SequenceScrollView *sequenceScrollView;
@property (strong, nonatomic) IBOutlet SequenceAudioAnalysisChannelScrollView *audioAnalysisChannelScrollView;

- (void)otherScrollViewBoundsChange:(NSNotification *)notification scrollX:(BOOL)x scrollY:(BOOL)y;
- (void)updateViews;

@end
