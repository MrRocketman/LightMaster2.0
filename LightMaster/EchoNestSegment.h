//
//  EchoNestSegment.h
//  LightMaster
//
//  Created by James Adams on 11/24/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class EchoNestAudioAnalysis, EchoNestPitch, EchoNestTimbre;

@interface EchoNestSegment : NSManagedObject

@property (nonatomic, retain) NSNumber * confidence;
@property (nonatomic, retain) NSNumber * duration;
@property (nonatomic, retain) NSNumber * loudnessMax;
@property (nonatomic, retain) NSNumber * loudnessMaxTime;
@property (nonatomic, retain) NSNumber * loudnessStart;
@property (nonatomic, retain) NSNumber * start;
@property (nonatomic, retain) EchoNestAudioAnalysis *echoNestAudioAnalysis;
@property (nonatomic, retain) NSSet *pitches;
@property (nonatomic, retain) NSSet *timbres;
@end

@interface EchoNestSegment (CoreDataGeneratedAccessors)

- (void)addPitchesObject:(EchoNestPitch *)value;
- (void)removePitchesObject:(EchoNestPitch *)value;
- (void)addPitches:(NSSet *)values;
- (void)removePitches:(NSSet *)values;

- (void)addTimbresObject:(EchoNestTimbre *)value;
- (void)removeTimbresObject:(EchoNestTimbre *)value;
- (void)addTimbres:(NSSet *)values;
- (void)removeTimbres:(NSSet *)values;

@end
