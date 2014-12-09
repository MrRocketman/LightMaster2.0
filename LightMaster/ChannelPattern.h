//
//  ChannelPattern.h
//  LightMaster
//
//  Created by James Adams on 12/8/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Channel, ChannelPattern;

@interface ChannelPattern : NSManagedObject

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * uuid;
@property (nonatomic, retain) NSSet *channels;
@property (nonatomic, retain) NSSet *childrenChannelPatterns;
@property (nonatomic, retain) NSSet *parentChannelPatterns;
@end

@interface ChannelPattern (CoreDataGeneratedAccessors)

- (void)addChannelsObject:(Channel *)value;
- (void)removeChannelsObject:(Channel *)value;
- (void)addChannels:(NSSet *)values;
- (void)removeChannels:(NSSet *)values;

- (void)addChildrenChannelPatternsObject:(ChannelPattern *)value;
- (void)removeChildrenChannelPatternsObject:(ChannelPattern *)value;
- (void)addChildrenChannelPatterns:(NSSet *)values;
- (void)removeChildrenChannelPatterns:(NSSet *)values;

- (void)addParentChannelPatternsObject:(ChannelPattern *)value;
- (void)removeParentChannelPatternsObject:(ChannelPattern *)value;
- (void)addParentChannelPatterns:(NSSet *)values;
- (void)removeParentChannelPatterns:(NSSet *)values;

@end
