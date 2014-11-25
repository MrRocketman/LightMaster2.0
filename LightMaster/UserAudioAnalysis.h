//
//  UserAudioAnalysis.h
//  LightMaster
//
//  Created by James Adams on 11/24/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Audio, UserAudioAnalysisTatums, UserInstrument;

@interface UserAudioAnalysis : NSManagedObject

@property (nonatomic, retain) Audio *sound;
@property (nonatomic, retain) NSSet *tatums;
@property (nonatomic, retain) NSSet *tracks;
@end

@interface UserAudioAnalysis (CoreDataGeneratedAccessors)

- (void)addTatumsObject:(UserAudioAnalysisTatums *)value;
- (void)removeTatumsObject:(UserAudioAnalysisTatums *)value;
- (void)addTatums:(NSSet *)values;
- (void)removeTatums:(NSSet *)values;

- (void)addTracksObject:(UserInstrument *)value;
- (void)removeTracksObject:(UserInstrument *)value;
- (void)addTracks:(NSSet *)values;
- (void)removeTracks:(NSSet *)values;

@end
