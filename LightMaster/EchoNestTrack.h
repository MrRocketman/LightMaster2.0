//
//  EchoNestTrack.h
//  LightMaster
//
//  Created by James Adams on 11/24/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class EchoNestAudioAnalysis;

@interface EchoNestTrack : NSManagedObject

@property (nonatomic, retain) NSNumber * analysisChannels;
@property (nonatomic, retain) NSNumber * analysisSampleRate;
@property (nonatomic, retain) NSString * codeString;
@property (nonatomic, retain) NSNumber * codeVersion;
@property (nonatomic, retain) NSString * decoder;
@property (nonatomic, retain) NSNumber * duration;
@property (nonatomic, retain) NSString * echoPrintString;
@property (nonatomic, retain) NSNumber * echoPrintVersion;
@property (nonatomic, retain) NSNumber * endOfFadeIn;
@property (nonatomic, retain) NSNumber * key;
@property (nonatomic, retain) NSNumber * keyConfidence;
@property (nonatomic, retain) NSNumber * loudness;
@property (nonatomic, retain) NSNumber * mode;
@property (nonatomic, retain) NSNumber * modeConfidence;
@property (nonatomic, retain) NSNumber * numberOfSamples;
@property (nonatomic, retain) NSNumber * offsetSeconds;
@property (nonatomic, retain) NSString * rhythmString;
@property (nonatomic, retain) NSNumber * rhythmVersion;
@property (nonatomic, retain) NSString * sampleMD5;
@property (nonatomic, retain) NSNumber * startOfFadeOut;
@property (nonatomic, retain) NSString * synchString;
@property (nonatomic, retain) NSNumber * synchVersion;
@property (nonatomic, retain) NSNumber * tempo;
@property (nonatomic, retain) NSNumber * tempoConfidence;
@property (nonatomic, retain) NSNumber * timeSignature;
@property (nonatomic, retain) NSNumber * timeSignatureConfidence;
@property (nonatomic, retain) NSNumber * windowSeconds;
@property (nonatomic, retain) EchoNestAudioAnalysis *echoNestAudioAnalysis;

@end
