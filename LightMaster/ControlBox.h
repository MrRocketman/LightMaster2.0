//
//  ControlBox.h
//  LightMaster
//
//  Created by James Adams on 11/23/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Channel, Sequence;

@interface ControlBox : NSManagedObject

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * id;
@property (nonatomic, retain) NSSet *channels;
@property (nonatomic, retain) NSSet *sequence;
@end

@interface ControlBox (CoreDataGeneratedAccessors)

- (void)addChannelsObject:(Channel *)value;
- (void)removeChannelsObject:(Channel *)value;
- (void)addChannels:(NSSet *)values;
- (void)removeChannels:(NSSet *)values;

- (void)addSequenceObject:(Sequence *)value;
- (void)removeSequenceObject:(Sequence *)value;
- (void)addSequence:(NSSet *)values;
- (void)removeSequence:(NSSet *)values;

@end
