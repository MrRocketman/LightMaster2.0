//
//  SequenceAudioAnalysisView.m
//  LightMaster
//
//  Created by James Adams on 12/4/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import "SequenceAudioAnalysisView.h"
#import "CoreDataManager.h"
#import "Sequence.h"
#import "SequenceLogic.h"

@interface SequenceAudioAnalysisView()

@end

@implementation SequenceAudioAnalysisView

- (void)awakeFromNib
{
    
}

- (BOOL)isFlipped
{
    return YES;
}

- (void)drawRect:(NSRect)dirtyRect
{
    self.frame = NSMakeRect(0, 0, [[SequenceLogic sharedInstance] timeToX:[[CoreDataManager sharedManager].currentSequence.endTime floatValue] + 1.0], [[SequenceLogic sharedInstance] numberOfAudioChannels] * CHANNEL_HEIGHT);
    
    [super drawRect:dirtyRect];
}

@end
