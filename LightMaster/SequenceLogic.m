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
#import "Command.h"
#import "CommandOn.h"
#import "CommandFade.h"

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
        self.magnification = 5.0;
        self.currentTime = 1.0;
        self.commandType = CommandTypeSelect;
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
    NSSet *audioAnalysisControlBoxes = [CoreDataManager sharedManager].currentSequence.controlBoxes;
    int channelCount = 0;
    for(ControlBox *box in audioAnalysisControlBoxes)
    {
        channelCount += (int)box.channels.count;
    }
    return channelCount;
}

- (int)numberOfAudioChannels
{
    
    NSSet *audioAnalysisControlBoxes = [CoreDataManager sharedManager].currentSequence.analysisControlBoxes;
    int channelCount = 0;
    for(ControlBox *box in audioAnalysisControlBoxes)
    {
        channelCount += (int)box.channels.count;
    }
    return channelCount;
}

#pragma mark - Commands

- (void)updateCommandsForCurrentTime
{
    self.commandsForCurrentTime = [[[[CoreDataManager sharedManager].managedObjectContext ofType:@"Command"] where:@"%f >= startTatum.time AND %f <= endTatum.time", [SequenceLogic sharedInstance].currentTime, [SequenceLogic sharedInstance].currentTime] toArray];
}

- (float)currentBrightnessForChannel:(Channel *)channel
{
    if([SequenceLogic sharedInstance].showChannelBrightness && channel.commands)
    {
        Command *command;
        for(Command *eachCommand in self.commandsForCurrentTime)
        {
            if(eachCommand.channel == channel)
            {
                command = eachCommand;
                break;
            }
        }
        //Command *command = [[[[[CoreDataManager sharedManager].managedObjectContext ofType:@"Command"] where:@"channel == %@ AND %f >= startTatum.time AND %f <= endTatum.time", channel, [SequenceLogic sharedInstance].currentTime, [SequenceLogic sharedInstance].currentTime] toArray] firstObject];
        if(command)
        {
            if([command isMemberOfClass:[CommandOn class]])
            {
                return [((CommandOn *)command).brightness floatValue];
            }
            else if([command isMemberOfClass:[CommandFade class]])
            {
                CommandFade *commandFade = (CommandFade *)command;
                float commandDuration = [commandFade.endTatum.time floatValue] - [commandFade.startTatum.time floatValue];
                float percentThroughCommand = ([commandFade.endTatum.time floatValue] - [SequenceLogic sharedInstance].currentTime) / commandDuration;
                float brightnessChange = [commandFade.endBrightness floatValue] - [commandFade.startBrightness floatValue];
                return 1.0 - ([commandFade.startBrightness floatValue] + percentThroughCommand * brightnessChange);
            }
        }
        else
        {
            return 0.0;
        }
    }
    
    return 1.0;
}

@end
