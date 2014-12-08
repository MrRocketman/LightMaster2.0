//
//  CommandFade.h
//  LightMaster
//
//  Created by James Adams on 12/7/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Command.h"


@interface CommandFade : Command

@property (nonatomic, retain) NSNumber * startBrightness;
@property (nonatomic, retain) NSNumber * endBrightness;

@end
