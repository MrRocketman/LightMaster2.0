//
//  Command.h
//  LightMaster
//
//  Created by James Adams on 12/8/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Channel, SequenceTatum;

@interface Command : NSManagedObject

@property (nonatomic, retain) NSNumber * sendComplete;
@property (nonatomic, retain) NSString * uuid;
@property (nonatomic, retain) Channel *channel;
@property (nonatomic, retain) SequenceTatum *endTatum;
@property (nonatomic, retain) SequenceTatum *startTatum;

@end
