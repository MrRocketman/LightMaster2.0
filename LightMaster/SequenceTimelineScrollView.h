//
//  SequenceTimelineScrollView.h
//  LightMaster
//
//  Created by James Adams on 11/30/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SequenceTimelineView;
@class SequenceScrollView, SequenceAudioAnalysisScrollView;

@interface SequenceTimelineScrollView : NSScrollView

@property (strong, nonatomic) IBOutlet SequenceTimelineView *timelineView;

@property (strong, nonatomic) IBOutlet SequenceScrollView *sequenceScrollView;
@property (strong, nonatomic) IBOutlet SequenceAudioAnalysisScrollView *audioAnalysisScrollView;

- (void)otherScrollViewBoundsChange:(NSNotification *)notification;
- (void)updateViews;

@end
