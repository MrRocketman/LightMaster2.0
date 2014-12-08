//
//  SequenceLogic.m
//  LightMaster
//
//  Created by James Adams on 12/1/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import "SequenceLogic.h"
#import "CoreDataManager.h"
#import "NSManagedObjectContext+Queryable.h"
#import "Sequence.h"
#import "SequenceTatum.h"
#import "ControlBox.h"
#import "Channel.h"
#import "Audio.h"

#define SECONDS_TO_PIXELS 25.0

@implementation SequenceLogic

+ (SequenceLogic *)sharedInstance
{
    static dispatch_once_t once;
    static SequenceLogic *instance;
    dispatch_once(&once, ^
                  {
                      instance = [[SequenceLogic alloc] init];
                  });
    return instance;
}

- (id)init
{
    self = [super init];
    if(self)
    {
        self.magnification = 1.0;
        self.currentTime = 1.0;
        self.commandType = CommandTypeOn;
    }
    
    return self;
}

- (void)updateMagnification:(float)newMagnification
{
    float previousMagnification = self.magnification;
    if(newMagnification > 1.0001)
    {
        self.magnification += newMagnification - 1.0;
        if(self.magnification > 20.0)
        {
            self.magnification = previousMagnification;
        }
    }
    else if(newMagnification < 0.9999)
    {
        self.magnification -= 1.0 - newMagnification; // A fudge since maginifcation is limited from 1-5
        if(self.magnification < 0.25)
        {
            self.magnification = previousMagnification;
        }
    }
}

- (float)timeToX:(float)time
{
    int x = [self widthForTimeInterval:time];
    
    return x;
}

- (float)xToTime:(int)x
{
    if(x > 0)
    {
        return  x / self.magnification / SECONDS_TO_PIXELS;
    }
    
    return 0;
}

- (float)widthForTimeInterval:(float)timeInterval
{
    return (timeInterval * self.magnification * SECONDS_TO_PIXELS);
}

- (int)numberOfChannels
{
    NSArray *controlBoxes = [[[[CoreDataManager sharedManager].managedObjectContext ofType:@"ControlBox"] where:@"sequence CONTAINS %@", [CoreDataManager sharedManager].currentSequence] toArray];
    int channelCount = 0;
    for(ControlBox *box in controlBoxes)
    {
        channelCount += (int)box.channels.count;
    }
    return channelCount;
}

- (int)numberOfAudioChannels
{
    NSArray *userAudioAnalysisTracks = [[[[CoreDataManager sharedManager].managedObjectContext ofType:@"ControlBox"] where:@"analysisSequence == %@", [CoreDataManager sharedManager].currentSequence] toArray];
    int audioAnalysisChannelCount = 0;
    for(ControlBox *track in userAudioAnalysisTracks)
    {
        audioAnalysisChannelCount += (int)track.channels.count;
    }
    return audioAnalysisChannelCount;
}

@end
