//
//  Channel.h
//  LightMaster
//
//  Created by James Adams on 12/2/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ChannelPattern, Command, ControlBox;

@interface Channel : NSManagedObject

@property (nonatomic, retain) id color;
@property (nonatomic, retain) NSNumber * idNumber;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSSet *channelPatterns;
@property (nonatomic, retain) NSSet *command;
@property (nonatomic, retain) ControlBox *controlBox;
@end

@interface Channel (CoreDataGeneratedAccessors)

- (void)addChannelPatternsObject:(ChannelPattern *)value;
- (void)removeChannelPatternsObject:(ChannelPattern *)value;
- (void)addChannelPatterns:(NSSet *)values;
- (void)removeChannelPatterns:(NSSet *)values;

- (void)addCommandObject:(Command *)value;
- (void)removeCommandObject:(Command *)value;
- (void)addCommand:(NSSet *)values;
- (void)removeCommand:(NSSet *)values;

@end
