//
//  EchoNestAudioAnalysis.h
//  LightMaster
//
//  Created by James Adams on 11/24/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Audio, EchoNestBar, EchoNestBeat, EchoNestMeta, EchoNestSection, EchoNestSegment, EchoNestTatum, EchoNestTrack;

@interface EchoNestAudioAnalysis : NSManagedObject

@property (nonatomic, retain) Audio *audio;
@property (nonatomic, retain) NSSet *bars;
@property (nonatomic, retain) NSSet *beats;
@property (nonatomic, retain) EchoNestMeta *meta;
@property (nonatomic, retain) NSSet *sections;
@property (nonatomic, retain) NSSet *segments;
@property (nonatomic, retain) NSSet *tatums;
@property (nonatomic, retain) EchoNestTrack *trackData;
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
