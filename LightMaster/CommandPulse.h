//
//  CommandPulse.h
//  LightMaster
//
//  Created by James Adams on 11/24/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ComplexCommand.h"


@interface CommandPulse : ComplexCommand

@property (nonatomic, retain) NSNumber * speed;

@end
