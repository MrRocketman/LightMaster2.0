//
//  UserAudioAnalysisTrack.h
//  LightMaster
//
//  Created by James Adams on 12/2/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Sequence, UserAudioAnalysisTrackChannel;

@interface UserAudioAnalysisTrack : NSManagedObject

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) Sequence *sequence;
@property (nonatomic, retain) NSSet *channels;
@end

@interface UserAudioAnalysisTrack (CoreDataGeneratedAccessors)

- (void)addChannelsObject:(UserAudioAnalysisTrackChannel *)value;
- (void)removeChannelsObject:(UserAudioAnalysisTrackChannel *)value;
- (void)addChannels:(NSSet *)values;
- (void)removeChannels:(NSSet *)values;

@end
