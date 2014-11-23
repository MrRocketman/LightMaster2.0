//
//  EchoNestSegment.m
//  LightMaster
//
//  Created by James Adams on 11/23/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import "EchoNestSegment.h"
#import "EchoNestAudioAnalysis.h"
#import "EchoNestPitch.h"
#import "EchoNestTimbre.h"


@implementation EchoNestSegment

@dynamic start;
@dynamic duration;
@dynamic confidence;
@dynamic loudnessStart;
@dynamic loudnessMaxTime;
@dynamic loudnessMax;
@dynamic pitches;
@dynamic timbres;
@dynamic echoNestAudioAnalysis;

@end
