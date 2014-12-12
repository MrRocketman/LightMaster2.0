//
//  Channel.h
//  LightMaster
//
//  Created by James Adams on 12/9/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ChannelPattern, Command, ControlBox;

@interface Channel : NSManagedObject

@property (nonatomic, retain) id color;
@property (nonatomic, retain) NSNumber * idNumber;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * uuid;
@property (nonatomic, retain) NSNumber * watts;
@property (nonatomic, retain) NSNumber * volts;
@property (nonatomic, retain) NSNumber * numberOfLights;
@property (nonatomic, retain) NSSet *channelPatterns;
@property (nonatomic, retain) NSSet *commands;
@property (nonatomic, retain) ControlBox *controlBox;
@end

@interface Channel (CoreDataGeneratedAccessors)

- (void)addChannelPatternsObject:(ChannelPattern *)value;
- (void)removeChannelPatternsObject:(ChannelPattern *)value;
- (void)addChannelPatterns:(NSSet *)values;
- (void)removeChannelPatterns:(NSSet *)values;

- (void)addCommandsObject:(Command *)value;
- (void)removeCommandsObject:(Command *)value;
- (void)addCommands:(NSSet *)values;
- (void)removeCommands:(NSSet *)values;

@end

@interface ColorToDataTransformer : NSValueTransformer
@end
