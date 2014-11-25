//
//  UserAudioAnalysisTatums.h
//  LightMaster
//
//  Created by James Adams on 11/24/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class UserAudioAnalysis;

@interface UserAudioAnalysisTatums : NSManagedObject

@property (nonatomic, retain) UNKNOWN_TYPE startTime;
@property (nonatomic, retain) UserAudioAnalysis *audioAnalysis;

@end
