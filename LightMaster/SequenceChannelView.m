//
//  SequenceChannelView.m
//  LightMaster
//
//  Created by James Adams on 11/30/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import "SequenceChannelView.h"

@implementation SequenceChannelView

- (void)awakeFromNib
{
    self.isAudioAnalysisView = NO;
    
    [self setup];
}

@end
