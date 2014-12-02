//
//  SequenceLogic.h
//  LightMaster
//
//  Created by James Adams on 12/1/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import <Foundation/Foundation.h>

#define CHANNEL_HEIGHT 20.0

@interface SequenceLogic : NSObject

+ (SequenceLogic *)sharedInstance;

@property (assign, nonatomic) float magnification;
@property (assign, nonatomic) float currentTime;

- (void)updateMagnification:(float)newMagnification;

- (NSRect)sequenceFrame;

- (float)timeToX:(float)time;
- (float)xToTime:(int)x;
- (float)widthForTimeInterval:(float)timeInterval;

@end
