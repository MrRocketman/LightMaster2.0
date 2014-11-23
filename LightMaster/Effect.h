//
//  Effect.h
//  LightMaster
//
//  Created by James Adams on 11/23/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Command;

@interface Effect : NSManagedObject

@property (nonatomic, retain) NSSet *commands;
@end

@interface Effect (CoreDataGeneratedAccessors)

- (void)addCommandsObject:(Command *)value;
- (void)removeCommandsObject:(Command *)value;
- (void)addCommands:(NSSet *)values;
- (void)removeCommands:(NSSet *)values;

@end
