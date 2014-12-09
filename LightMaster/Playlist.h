//
//  Playlist.h
//  LightMaster
//
//  Created by James Adams on 12/8/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Sequence;

@interface Playlist : NSManagedObject

@property (nonatomic, retain) NSDate * endTime;
@property (nonatomic, retain) NSDate * startTime;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * uuid;
@property (nonatomic, retain) NSSet *sequences;
@end

@interface Playlist (CoreDataGeneratedAccessors)

- (void)addSequencesObject:(Sequence *)value;
- (void)removeSequencesObject:(Sequence *)value;
- (void)addSequences:(NSSet *)values;
- (void)removeSequences:(NSSet *)values;

@end
