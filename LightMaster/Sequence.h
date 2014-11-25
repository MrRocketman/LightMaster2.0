//
//  Sequence.h
//  LightMaster
//
//  Created by James Adams on 11/24/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Audio, Command, ControlBox, Playlist;

@interface Sequence : NSManagedObject

@property (nonatomic, retain) NSNumber * endOffset;
@property (nonatomic, retain) NSNumber * endTime;
@property (nonatomic, retain) NSNumber * startOffset;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSSet *commands;
@property (nonatomic, retain) NSSet *controlBoxes;
@property (nonatomic, retain) NSSet *playlists;
@property (nonatomic, retain) NSSet *sounds;
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

- (void)addSoundsObject:(Audio *)value;
- (void)removeSoundsObject:(Audio *)value;
- (void)addSounds:(NSSet *)values;
- (void)removeSounds:(NSSet *)values;

@end
