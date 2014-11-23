//
//  EchoNestMeta.h
//  LightMaster
//
//  Created by James Adams on 11/23/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class EchoNestAudioAnalysis;

@interface EchoNestMeta : NSManagedObject

@property (nonatomic, retain) NSNumber * analyzerVersion;
@property (nonatomic, retain) NSString * detailedStatus;
@property (nonatomic, retain) NSString * fileName;
@property (nonatomic, retain) NSString * artist;
@property (nonatomic, retain) NSString * album;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * genre;
@property (nonatomic, retain) NSNumber * bitrate;
@property (nonatomic, retain) NSNumber * sampleRate;
@property (nonatomic, retain) NSNumber * seconds;
@property (nonatomic, retain) NSNumber * statusCode;
@property (nonatomic, retain) NSNumber * timestamp;
@property (nonatomic, retain) NSNumber * analysisTime;
@property (nonatomic, retain) EchoNestAudioAnalysis *echoNestAudioAnalysis;

@end
