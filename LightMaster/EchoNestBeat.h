//
//  EchoNestBeat.h
//  LightMaster
//
//  Created by James Adams on 11/24/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class EchoNestAudioAnalysis;

@interface EchoNestBeat : NSManagedObject

@property (nonatomic, retain) NSNumber * confidence;
@property (nonatomic, retain) NSNumber * duration;
@property (nonatomic, retain) NSNumber * start;
@property (nonatomic, retain) EchoNestAudioAnalysis *echoNestAudioAnalysis;

@end
