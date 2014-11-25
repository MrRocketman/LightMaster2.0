//
//  EchoNestSection.h
//  LightMaster
//
//  Created by James Adams on 11/24/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class EchoNestAudioAnalysis;

@interface EchoNestSection : NSManagedObject

@property (nonatomic, retain) NSNumber * confidence;
@property (nonatomic, retain) NSNumber * duration;
@property (nonatomic, retain) NSNumber * key;
@property (nonatomic, retain) NSNumber * keyConfidence;
@property (nonatomic, retain) NSNumber * loudness;
@property (nonatomic, retain) NSNumber * mode;
@property (nonatomic, retain) NSNumber * modeConfidence;
@property (nonatomic, retain) NSNumber * start;
@property (nonatomic, retain) NSNumber * tempo;
@property (nonatomic, retain) NSNumber * tempoConfidence;
@property (nonatomic, retain) NSNumber * timeSignature;
@property (nonatomic, retain) NSNumber * timeSignatureConfidence;
@property (nonatomic, retain) EchoNestAudioAnalysis *echoNestAudioAnalysis;

@end
