//
//  EchoNestTimbre.h
//  LightMaster
//
//  Created by James Adams on 11/24/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class EchoNestSegment;

@interface EchoNestTimbre : NSManagedObject

@property (nonatomic, retain) NSNumber * timbre;
@property (nonatomic, retain) EchoNestSegment *segment;

@end
