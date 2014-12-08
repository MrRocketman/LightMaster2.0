//
//  SequenceLogic.h
//  LightMaster
//
//  Created by James Adams on 12/1/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import <Foundation/Foundation.h>

#define CHANNEL_HEIGHT 20.0
#define AUTO_SCROLL_REFRESH_RATE 0.03

enum
{
    CommandTypeDelete,
    CommandTypeOn,
    CommandTypeUp,
    CommandTypeDown,
    CommandTypeTwinkle,
    CommandTypePulse
};

@interface SequenceLogic : NSObject

+ (SequenceLogic *)sharedInstance;

@property (assign, nonatomic) float magnification;
@property (assign, nonatomic) float currentTime;
@property (assign, nonatomic) int commandType;

- (void)updateMagnification:(float)newMagnification;

- (float)timeToX:(float)time;
- (float)xToTime:(int)x;
- (float)widthForTimeInterval:(float)timeInterval;
- (int)numberOfChannels;
- (int)numberOfAudioChannels;

@end
