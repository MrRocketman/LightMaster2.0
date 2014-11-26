//
//  UserAudioAnalysis.h
//  LightMaster
//
//  Created by James Adams on 11/25/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Audio, UserAudioAnalysisTrack;

@interface UserAudioAnalysis : NSManagedObject

@property (nonatomic, retain) Audio *sound;
@property (nonatomic, retain) NSSet *tracks;
@end

@interface UserAudioAnalysis (CoreDataGeneratedAccessors)

- (void)addTracksObject:(UserAudioAnalysisTrack *)value;
- (void)removeTracksObject:(UserAudioAnalysisTrack *)value;
- (void)addTracks:(NSSet *)values;
- (void)removeTracks:(NSSet *)values;

@end
