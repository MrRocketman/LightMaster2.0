//
//  UserAudioAnalysisTrackChannel.h
//  LightMaster
//
//  Created by James Adams on 11/24/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Command, UserAudioAnalysisTrack;

@interface UserAudioAnalysisTrackChannel : NSManagedObject

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * pitch;
@property (nonatomic, retain) NSSet *commands;
@property (nonatomic, retain) UserAudioAnalysisTrack *track;
@end

@interface UserAudioAnalysisTrackChannel (CoreDataGeneratedAccessors)

- (void)addCommandsObject:(Command *)value;
- (void)removeCommandsObject:(Command *)value;
- (void)addCommands:(NSSet *)values;
- (void)removeCommands:(NSSet *)values;

@end
