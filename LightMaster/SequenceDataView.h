//
//  SequenceDataView.h
//  LightMaster
//
//  Created by James Adams on 12/5/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SequenceTatum;

@interface SequenceDataView : NSView

@property (assign, nonatomic) BOOL isAudioAnalysisView;

- (void)setup;
- (void)fetchControlBoxAndChannelData;

@end
