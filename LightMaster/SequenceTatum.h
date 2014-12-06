//
//  SequenceTatum.h
//  LightMaster
//
//  Created by James Adams on 12/5/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Command, Sequence;

@interface SequenceTatum : NSManagedObject

@property (nonatomic, retain) NSNumber *time;
@property (nonatomic, retain) NSSet *endCommands;
@property (nonatomic, retain) Sequence *sequence;
@property (nonatomic, retain) NSSet *startCommands;
@end

@interface SequenceTatum (CoreDataGeneratedAccessors)

- (void)addEndCommandsObject:(Command *)value;
- (void)removeEndCommandsObject:(Command *)value;
- (void)addEndCommands:(NSSet *)values;
- (void)removeEndCommands:(NSSet *)values;

- (void)addStartCommandsObject:(Command *)value;
- (void)removeStartCommandsObject:(Command *)value;
- (void)addStartCommands:(NSSet *)values;
- (void)removeStartCommands:(NSSet *)values;

@end
