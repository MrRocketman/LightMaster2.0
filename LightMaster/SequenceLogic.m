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

#pragma mark - Math

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

#pragma mark - SerialPort

- (void)sendPacketToSerialPort:(uint8_t *)packet packetLength:(int)length
{
    if([self.serialPort isOpen])
    {
        /*for(int i = 0; i < length; i ++)
         {
         NSLog(@"send:0x%02x", packet[i]);
         }*/
        [self.serialPort sendData:[NSData dataWithBytes:packet length:length]];
    }
    else
    {
        //NSLog(@"Can't send:%@", [NSString stringWithCString:packet encoding:NSStringEncodingConversionAllowLossy]);
        for(int i = 0; i < length; i ++)
        {
            NSLog(@"can't send c:%c d:%d h:%02x", packet[i], packet[i], packet[i]);
        }
        //NSLog(@"Couldn't send. Not connected");
    }
}

- (void)sendStringToSerialPort:(NSString *)text
{
    if([self.serialPort isOpen])
    {
        //NSLog(@"Writing:%@:", text);
        [self.serialPort sendData:[text dataUsingEncoding:NSUTF8StringEncoding]];
    }
    else
    {
        NSLog(@"Can't send:%@", text);
        for(int i = 0; i < [text length]; i ++)
        {
            NSLog(@"c:%c d:%d h:%x", [text characterAtIndex:i], [text characterAtIndex:i], [text characterAtIndex:i]);
        }
    }
}

#pragma mark - ORSSerialPortDelegate

- (void)serialPortWasOpened:(ORSSerialPort *)serialPort
{
    //self.openCloseButton.title = @"Close";
}

- (void)serialPortWasClosed:(ORSSerialPort *)serialPort
{
    //self.openCloseButton.title = @"Open";
}

- (void)serialPort:(ORSSerialPort *)serialPort didReceiveData:(NSData *)data
{
    // This method is called if data arrives
    if ([data length] > 0)
    {
        NSString *receivedText = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"Serial Port Data Received: %@",receivedText);
        for(int i = 0; i < [receivedText length]; i ++)
        {
            char character = [receivedText characterAtIndex:i];
            int characterValue = (int)character;
            NSLog(@"c:%c v:%i", character, characterValue);
        }
        
        // ToDo: Do something with received text
    }
    // Port closed
    else
    {
        NSLog(@"Port was closed on a readData operation...not good!");
    }
}

- (void)serialPortWasRemovedFromSystem:(ORSSerialPort *)serialPort;
{
    // After a serial port is removed from the system, it is invalid and we must discard any references to it
    self.serialPort = nil;
}

- (void)serialPort:(ORSSerialPort *)theSerialPort didEncounterError:(NSError *)error
{
    NSLog(@"Serial port %@ encountered an error: %@", theSerialPort, error);
}

@end
