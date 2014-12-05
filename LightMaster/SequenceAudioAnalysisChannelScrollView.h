//
//  SequenceAudioAnalysisTracksScrollView.h
//  LightMaster
//
//  Created by James Adams on 12/4/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SequenceAudioAnalysisChannelView;
@class SequenceAudioAnalysisScrollView;

@interface SequenceAudioAnalysisChannelScrollView : NSScrollView

@property (strong, nonatomic) IBOutlet SequenceAudioAnalysisChannelView *audioAnalysisChannelView;

@property (strong, nonatomic) IBOutlet SequenceAudioAnalysisScrollView *audioAnalysisScrollView;

- (void)otherScrollViewBoundsChange:(NSNotification *)notification;
- (void)updateViews;

@end
