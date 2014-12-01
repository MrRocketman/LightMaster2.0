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
#import "UserAudioAnalysis.h"
#import "UserAudioAnalysisTrack.h"
#import "UserAudioAnalysisTrackChannel.h"

#define CHANNEL_HEIGHT 20.0

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

- (NSRect)sequenceFrame
{
    // Calculate the frame
    int channelsCount = 1 + (int)[[[[CoreDataManager sharedManager].managedObjectContext ofType:@"Channel"] toArray] count] + (int)[[[[CoreDataManager sharedManager].managedObjectContext ofType:@"UserAudioAnalysisTrackChannel"] toArray] count] + (int)[CoreDataManager sharedManager].currentSequence.audio.userAudioAnalysis.tracks.count + ([CoreDataManager sharedManager].currentSequence.audio ? 1 : 0);
    int frameHeight = 0;
    int frameWidth = [self timeToX:[[CoreDataManager sharedManager].currentSequence.endTime floatValue]];
    // Set the Frame
    frameHeight = channelsCount * CHANNEL_HEIGHT;
    if(frameWidth <= 700)
    {
        frameWidth = 700;
    }
    if(frameHeight <= 300)
    {
        frameHeight = 300;
    }
    return NSMakeRect(0, 0, frameWidth, frameHeight);
}

- (int)timeToX:(float)time
{
    int x = [self widthForTimeInterval:time];
    
    return x;
}

- (float)xToTime:(int)x
{
    if(x > 0)
    {
        //return  x / self.zoomLevel / PIXEL_TO_ZOOM_RATIO;
    }
    
    return 0;
}

- (int)widthForTimeInterval:(float)timeInterval
{
    return 100;// (timeInterval * self.zoomLevel * PIXEL_TO_ZOOM_RATIO);
}

@end
