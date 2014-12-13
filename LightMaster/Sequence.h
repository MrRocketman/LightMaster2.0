//
//  Sequence.h
//  LightMaster
//
//  Created by James Adams on 12/12/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Audio, Command, ControlBox, Playlist, SequenceTatum;

@interface Sequence : NSManagedObject

@property (nonatomic, retain) NSNumber * endOffset;
@property (nonatomic, retain) NSNumber * endTime;
@property (nonatomic, retain) NSDate * modifiedDate;
@property (nonatomic, retain) NSNumber * startOffset;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * uuid;
@property (nonatomic, retain) NSSet *analysisControlBoxes;
@property (nonatomic, retain) Audio *audio;
@property (nonatomic, retain) NSSet *controlBoxes;
@property (nonatomic, retain) NSSet *playlists;
@property (nonatomic, retain) NSSet *tatums;
@property (nonatomic, retain) NSSet *commands;
@end

@interface Sequence (CoreDataGeneratedAccessors)

- (void)addAnalysisControlBoxesObject:(ControlBox *)value;
- (void)removeAnalysisControlBoxesObject:(ControlBox *)value;
- (void)addAnalysisControlBoxes:(NSSet *)values;
- (void)removeAnalysisControlBoxes:(NSSet *)values;

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

- (void)addCommandsObject:(Command *)value;
- (void)removeCommandsObject:(Command *)value;
- (void)addCommands:(NSSet *)values;
- (void)removeCommands:(NSSet *)values;

@end
