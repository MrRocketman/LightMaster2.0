//
//  UserAudioAnalysisTrack.h
//  LightMaster
//
//  Created by James Adams on 11/24/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class UserAudioAnalysis;

@interface UserAudioAnalysisTrack : NSManagedObject

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) UserAudioAnalysis *audioAnalysis;
@property (nonatomic, retain) NSSet *channels;
@end

@interface UserAudioAnalysisTrack (CoreDataGeneratedAccessors)

- (void)addChannelsObject:(NSManagedObject *)value;
- (void)removeChannelsObject:(NSManagedObject *)value;
- (void)addChannels:(NSSet *)values;
- (void)removeChannels:(NSSet *)values;

@end
