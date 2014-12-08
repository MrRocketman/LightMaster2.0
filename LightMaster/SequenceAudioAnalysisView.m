//
//  SequenceAudioAnalysisView.m
//  LightMaster
//
//  Created by James Adams on 12/4/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import "SequenceAudioAnalysisView.h"

@interface SequenceAudioAnalysisView()

@end

@implementation SequenceAudioAnalysisView

- (void)awakeFromNib
{
    self.isAudioAnalysisView = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentTimeChange:) name:@"CurrentTimeChange" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentTimeChange:) name:@"SequenceTatumChange" object:nil];
}

- (void)currentTimeChange:(NSNotification *)notification
{
    [self setNeedsDisplay:YES];
}

@end
