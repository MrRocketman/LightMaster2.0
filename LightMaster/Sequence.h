//
//  Sequence.h
//  LightMaster
//
//  Created by James Adams on 12/2/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Audio, Command, ControlBox, Playlist, SequenceTatum, UserAudioAnalysisTrack;

@interface Sequence : NSManagedObject

@property (nonatomic, retain) NSNumber * endOffset;
@property (nonatomic, retain) NSNumber * endTime;
@property (nonatomic, retain) NSDate * modifiedDate;
@property (nonatomic, retain) NSNumber * startOffset;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) Audio *audio;
@property (nonatomic, retain) NSSet *commands;
@property (nonatomic, retain) NSSet *controlBoxes;
@property (nonatomic, retain) NSSet *playlists;
@property (nonatomic, retain) NSSet *tatums;
@property (nonatomic, retain) NSSet *userAudioAnalysisTracks;
@end

@interface Sequence (CoreDataGeneratedAccessors)

- (void)addCommandsObject:(Command *)value;
- (void)removeCommandsObject:(Command *)value;
- (void)addCommands:(NSSet *)values;
- (void)removeCommands:(NSSet *)values;

- (void)addControlBoxesObject:(ControlBox *)value;
- (void)removeControlBoxesObject:(ControlBox *)value;
- (void)addControlBoxes:(NSSet *)values;
- (void)removeControlBoxes:(NSSet *)values;

- (void)addPlaylistsObject:(Playlist *)value;
- (void)removePlaylistsObject:(Playlist *)value;
- (void)addPlaylists:(NSSet *)values;
- (void)removePlaylists:(NSSet *)values;

- (void)addTatumsObject:(SequenceTatum *)value;
- (void)removeTatumsObject:(SequenceTatum *)value;
- (void)addTatums:(NSSet *)values;
- (void)removeTatums:(NSSet *)values;

- (void)addUserAudioAnalysisTracksObject:(UserAudioAnalysisTrack *)value;
- (void)removeUserAudioAnalysisTracksObject:(UserAudioAnalysisTrack *)value;
- (void)addUserAudioAnalysisTracks:(NSSet *)values;
- (void)removeUserAudioAnalysisTracks:(NSSet *)values;

@end
