//
//  Command.h
//  LightMaster
//
//  Created by James Adams on 11/23/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Channel, Effect;

@interface Command : NSManagedObject

@property (nonatomic, retain) NSNumber * startTime;
@property (nonatomic, retain) NSNumber * endTime;
@property (nonatomic, retain) NSNumber * startBrightness;
@property (nonatomic, retain) NSNumber * fadeInDuration;
@property (nonatomic, retain) NSNumber * brightness;
@property (nonatomic, retain) NSNumber * endBrightness;
@property (nonatomic, retain) NSNumber * fadeOutDuration;
@property (nonatomic, retain) Channel *channel;
@property (nonatomic, retain) Effect *effects;

@end
