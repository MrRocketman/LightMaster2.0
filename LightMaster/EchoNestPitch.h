//
//  EchoNestPitch.h
//  LightMaster
//
//  Created by James Adams on 11/23/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class EchoNestSegment;

@interface EchoNestPitch : NSManagedObject

@property (nonatomic, retain) NSNumber * pitch;
@property (nonatomic, retain) EchoNestSegment *segment;

@end
