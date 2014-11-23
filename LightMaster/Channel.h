//
//  Channel.h
//  LightMaster
//
//  Created by James Adams on 11/23/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ChannelPattern, Command, ControlBox;

@interface Channel : NSManagedObject

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * number;
@property (nonatomic, retain) NSNumber * color;
@property (nonatomic, retain) ControlBox *controlBox;
@property (nonatomic, retain) NSSet *command;
@property (nonatomic, retain) NSSet *channelPatterns;
@end

@interface Channel (CoreDataGeneratedAccessors)

- (void)addCommandObject:(Command *)value;
- (void)removeCommandObject:(Command *)value;
- (void)addCommand:(NSSet *)values;
- (void)removeCommand:(NSSet *)values;

- (void)addChannelPatternsObject:(ChannelPattern *)value;
- (void)removeChannelPatternsObject:(ChannelPattern *)value;
- (void)addChannelPatterns:(NSSet *)values;
- (void)removeChannelPatterns:(NSSet *)values;

@end
