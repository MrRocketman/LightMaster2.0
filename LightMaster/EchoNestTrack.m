//
//  EchoNestTrack.m
//  LightMaster
//
//  Created by James Adams on 11/23/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import "EchoNestTrack.h"
#import "EchoNestAudioAnalysis.h"


@implementation EchoNestTrack

@dynamic duration;
@dynamic endOfFadeIn;
@dynamic startOfFadeOut;
@dynamic loudness;
@dynamic tempo;
@dynamic tempoConfidence;
@dynamic timeSignature;
@dynamic timeSignatureConfidence;
@dynamic key;
@dynamic keyConfidence;
@dynamic mode;
@dynamic modeConfidence;
@dynamic numberOfSamples;
@dynamic sampleMD5;
@dynamic decoder;
@dynamic offsetSeconds;
@dynamic windowSeconds;
@dynamic analysisSampleRate;
@dynamic analysisChannels;
@dynamic codeString;
@dynamic codeVersion;
@dynamic echoPrintString;
@dynamic echoPrintVersion;
@dynamic synchString;
@dynamic synchVersion;
@dynamic rhythmString;
@dynamic rhythmVersion;
@dynamic echoNestAudioAnalysis;

@end
