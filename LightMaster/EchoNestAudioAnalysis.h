//
//  EchoNestAudioAnalysis.h
//  LightMaster
//
//  Created by James Adams on 12/6/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Audio, EchoNestBar, EchoNestBeat, EchoNestSection, EchoNestSegment, EchoNestTatum;

@interface EchoNestAudioAnalysis : NSManagedObject

@property (nonatomic, retain) NSNumber * acousticness;
@property (nonatomic, retain) NSString * album;
@property (nonatomic, retain) NSNumber * analysisChannels;
@property (nonatomic, retain) NSNumber * analysisSampleRate;
@property (nonatomic, retain) NSNumber * analysisTime;
@property (nonatomic, retain) NSString * analysisURL;
@property (nonatomic, retain) NSString * analyzerVersion;
@property (nonatomic, retain) NSString * artist;
@property (nonatomic, retain) NSString * artistID;
@property (nonatomic, retain) NSString * audioMD5;
@property (nonatomic, retain) NSNumber * bitrate;
@property (nonatomic, retain) NSString * codeString;
@property (nonatomic, retain) NSNumber * codeVersion;
@property (nonatomic, retain) NSNumber * danceability;
@property (nonatomic, retain) NSString * decoder;
@property (nonatomic, retain) NSString * detailedStatus;
@property (nonatomic, retain) NSNumber * duration;
@property (nonatomic, retain) NSString * echoPrintString;
@property (nonatomic, retain) NSNumber * echoPrintVersion;
@property (nonatomic, retain) NSNumber * endOfFadeIn;
@property (nonatomic, retain) NSNumber * energy;
@property (nonatomic, retain) NSString * fileName;
@property (nonatomic, retain) NSString * genre;
@property (nonatomic, retain) NSString * idString;
@property (nonatomic, retain) NSNumber * instrumentalness;
@property (nonatomic, retain) NSNumber * key;
@property (nonatomic, retain) NSNumber * keyConfidence;
@property (nonatomic, retain) NSNumber * liveness;
@property (nonatomic, retain) NSNumber * loudness;
@property (nonatomic, retain) NSString * md5;
@property (nonatomic, retain) NSNumber * mode;
@property (nonatomic, retain) NSNumber * modeConfidence;
@property (nonatomic, retain) NSNumber * numberOfSamples;
@property (nonatomic, retain) NSNumber * offsetSeconds;
@property (nonatomic, retain) NSString * rhythmString;
@property (nonatomic, retain) NSNumber * rhythmVersion;
@property (nonatomic, retain) NSNumber * sampleRate;
@property (nonatomic, retain) NSNumber * seconds;
@property (nonatomic, retain) NSString * songID;
@property (nonatomic, retain) NSNumber * speechiness;
@property (nonatomic, retain) NSNumber * startOfFadeOut;
@property (nonatomic, retain) NSString * status;
@property (nonatomic, retain) NSNumber * statusCode;
@property (nonatomic, retain) NSString * synchString;
@property (nonatomic, retain) NSNumber * synchVersion;
@property (nonatomic, retain) NSNumber * tempo;
@property (nonatomic, retain) NSNumber * tempoConfidence;
@property (nonatomic, retain) NSNumber * timeSignature;
@property (nonatomic, retain) NSNumber * timeSignatureConfidence;
@property (nonatomic, retain) NSNumber * timestamp;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * valence;
@property (nonatomic, retain) NSNumber * windowSeconds;
@property (nonatomic, retain) Audio *audio;
@property (nonatomic, retain) NSSet *bars;
@property (nonatomic, retain) NSSet *beats;
@property (nonatomic, retain) NSSet *sections;
@property (nonatomic, retain) NSSet *segments;
@property (nonatomic, retain) NSSet *tatums;
@end

@interface EchoNestAudioAnalysis (CoreDataGeneratedAccessors)

- (void)addBarsObject:(EchoNestBar *)value;
- (void)removeBarsObject:(EchoNestBar *)value;
- (void)addBars:(NSSet *)values;
- (void)removeBars:(NSSet *)values;

- (void)addBeatsObject:(EchoNestBeat *)value;
- (void)removeBeatsObject:(EchoNestBeat *)value;
- (void)addBeats:(NSSet *)values;
- (void)removeBeats:(NSSet *)values;

- (void)addSectionsObject:(EchoNestSection *)value;
- (void)removeSectionsObject:(EchoNestSection *)value;
- (void)addSections:(NSSet *)values;
- (void)removeSections:(NSSet *)values;

- (void)addSegmentsObject:(EchoNestSegment *)value;
- (void)removeSegmentsObject:(EchoNestSegment *)value;
- (void)addSegments:(NSSet *)values;
- (void)removeSegments:(NSSet *)values;

- (void)addTatumsObject:(EchoNestTatum *)value;
- (void)removeTatumsObject:(EchoNestTatum *)value;
- (void)addTatums:(NSSet *)values;
- (void)removeTatums:(NSSet *)values;

@end
