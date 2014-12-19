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
#import "ORSSerialPort.h"
#import <AVFoundation/AVFoundation.h>
#import "ENAPIRequest.h"
#import "ENAPI.h"
#import "EchoNestAudioAnalysis.h"
#import "EchoNestSection.h"
#import "EchoNestBar.h"
#import "EchoNestBeat.h"
#import "EchoNestTatum.h"
#import "EchoNestSegment.h"
#import "EchoNestPitch.h"
#import "EchoNestTimbre.h"

#define SECONDS_TO_PIXELS 25.0
#define MAX_BRIGHTNESS 127
#define MAX_SHORT_DURATION 2.56
#define MAX_LONG_DURATION 25.6

@interface SequenceLogic()

@property (strong, nonatomic) AVAudioPlayer *audioPlayer;
@property (assign, nonatomic) BOOL isPlayButton;
@property (assign, nonatomic) BOOL isPlaySelection;
@property (assign, nonatomic) BOOL isPlayFromCurrentTime;
@property (strong, nonatomic) NSTimer *audioTimer;
@property (strong, nonatomic) Audio *currentAudio;
@property (assign, nonatomic) float lastChannelUpdateTime;

@end

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
        self.drawCurrentSequence = YES;
        
        if(![CoreDataManager sharedManager].currentSequence)
        {
            [[CoreDataManager sharedManager] getLatestOrCreateNewSequence];
            [self resetCommandsSendComplete];
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadSequenceFromNotification:) name:@"CurrentSequenceChange" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentTimeChange:) name:@"CurrentTimeChange" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playPause:) name:@"PlayPause" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playPauseSelection:) name:@"PlayPauseSelection" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playPauseFromCurrentTime:) name:@"PlayPauseFromCurrentTime" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deselectMouse:) name:@"DeselectMouse" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(echoNestUploadUpdate:) name:@"ENAPIRequest.didSendBodyData" object:nil];
        
        self.isPlayButton = YES;
        [self reloadAudio];
        [self currentTimeChange:nil];
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
    const float epsilon = 0.030;
    self.commandsForCurrentTime = [[[[CoreDataManager sharedManager].managedObjectContext ofType:@"Command"] where:@"%f >= startTatum.time AND %f <= endTatum.time AND sequence == %@", self.currentTime + epsilon, self.currentTime, [CoreDataManager sharedManager].currentSequence] toArray];
    
    [self sendCommandsForCurrentTime];
}

- (void)resetCommandsSendComplete
{
    NSArray *commandsToReset = [[[[CoreDataManager sharedManager].managedObjectContext ofType:@"Command"] where:@"startTatum.time >= %f AND sequence == %@", self.currentTime, [CoreDataManager sharedManager].currentSequence] toArray];
    for(Command *command in commandsToReset)
    {
        command.sendComplete = @(NO);
    }
    
    [[CoreDataManager sharedManager] saveContext];
}

- (void)sendCommandsForCurrentTime
{
    const float epsilon = 0.005;
    
    for(Command *command in self.commandsForCurrentTime)
    {
        uint8_t packet[32] = {0};
        uint8_t packetIndex = 0;
        // Set the controlBox packet byte
        packet[packetIndex] = (uint8_t)[command.channel.controlBox.idNumber intValue];
        packetIndex ++;
        
        // If the command hasn't been sent, send it
        if(![command.sendComplete boolValue] && command.channel.controlBox.analysisSequence == nil)
        {
            // Command on
            if([command isMemberOfClass:[CommandOn class]])
            {
                CommandOn *commandOn = (CommandOn *)command;
                float commandDuration = [commandOn.endTatum.time floatValue] - [commandOn.startTatum.time floatValue];
                
                // Does the command have a custom brightness
                if([commandOn.brightness floatValue] < 1.0 - epsilon)
                {
                    if(commandDuration <= MAX_SHORT_DURATION)
                    {
                        // Set the command id byte to brightness for hundredths for 1 channel
                        packet[packetIndex] = 0x12;
                        packetIndex ++;
                    }
                    else if(commandDuration <= MAX_LONG_DURATION)
                    {
                        // Set the command id byte to brightness for tenths for 1 channel
                        packet[packetIndex] = 0x13;
                        packetIndex ++;
                    }
                    
                    // Set the channel id byte
                    packet[packetIndex] = (uint8_t)[commandOn.channel.idNumber intValue];
                    packetIndex ++;
                    
                    // Set the brightness byte
                    packet[packetIndex] = (uint8_t)([commandOn.brightness floatValue] * MAX_BRIGHTNESS);
                    packetIndex ++;
                    
                    if(commandDuration <= MAX_SHORT_DURATION)
                    {
                        // Set the command id byte to brightness for hundredths for 1 channel
                        packet[packetIndex] = (uint8_t)(commandDuration * 100);
                        packetIndex ++;
                    }
                    else if(commandDuration <= MAX_LONG_DURATION)
                    {
                        // Set the command id byte to brightness for tenths for 1 channel
                        packet[packetIndex] = (uint8_t)(commandDuration * 10);
                        packetIndex ++;
                    }
                }
                // Full brightness command
                else
                {
                    // Command id byte
                    if(commandDuration <= MAX_SHORT_DURATION)
                    {
                        // Set the command id byte to brightness for hundredths for 1 channel
                        packet[packetIndex] = 0x05;
                        packetIndex ++;
                    }
                    else if(commandDuration <= MAX_LONG_DURATION)
                    {
                        // Set the command id byte to brightness for tenths for 1 channel
                        packet[packetIndex] = 0x06;
                        packetIndex ++;
                    }
                    
                    // Set the channel id byte
                    packet[packetIndex] = (uint8_t)[commandOn.channel.idNumber intValue];
                    packetIndex ++;
                    
                    // Duration byte
                    if(commandDuration <= MAX_SHORT_DURATION)
                    {
                        // Set the command id byte to brightness for hundredths for 1 channel
                        packet[packetIndex] = (uint8_t)(commandDuration * 100);
                        packetIndex ++;
                    }
                    else if(commandDuration <= MAX_LONG_DURATION)
                    {
                        // Set the command id byte to brightness for tenths for 1 channel
                        packet[packetIndex] = (uint8_t)(commandDuration * 10);
                        packetIndex ++;
                    }
                }
            }
            // Command on
            else if([command isMemberOfClass:[CommandFade class]])
            {
                CommandFade *commandFade = (CommandFade *)command;
                float commandDuration = [commandFade.endTatum.time floatValue] - [commandFade.startTatum.time floatValue];
                
                // Does the command have a custom brightness
                if(([commandFade.startBrightness floatValue] < 1.0 - epsilon && [commandFade.startBrightness floatValue] > 0.0 + epsilon) || ([commandFade.endBrightness floatValue] < 1.0 - epsilon && [commandFade.endBrightness floatValue] > 0.0 + epsilon))
                {
                    if(commandDuration <= MAX_SHORT_DURATION)
                    {
                        // Set the command id byte to custom fade for hundredths for 1 channel
                        packet[packetIndex] = 0x24;
                        packetIndex ++;
                    }
                    else if(commandDuration <= MAX_LONG_DURATION)
                    {
                        // Set the command id byte to custom fade for tenths for 1 channel
                        packet[packetIndex] = 0x25;
                        packetIndex ++;
                    }
                    
                    // Set the channel id byte
                    packet[packetIndex] = (uint8_t)[commandFade.channel.idNumber intValue];
                    packetIndex ++;
                    
                    // Set the startBrightness byte
                    packet[packetIndex] = (uint8_t)([commandFade.startBrightness floatValue] * MAX_BRIGHTNESS);
                    packetIndex ++;
                    
                    // Set the endBrightness byte
                    packet[packetIndex] = (uint8_t)([commandFade.endBrightness floatValue] * MAX_BRIGHTNESS);
                    packetIndex ++;
                    
                    if(commandDuration <= MAX_SHORT_DURATION)
                    {
                        // Set the command id byte to brightness for hundredths for 1 channel
                        packet[packetIndex] = (uint8_t)(commandDuration * 100);
                        packetIndex ++;
                    }
                    else if(commandDuration <= MAX_LONG_DURATION)
                    {
                        // Set the command id byte to brightness for tenths for 1 channel
                        packet[packetIndex] = (uint8_t)(commandDuration * 10);
                        packetIndex ++;
                    }
                }
                // Full brightness fade
                else
                {
                    // Command id byte
                    if(commandDuration <= MAX_SHORT_DURATION)
                    {
                        // Fade down command
                        if([commandFade.startBrightness floatValue] > 1.0 - epsilon)
                        {
                            // Set the command id byte to fade down for hundredths for 1 channel
                            packet[packetIndex] = 0x22;
                            packetIndex ++;
                        }
                        // Fade up command
                        else
                        {
                            // Set the command id byte to fade up for hundredths for 1 channel
                            packet[packetIndex] = 0x20;
                            packetIndex ++;
                        }
                    }
                    else if(commandDuration <= MAX_LONG_DURATION)
                    {
                        // Fade down command
                        if([commandFade.startBrightness floatValue] > 1.0 - epsilon)
                        {
                            // Set the command id byte to fade down for tenths for 1 channel
                            packet[packetIndex] = 0x23;
                            packetIndex ++;
                        }
                        // Fade up command
                        else
                        {
                            // Set the command id byte to fade up for tenths for 1 channel
                            packet[packetIndex] = 0x21;
                            packetIndex ++;
                        }
                    }
                    
                    // Set the channel id byte
                    packet[packetIndex] = (uint8_t)[commandFade.channel.idNumber intValue];
                    packetIndex ++;
                    
                    // Duration byte
                    if(commandDuration <= MAX_SHORT_DURATION)
                    {
                        // Set the command id byte to brightness for hundredths for 1 channel
                        packet[packetIndex] = (uint8_t)(commandDuration * 100);
                        packetIndex ++;
                    }
                    else if(commandDuration <= MAX_LONG_DURATION)
                    {
                        // Set the command id byte to brightness for tenths for 1 channel
                        packet[packetIndex] = (uint8_t)(commandDuration * 10);
                        packetIndex ++;
                    }
                }
            }
            
            // Set the end of packet byte
            packet[packetIndex] = 0xFF;
            packetIndex ++;
            
            // Send the packet
            [self sendPacketToSerialPort:packet packetLength:packetIndex];
            
            // Mark as sent so it doesn't get sent again
            command.sendComplete = @(YES);
        }
    }
}

- (float)currentBrightnessForChannel:(Channel *)channel
{
    if(self.showChannelBrightness && channel.commands)
    {
        // Find the command for this channel
        Command *command;
        for(Command *eachCommand in self.commandsForCurrentTime)
        {
            if(eachCommand.channel == channel)
            {
                command = eachCommand;
                break;
            }
        }
        
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
                float percentThroughCommand = ([commandFade.endTatum.time floatValue] - self.currentTime) / commandDuration;
                float brightnessChange = [commandFade.endBrightness floatValue] - [commandFade.startBrightness floatValue];
                float maxBrightness = ([commandFade.startBrightness floatValue] > [commandFade.endBrightness floatValue] ? [commandFade.startBrightness floatValue] : [commandFade.endBrightness floatValue]);
                return maxBrightness - ([commandFade.startBrightness floatValue] + percentThroughCommand * brightnessChange);
            }
        }
        else
        {
            return 0.0;
        }
    }
    
    return 1.0;
}

- (void)addCommandForChannel:(Channel *)channel startTatum:(SequenceTatum *)startTatum endTatum:(SequenceTatum *)endTatum startBrightness:(float)startBrightness endBrightness:(float)endBrightness
{
    // Modify any commands that we are overlapping
    const float epsilon = 0.0001;
    float startTatumTime = [startTatum.time floatValue];
    float endTatumTime = [endTatum.time floatValue];
    // We overlap the start, so adjust the start
    NSArray *commandsToModify = [[[[[CoreDataManager sharedManager].managedObjectContext ofType:@"Command"] where:@"sequence == %@ AND channel == %@ AND startTatum.time > %f AND startTatum.time < %f", [CoreDataManager sharedManager].currentSequence, channel, startTatumTime - epsilon, endTatumTime + epsilon] orderBy:@"startTatum.time"] toArray];
    for(Command *command in commandsToModify)
    {
        command.startTatum = endTatum;
    }
    // We overlap the end so adjust the end
    commandsToModify = [[[[[CoreDataManager sharedManager].managedObjectContext ofType:@"Command"] where:@"sequence == %@ AND channel == %@ AND endTatum.time > %f AND endTatum.time < %f", [CoreDataManager sharedManager].currentSequence, channel, startTatumTime - epsilon, endTatumTime + epsilon] orderBy:@"startTatum.time"] toArray];
    for(Command *command in commandsToModify)
    {
        command.endTatum = startTatum;
    }
    // We overlap the whole thing so delete it
    commandsToModify = [[[[[CoreDataManager sharedManager].managedObjectContext ofType:@"Command"] where:@"sequence == %@ AND channel == %@ AND startTatum.time > %f AND endTatum.time < %f", [CoreDataManager sharedManager].currentSequence, channel, startTatumTime - epsilon, endTatumTime + epsilon] orderBy:@"startTatum.time"] toArray];
    for(Command *command in commandsToModify)
    {
        [[CoreDataManager sharedManager].managedObjectContext deleteObject:command];
    }
    // We are in the middle of a command, so split it
    commandsToModify = [[[[[CoreDataManager sharedManager].managedObjectContext ofType:@"Command"] where:@"sequence == %@ AND channel == %@ AND startTatum.time < %f AND endTatum.time > %f", [CoreDataManager sharedManager].currentSequence, channel, startTatumTime + epsilon, endTatumTime - epsilon] orderBy:@"startTatum.time"] toArray];
    for(Command *command in commandsToModify)
    {
        SequenceTatum *oldEndTatum = command.endTatum;
        command.endTatum = startTatum;
        if([command isMemberOfClass:[CommandOn class]])
        {
            CommandOn *commandOn = (CommandOn *)command;
            [[CoreDataManager sharedManager] addCommandOnWithStartTatum:endTatum endTatum:oldEndTatum brightness:[commandOn.brightness floatValue] channel:command.channel];
        }
        else if ([command isMemberOfClass:[CommandFade class]])
        {
            CommandFade *commandFade = (CommandFade *)command;
            float newCommandStartBrightness = ([commandFade.endBrightness floatValue] > [commandFade.startBrightness floatValue] ? 0 : [commandFade.startBrightness floatValue]);
            float newCommandEndBrightness = ([commandFade.endBrightness floatValue] > [commandFade.startBrightness floatValue] ? [commandFade.endBrightness floatValue] : 0);
            [[CoreDataManager sharedManager] addCommandFadeWithStartTatum:endTatum endTatum:oldEndTatum startBrightness:newCommandStartBrightness endBrightness:newCommandEndBrightness channel:command.channel];
            commandFade.endBrightness = @(newCommandEndBrightness);
        }
    }
    
    // Add the appropriate command
    if(startBrightness > endBrightness - epsilon && startBrightness < endBrightness + epsilon)
    {
        // See if we are merging commands
        CommandOn *nextCommand = [[[[[CoreDataManager sharedManager].managedObjectContext ofType:@"CommandOn"] where:@"sequence == %@ AND channel == %@ AND startTatum.time > %f AND startTatum.time < %f AND brightness > %f AND brightness < %f", [CoreDataManager sharedManager].currentSequence, channel, endTatumTime - epsilon, endTatumTime + epsilon, startBrightness - epsilon, startBrightness + epsilon] toArray] firstObject];
        CommandOn *previousCommand = [[[[[CoreDataManager sharedManager].managedObjectContext ofType:@"CommandOn"] where:@"sequence == %@ AND channel == %@ AND endTatum.time > %f AND endTatum.time < %f AND brightness > %f AND brightness < %f", [CoreDataManager sharedManager].currentSequence, channel, startTatumTime - epsilon, startTatumTime + epsilon, startBrightness - epsilon, startBrightness + epsilon] toArray] firstObject];
        SequenceTatum *newStartTatum = startTatum;
        SequenceTatum *newEndTatum = endTatum;
        if(nextCommand)
        {
            newEndTatum = nextCommand.endTatum;
            [[CoreDataManager sharedManager].managedObjectContext deleteObject:nextCommand];
        }
        if(previousCommand)
        {
            newStartTatum = previousCommand.startTatum;
            [[CoreDataManager sharedManager].managedObjectContext deleteObject:previousCommand];
        }
        
        // Add the command on
        [[CoreDataManager sharedManager] addCommandOnWithStartTatum:newStartTatum endTatum:newEndTatum brightness:startBrightness channel:channel];
    }
    else
    {
        // Add command fade
        [[CoreDataManager sharedManager] addCommandFadeWithStartTatum:startTatum endTatum:endTatum startBrightness:startBrightness endBrightness:endBrightness channel:channel];
    }
}

#pragma mark - SerialPort

- (void)sendPacketToSerialPort:(uint8_t *)packet packetLength:(int)length
{
    if([self.serialPort isOpen])
    {
        //NSLog(@"Send");
        //for(int i = 0; i < length; i ++)
        //{
        //    NSLog(@"0x%02x", packet[i]);
        //}
        [self.serialPort sendData:[NSData dataWithBytes:packet length:length]];
    }
    else
    {
        //NSLog(@"Can't send:%@", [NSString stringWithCString:packet encoding:NSStringEncodingConversionAllowLossy]);
        //for(int i = 0; i < length; i ++)
        //{
        //    NSLog(@"can't send c:%c d:%d h:%02x", packet[i], packet[i], packet[i]);
        //}
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

#pragma mark - Play Pause

- (void)playPause
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PlayPauseButtonUpdate" object:@(self.isPlayButton)];
    
    if(self.isPlayButton)
    {
        [self.audioPlayer play];
        self.audioTimer = [NSTimer scheduledTimerWithTimeInterval:0.001 target:self selector:@selector(audioTimerFire:) userInfo:nil repeats:YES];
        self.showChannelBrightness = YES;
        self.lastChannelUpdateTime = -1;
    }
    else
    {
        [self.audioPlayer pause];
        [self.audioTimer invalidate];
        self.audioTimer = nil;
        self.showChannelBrightness = NO;
    }
    
    self.isPlayButton = !self.isPlayButton;
}

- (void)playPause:(NSNotification *)notification
{
    self.isPlayFromCurrentTime = NO;
    self.isPlaySelection = NO;
    
    [self playPause];
}

- (void)playPauseSelection:(NSNotification *)notification
{
    self.isPlaySelection = YES;
    self.isPlayFromCurrentTime = NO;
    
    if(self.isPlayButton)
    {
        self.currentTime = [self.mouseBoxSelectStartTatum.time floatValue] - 0.05;
        self.audioPlayer.currentTime = self.currentTime;
    }
    
    [self playPause];
}

- (void)playPauseFromCurrentTime:(NSNotification *)notification
{
    self.isPlayFromCurrentTime = YES;
    self.isPlaySelection = NO;
    
    if(self.isPlayButton)
    {
        self.currentTime = [self.mouseBoxSelectStartTatum.time floatValue];
        self.audioPlayer.currentTime = self.currentTime;
    }
    
    [self playPause];
}

#pragma mark - Time

- (void)audioTimerFire:(NSTimer *)timer
{
    self.currentTime = self.audioPlayer.currentTime;//[[NSDate date] timeIntervalSinceDate:self.playStartDate] + self.playStartTime;
    [self updateTime];
    
    if(self.drawCurrentSequence)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"CurrentTimeChange" object:self];
    }
}

- (void)updateTime
{
    // Loop back to beginning
    if(self.currentTime > [[CoreDataManager sharedManager].currentSequence.endTime floatValue])
    {
        [self.audioPlayer stop];
        [self resetCommandsSendComplete];
        self.currentTime = 0;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SequenceComplete" object:nil];
        
        self.audioPlayer.currentTime = 0;
        self.lastChannelUpdateTime = -1;
        [self.audioPlayer play];
    }
    // If we are playing a selection and get to the end
    else if(self.isPlaySelection && self.currentTime >= [self.mouseBoxSelectEndTatum.time floatValue])
    {
        self.isPlaySelection = NO;
        self.isPlayButton = !self.isPlayButton;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"Pause" object:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"PlayPauseButtonUpdate" object:@(self.isPlayButton)];
        [self.audioPlayer pause];
        [self.audioTimer invalidate];
        self.audioTimer = nil;
        self.showChannelBrightness = NO;
        self.lastChannelUpdateTime = -1;
    }
    
    // Update channel brightness at 30Hz
    [self updateCommandsForCurrentTime];
    if(self.currentTime > self.lastChannelUpdateTime + 0.03)
    {
        self.lastChannelUpdateTime = self.currentTime;
        [self updateCommandsForCurrentTime];
        
        if(self.drawCurrentSequence)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateDimmingDisplay" object:nil];
        }
    }
}

- (void)deselectMouse:(NSNotification *)notification
{
    self.lastChannelUpdateTime = -1;
    [self resetCommandsSendComplete];
}

- (void)currentTimeChange:(NSNotification *)notification
{
    // Only update the audio if the user dragged the time marker
    if(notification.object != self)
    {
        self.audioPlayer.currentTime = self.currentTime;
    }
}

- (void)reloadAudio
{
    NSError *error = nil;
    self.audioPlayer = [[AVAudioPlayer alloc] initWithData:[CoreDataManager sharedManager].currentSequence.audio.audioFile fileTypeHint:[[CoreDataManager sharedManager].currentSequence.audio.audioFilePath pathExtension] error:&error];
    //NSLog(@"Audio error %@, %@", error, [error userInfo]);
    self.audioPlayer.currentTime = 1.0;
    [self.audioPlayer prepareToPlay];
    self.currentAudio = [CoreDataManager sharedManager].currentSequence.audio;
}

- (void)reloadSequenceFromNotification:(NSNotification *)notification
{
    [self reloadSequence];
}

- (void)reloadSequence
{
    if(self.currentAudio != [CoreDataManager sharedManager].currentSequence.audio)
    {
        [self reloadAudio];
    }
}

- (void)skipBack
{
    self.currentTime = 0;
    self.audioPlayer.currentTime = 0;
    self.lastChannelUpdateTime = -1;
    [self resetCommandsSendComplete];
    [self updateTime];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CurrentTimeChange" object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DeselectMouse" object:nil];
}

#pragma mark - Autogen

- (SequenceTatum *)sequenceTatumForCurrentSequenceAtTime:(float)time
{
    const float epsilon = 0.03;
    SequenceTatum *tatum = [[[[[CoreDataManager sharedManager].managedObjectContext ofType:@"SequenceTatum"] where:@"sequence == %@ AND time >= %f AND time <= %f", [CoreDataManager sharedManager].currentSequence, time - epsilon, time + epsilon] toArray] firstObject];
    
    if(tatum)
    {
        return tatum;
    }
    else
    {
        return [[CoreDataManager sharedManager] addSequenceTatumToSequence:[CoreDataManager sharedManager].currentSequence atTime:time];
    }
}

- (void)echoNestAutoGenForCurrentSequence
{
    float intensity = 1.0;
    const int pitchesToUse = 12;
    
    // Get the audioAnalysis for this sequence
    EchoNestAudioAnalysis *audioAnalysis = [CoreDataManager sharedManager].currentSequence.audio.echoNestAudioAnalysis;
    
    // If the sequence has an analysis, autogen commands
    if(audioAnalysis != nil)
    {
        // Delete all previous data for the sequence
        [[CoreDataManager sharedManager].currentSequence removeCommands:[CoreDataManager sharedManager].currentSequence.commands];
        
        // Variables
        NSArray *sections = [[[[[CoreDataManager sharedManager].managedObjectContext ofType:@"EchoNestSection"] where:@"echoNestAudioAnalysis == %@", audioAnalysis] orderBy:@"start"] toArray];
        NSArray *allSegments = [[[[[CoreDataManager sharedManager].managedObjectContext ofType:@"EchoNestSegment"] where:@"echoNestAudioAnalysis == %@", audioAnalysis] orderBy:@"start"] toArray];
        
        // Get the ControlBoxes
        NSArray *controlBoxes = [[[[[CoreDataManager sharedManager].managedObjectContext ofType:@"ControlBox"] where:@"sequence CONTAINS %@", [CoreDataManager sharedManager].currentSequence] orderBy:@"idNumber"] toArray];
        
        // Find the min and max loudness of the audioAnalysis
        float minLoudness = 10000.0;
        float maxLoudness = -10000.0;
        for(EchoNestSegment *segment in allSegments)
        {
            float segmentLoudness = [segment.loudnessMax floatValue];
            
            if(segmentLoudness > maxLoudness)
            {
                maxLoudness = segmentLoudness;
            }
            if(segmentLoudness < minLoudness && segmentLoudness >= -51.000)
            {
                minLoudness = segmentLoudness;
            }
        }
        float loudnessRange = maxLoudness - minLoudness;
        
        // Main loop (looping through the sections, then segments, then beats and tatums)
        for(EchoNestSection *section in sections)
        {
            NSMutableArray *beatControlBoxes = [NSMutableArray new];
            NSMutableArray *tatumControlBoxes = [NSMutableArray new];
            NSMutableArray *segmentControlBoxes = [NSMutableArray new];
            NSMutableArray *controlBoxesAvailable = [NSMutableArray arrayWithArray:controlBoxes];
            int numberOfBoxesToUseForBeat = (controlBoxesAvailable.count > 3 ? 1 : 0); // just 1 for now
            int numberOfBoxesToUseForTatum = (controlBoxesAvailable.count > 3 ? 1 : 0); // just 1 for now
            int numberOfBoxesToUseForSegment = 0;
            int numberOfAvailableChannelsForBeats = 0;
            int numberOfAvailableChannelsForTatums = 0;
            int numberOfAvailableChannelsForSegments = 0;
            
            // Pick controlBoxes for the beat
            for(int i = 0; i < numberOfBoxesToUseForBeat; i ++)
            {
                // Pick a random control box index
                int controlBoxIndexToUse = arc4random() % controlBoxesAvailable.count;
                [beatControlBoxes addObject:controlBoxesAvailable[controlBoxIndexToUse]];
                [controlBoxesAvailable removeObjectAtIndex:controlBoxIndexToUse];
            }
            // Get the numberOfAvailableChannels for beatControlBoxes
            for(int i = 0; i < beatControlBoxes.count; i ++)
            {
                numberOfAvailableChannelsForBeats += (int)((ControlBox *)beatControlBoxes[i]).channels.count;
            }
            
            // Pick controlBoxes for the tatum
            for(int i = 0; i < numberOfBoxesToUseForBeat; i ++)
            {
                // Pick a random control box index
                int controlBoxIndexToUse = arc4random() % controlBoxesAvailable.count;
                [tatumControlBoxes addObject:controlBoxesAvailable[controlBoxIndexToUse]];
                [controlBoxesAvailable removeObjectAtIndex:controlBoxIndexToUse];
            }
            // Get the numberOfAvailableChannels for beatControlBoxes
            for(int i = 0; i < tatumControlBoxes.count; i ++)
            {
                numberOfAvailableChannelsForTatums += (int)((ControlBox *)tatumControlBoxes[i]).channels.count;
            }
            
            // Section info
            float averageLoudnessForSection = [section.loudness floatValue];
            
            // Determine how many controlBoxes to use
            numberOfBoxesToUseForSegment = (int)((averageLoudnessForSection - minLoudness) / loudnessRange * intensity * controlBoxesAvailable.count + 0.5);
            if(numberOfBoxesToUseForSegment == 0)
            {
                numberOfBoxesToUseForSegment = 1;
            }
            // If we are using 2 or fewer boxes, assign all boxes to segment data
            if(numberOfBoxesToUseForBeat == 0 && numberOfBoxesToUseForTatum == 0)
            {
                numberOfBoxesToUseForSegment = (int)controlBoxesAvailable.count;
            }
            
            // Pick controlBoxes for the segments
            for(int i = 0; i < numberOfBoxesToUseForSegment; i ++)
            {
                // Pick a random control box index
                int controlBoxIndexToUse = arc4random() % controlBoxesAvailable.count;
                [segmentControlBoxes addObject:controlBoxesAvailable[controlBoxIndexToUse]];
                [controlBoxesAvailable removeObjectAtIndex:controlBoxIndexToUse];
            }
            // Get the numberOfAvailableChannels for segmentControlBoxes
            for(int i = 0; i < segmentControlBoxes.count; i ++)
            {
                numberOfAvailableChannelsForSegments += (int)((ControlBox *)segmentControlBoxes[i]).channels.count;
            }
            
            NSArray *beats = [[[[[CoreDataManager sharedManager].managedObjectContext ofType:@"EchoNestBeat"] where:@"echoNestAudioAnalysis == %@ && start >= %f AND start + duration <= %f", audioAnalysis, [section.start floatValue], [section.start floatValue] + [section.duration floatValue]] orderBy:@"start"] toArray];
            NSArray *tatums = [[[[[CoreDataManager sharedManager].managedObjectContext ofType:@"EchoNestTatum"] where:@"echoNestAudioAnalysis == %@ && start >= %f AND start + duration <= %f", audioAnalysis, [section.start floatValue], [section.start floatValue] + [section.duration floatValue]] orderBy:@"start"] toArray];
            NSArray *segments = [[[[[CoreDataManager sharedManager].managedObjectContext ofType:@"EchoNestSegment"] where:@"echoNestAudioAnalysis == %@ && start >= %f AND start + duration <= %f", audioAnalysis, [section.start floatValue], [section.start floatValue] + [section.duration floatValue]] orderBy:@"start"] toArray];
            
            ///////// Start of code for segment commands /////////////
            // Make an array so we can store which channel belongs to which pitch
            NSMutableArray *pitchChannelArrays = [NSMutableArray new];
            for(int i = 0; i < pitchesToUse; i ++)
            {
                // Add an array for each pitch to store the channels in
                [pitchChannelArrays addObject:[NSMutableArray new]];
            }
            
            // Loop through each controlBox and assign each of it's channel to a pitch
            for(ControlBox *controlBox in segmentControlBoxes)
            {
                float pitchesPerChannel = (pitchesToUse * intensity) / (float)(controlBox.channels.count);
                float currentPitchIndex = 0;
                for(Channel *channel in controlBox.channels)
                {
                    [((NSMutableArray *)pitchChannelArrays[(int)currentPitchIndex]) addObject:channel];
                    
                    currentPitchIndex += pitchesPerChannel;
                }
            }
            
            // Seed initial data
            NSArray *previousSegmentPitches;
            NSArray *currentSegmentPitches;
            NSArray *nextSegmentPitches;
            NSArray *nextNextSegmentPitches;
            EchoNestSegment *previousSegment;
            EchoNestSegment *nextSegment;
            EchoNestSegment *nextNextSegment;
            if(segments.count > 1)
            {
                nextSegmentPitches = [[[[[CoreDataManager sharedManager].managedObjectContext ofType:@"EchoNestPitch"] where:@"segment == %@", segments[0]] orderBy:@"index"] toArray];
                nextSegment = segments[0];
            }
            if(segments.count > 2)
            {
                nextSegmentPitches = [[[[[CoreDataManager sharedManager].managedObjectContext ofType:@"EchoNestPitch"] where:@"segment == %@", segments[1]] orderBy:@"index"] toArray];
                nextNextSegment = segments[1];
            }
            // Now loop through each segment
            for(int segmentIndex = 0; segmentIndex < segments.count; segmentIndex ++)
            {
                // Get the current segment details
                EchoNestSegment *segment = segments[segmentIndex];
                float segmentLoudness = [segment.loudnessStart floatValue];
                float segmentStartTime = [segment.start floatValue];
                float segmentEndTime = segmentStartTime + [segment.duration floatValue];
                
                // Get the next segments and pitches
                currentSegmentPitches = nextSegmentPitches;
                nextSegmentPitches = nextNextSegmentPitches;
                nextSegment = nextNextSegment;
                if(segmentIndex < segments.count - 2)
                {
                    nextSegmentPitches = [[[[[CoreDataManager sharedManager].managedObjectContext ofType:@"EchoNestPitch"] where:@"segment == %@", segments[segmentIndex + 2]] orderBy:@"index"] toArray];
                    nextNextSegment = segments[segmentIndex + 2];
                }
                
                // Create the commands for the segments
                if(previousSegmentPitches)
                {
                    int pitchIndex = 0;
                    for(EchoNestPitch *pitch in currentSegmentPitches)
                    {
                        float previousPitchValue = [((EchoNestPitch *)previousSegmentPitches[pitchIndex]).pitch floatValue];
                        float currentPitchValue = [pitch.pitch floatValue];
                        float nextPitchValue = [((EchoNestPitch *)nextSegmentPitches[pitchIndex]).pitch floatValue];
                        float nextNextPitchValue = [((EchoNestPitch *)nextNextSegmentPitches[pitchIndex]).pitch floatValue];
                        
                        // Create a new command (volume increased, therefore it has to be a new 'ding')
                        if(currentPitchValue >= previousPitchValue + 0.1 && currentPitchValue >= 0.3) // && currentPitch > 0.5???
                        {
                            // Get the channels for this pitch
                            NSArray *channelsForCurrentPitch = (NSArray *)pitchChannelArrays[pitchIndex];
                            
                            for(Channel *channel in channelsForCurrentPitch)
                            {
                                // Find the start and end tatum for the new command being created
                                SequenceTatum *startTatum = [self sequenceTatumForCurrentSequenceAtTime:[segment.start floatValue]];
                                SequenceTatum *endTatum;
                                
                                // Note lasts more than this segment
                                if(nextPitchValue <= currentPitchValue)
                                {
                                    // Note lasts at least 2 segments
                                    if((nextPitchValue <= currentPitchValue && nextPitchValue >= 0.3 && [nextSegment.confidence floatValue] >= 0.3) || (currentPitchValue - nextPitchValue <= 0.1 && currentPitchValue - nextPitchValue >= 0.0 && [nextSegment.confidence floatValue] < 0.3))
                                    {
                                        // Note lasts three segments
                                        if((nextNextPitchValue <= nextPitchValue && nextNextPitchValue >= 0.3 && [nextNextSegment.confidence floatValue] >= 0.3) || (nextPitchValue - nextNextPitchValue <= 0.1 && nextPitchValue - nextNextPitchValue >= 0.0 && [nextNextSegment.confidence floatValue] < 0.3))
                                        {
                                            endTatum = [self sequenceTatumForCurrentSequenceAtTime:[nextNextSegment.start floatValue] + [nextNextSegment.duration floatValue]];
                                        }
                                        // Note lasts two segments but the third segment is a new note
                                        else if(nextNextPitchValue >= nextPitchValue + 0.1 && nextPitchValue >= 0.2)
                                        {
                                            endTatum = [self sequenceTatumForCurrentSequenceAtTime:[nextSegment.start floatValue] + [nextSegment.duration floatValue]];
                                        }
                                        // Note lasts two segments and the third segment is not a note
                                        else
                                        {
                                            endTatum = [self sequenceTatumForCurrentSequenceAtTime:[nextSegment.start floatValue] + [nextSegment.duration floatValue]];
                                        }
                                    }
                                    // Note just lasts one segment
                                    else
                                    {
                                        endTatum = [self sequenceTatumForCurrentSequenceAtTime:[segment.start floatValue] + [segment.duration floatValue]];
                                    }
                                }
                                else
                                {
                                    endTatum = [self sequenceTatumForCurrentSequenceAtTime:[segment.start floatValue] + [segment.duration floatValue]];
                                }
                                
                                // Create the new command
                                [[CoreDataManager sharedManager] addCommandFadeWithStartTatum:startTatum endTatum:endTatum startBrightness:1.0 endBrightness:0.0 channel:channel];
                            }
                        }
                        
                        pitchIndex ++;
                    }
                    
                    ///////////////// Tatum commands //////////////////////
                    // Now create the commands for the tatums within the doman of the current segment
                    for(EchoNestTatum *echoTatum in tatums)
                    {
                        float tatumStartTime = [echoTatum.start floatValue];
                        
                        // This tatum should have commands added
                        if(tatumStartTime >= segmentStartTime && tatumStartTime < segmentEndTime && [echoTatum.confidence floatValue] >= 0.10)
                        {
                            int numberOfChannelsToUse = ((segmentLoudness - minLoudness) / loudnessRange) * intensity * numberOfAvailableChannelsForTatums / 2;
                            
                            // Limit the numberOfChannelsToUse
                            if(numberOfChannelsToUse > numberOfAvailableChannelsForTatums)
                            {
                                numberOfChannelsToUse = numberOfAvailableChannelsForTatums;
                            }
                            else if(numberOfChannelsToUse < 0)
                            {
                                numberOfChannelsToUse = 0;
                            }
                            else if(numberOfChannelsToUse == 0)
                            {
                                numberOfChannelsToUse ++;
                            }
                            
                            NSMutableArray *echoTatumChannels = [NSMutableArray new];
                            for(ControlBox *tatumControlBox in tatumControlBoxes)
                            {
                                [echoTatumChannels addObjectsFromArray:[tatumControlBox.channels allObjects]];
                            }
                            
                            // Create the commands for this tatum
                            for(int i = 0; i < numberOfChannelsToUse; i ++)
                            {
                                // Randomly pick a channel
                                int tatumChannelIndexToUse = arc4random() % echoTatumChannels.count;
                                
                                // Create the new command
                                SequenceTatum *startTatum = [self sequenceTatumForCurrentSequenceAtTime:[echoTatum.start floatValue]];
                                SequenceTatum *endTatum = [self sequenceTatumForCurrentSequenceAtTime:[echoTatum.start floatValue] + [echoTatum.duration floatValue]];
                                [[CoreDataManager sharedManager] addCommandFadeWithStartTatum:startTatum endTatum:endTatum startBrightness:1.0 endBrightness:0.0 channel:echoTatumChannels[tatumChannelIndexToUse]];
                                
                                // Remove this channel/controlBox from the availble channels to use
                                [echoTatumChannels removeObjectAtIndex:tatumChannelIndexToUse];
                            }
                        }
                        // We are done looking if we get past the endTime of the current segment since the data is sorted
                        else if(tatumStartTime >= segmentEndTime)
                        {
                            break;
                        }
                    }
                    
                    //////////////// Beat commands //////////////////////
                    // Now create the commands for the beats within the doman of the current segment
                    for(EchoNestBeat *echoBeat in beats)
                    {
                        float beatStartTime = [echoBeat.start floatValue];
                        
                        // This tatum should have commands added
                        if(beatStartTime >= segmentStartTime && beatStartTime < segmentEndTime && [echoBeat.confidence floatValue] >= 0.10)
                        {
                            int numberOfChannelsToUse = ((segmentLoudness - minLoudness) / loudnessRange) * intensity * numberOfAvailableChannelsForTatums / 2;
                            
                            // Limit the numberOfChannelsToUse
                            if(numberOfChannelsToUse > numberOfAvailableChannelsForTatums)
                            {
                                numberOfChannelsToUse = numberOfAvailableChannelsForTatums;
                            }
                            else if(numberOfChannelsToUse < 0)
                            {
                                numberOfChannelsToUse = 0;
                            }
                            else if(numberOfChannelsToUse == 0)
                            {
                                numberOfChannelsToUse ++;
                            }
                            
                            NSMutableArray *echoBeatChannels = [NSMutableArray new];
                            for(ControlBox *beatControlBox in beatControlBoxes)
                            {
                                [echoBeatChannels addObjectsFromArray:[beatControlBox.channels allObjects]];
                            }
                            
                            // Create the commands for this tatum
                            for(int i = 0; i < numberOfChannelsToUse; i ++)
                            {
                                // Randomly pick a channel
                                int beatChannelIndexToUse = arc4random() % echoBeatChannels.count;
                                
                                // Create the new command
                                SequenceTatum *startTatum = [self sequenceTatumForCurrentSequenceAtTime:[echoBeat.start floatValue]];
                                SequenceTatum *endTatum = [self sequenceTatumForCurrentSequenceAtTime:[echoBeat.start floatValue] + [echoBeat.duration floatValue]];
                                [[CoreDataManager sharedManager] addCommandFadeWithStartTatum:startTatum endTatum:endTatum startBrightness:1.0 endBrightness:0.0 channel:echoBeatChannels[beatChannelIndexToUse]];
                                
                                // Remove this channel/controlBox from the availble channels to use
                                [echoBeatChannels removeObjectAtIndex:beatChannelIndexToUse];
                            }
                        }
                        // We are done looking if we get past the endTime of the current segment since the data is sorted
                        else if(beatStartTime >= segmentEndTime)
                        {
                            break;
                        }
                    }
                }
                
                previousSegmentPitches = currentSegmentPitches;
                previousSegment = segment;
            }
        }
        
        [[CoreDataManager sharedManager] saveContext];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"CurrentSequenceChange" object:nil];
    }
}

#pragma mark - EchoNest

- (void)fetchEchoNestAnalysisForCurrentSequenceAudio
{
    Audio *audio = [CoreDataManager sharedManager].currentSequence.audio;
    
    // Search EchoNest for analysis
    if(audio.audioFilePath.length > 1)
    {
        // See if the analysis has already been done
        NSDictionary *parameters = @{@"md5" : [ENAPI calculateMD5DigestFromData:audio.audioFile], @"bucket" : @"audio_summary"};
        [ENAPIRequest GETWithEndpoint:@"track/profile" andParameters:parameters andCompletionBlock:
         ^(ENAPIRequest *request)
         {
             // Doesn't exist yet, needs uploading
             if(![request.response[@"response"][@"track"][@"status"] isEqualToString:@"complete"])
             {
                 // Upload the track
                 NSDictionary *parameters = @{@"track" : audio.audioFile, @"filetype" : [audio.audioFilePath pathExtension]};
                 [ENAPIRequest POSTWithEndpoint:@"track/upload" andParameters:parameters andCompletionBlock:
                  ^(ENAPIRequest *request)
                  {
                      //NSLog(@"upload request response:%@", request.response);
                      [self prepareForAudioAnalysisDownloadWithENAPIRequest:request andAudio:audio];
                  }];
             }
             // Already exists, skip to downloading analysis
             else
             {
                 [self prepareForAudioAnalysisDownloadWithENAPIRequest:request andAudio:audio];
             }
         }];
    }
}

- (void)echoNestUploadUpdate:(NSNotification *)notification
{
    int bytesWritten = [notification.userInfo[@"totalBytesWritten"] intValue];
    int totalBytesToWrite = [notification.userInfo[@"totalBytesExpectedToWrite"] intValue];
    self.currentAudio.echoNestUploadProgress = @(0.8 * (float)bytesWritten / totalBytesToWrite);
    
    // Tell the label to update
    [[NSNotificationCenter defaultCenter] postNotificationName:@"AudioAnalysisProgress" object:nil];
}

- (void)prepareForAudioAnalysisDownloadWithENAPIRequest:(ENAPIRequest *)request andAudio:(Audio *)audio
{
    // Delete any old data
    if(audio.echoNestAudioAnalysis)
    {
        [[CoreDataManager sharedManager].managedObjectContext deleteObject:audio.echoNestAudioAnalysis];
    }
    
    EchoNestAudioAnalysis *echonestAudioAnalysis = [NSEntityDescription insertNewObjectForEntityForName:@"EchoNestAudioAnalysis" inManagedObjectContext:[CoreDataManager sharedManager].managedObjectContext];
    echonestAudioAnalysis.audio = audio;
    echonestAudioAnalysis.idString = request.response[@"response"][@"track"][@"id"];
    audio.title = request.response[@"response"][@"track"][@"title"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"AudioNameChange" object:nil];
    audio.echoNestUploadProgress = @(0.85);
    // Tell the label to update
    [[NSNotificationCenter defaultCenter] postNotificationName:@"AudioAnalysisProgress" object:nil];
    
    [[CoreDataManager sharedManager] saveContext];
    
    // Download the audioanalysis
    [self checkForAudioAnalysisCompletionWithAudio:audio];
}

- (void)checkForAudioAnalysisCompletionWithAudio:(Audio *)audio
{
    if([audio.echoNestUploadProgress floatValue] < 0.95)
    {
        audio.echoNestUploadProgress = @([audio.echoNestUploadProgress floatValue] + 0.01);
        // Tell the label to update
        [[NSNotificationCenter defaultCenter] postNotificationName:@"AudioAnalysisProgress" object:nil];
    }
    
    NSDictionary *parameters = @{@"id" : audio.echoNestAudioAnalysis.idString, @"bucket" : @"audio_summary"};
    [ENAPIRequest GETWithEndpoint:@"track/profile" andParameters:parameters andCompletionBlock:
     ^(ENAPIRequest *request)
     {
         //NSLog(@"summary request response:%@", request.response);
         
         // Analysis is ready for download
         if([request.response[@"response"][@"track"][@"status"] isEqualToString:@"complete"])
         {
             audio.echoNestUploadProgress = @(0.95);
             // Tell the label to update
             [[NSNotificationCenter defaultCenter] postNotificationName:@"AudioAnalysisProgress" object:nil];
             
             // Store the analysisSummary data
             audio.echoNestAudioAnalysis.artistID = request.response[@"response"][@"track"][@"artist_id"];
             audio.echoNestAudioAnalysis.idString = request.response[@"response"][@"track"][@"id"];
             audio.echoNestAudioAnalysis.md5 = request.response[@"response"][@"track"][@"md5"];
             audio.echoNestAudioAnalysis.songID = request.response[@"response"][@"track"][@"song_id"];
             audio.echoNestAudioAnalysis.status = request.response[@"response"][@"track"][@"status"];
             audio.echoNestAudioAnalysis.acousticness = request.response[@"response"][@"track"][@"audio_summary"][@"acousticness"];
             audio.echoNestAudioAnalysis.analysisURL = request.response[@"response"][@"track"][@"audio_summary"][@"analysis_url"];
             audio.echoNestAudioAnalysis.danceability = request.response[@"response"][@"track"][@"audio_summary"][@"danceability"];
             audio.echoNestAudioAnalysis.energy = request.response[@"response"][@"track"][@"audio_summary"][@"energy"];
             audio.echoNestAudioAnalysis.instrumentalness = request.response[@"response"][@"track"][@"audio_summary"][@"instrumentalness"];
             audio.echoNestAudioAnalysis.liveness = request.response[@"response"][@"track"][@"audio_summary"][@"liveness"];
             audio.echoNestAudioAnalysis.loudness = request.response[@"response"][@"track"][@"audio_summary"][@"loudness"];
             audio.echoNestAudioAnalysis.speechiness = request.response[@"response"][@"track"][@"audio_summary"][@"speechiness"];
             audio.echoNestAudioAnalysis.tempo = request.response[@"response"][@"track"][@"audio_summary"][@"tempo"];
             audio.echoNestAudioAnalysis.valence = request.response[@"response"][@"track"][@"audio_summary"][@"valence"];
             
             // Download the full analysis
             [ENAPIRequest downloadAnalysisURL:audio.echoNestAudioAnalysis.analysisURL withCompletionBlock:
              ^(ENAPIRequest *request)
              {
                  //NSLog(@"analysis:%@", request.response);
                  audio.echoNestAudioAnalysis.album = request.response[@"meta"][@"album"];
                  audio.echoNestAudioAnalysis.analysisTime = request.response[@"meta"][@"analysis_time"];
                  audio.echoNestAudioAnalysis.analyzerVersion = request.response[@"meta"][@"analyzer_version"];
                  audio.echoNestAudioAnalysis.artist = request.response[@"meta"][@"artist"];
                  audio.echoNestAudioAnalysis.bitrate = request.response[@"meta"][@"bitrate"];
                  audio.echoNestAudioAnalysis.detailedStatus = request.response[@"meta"][@"detailed_status"];
                  audio.echoNestAudioAnalysis.fileName = request.response[@"meta"][@"filename"];
                  audio.echoNestAudioAnalysis.genre = request.response[@"meta"][@"genre"];
                  audio.echoNestAudioAnalysis.platform = request.response[@"meta"][@"platform"];
                  audio.echoNestAudioAnalysis.sampleRate = request.response[@"meta"][@"sample_rate"];
                  audio.echoNestAudioAnalysis.seconds = request.response[@"meta"][@"seconds"];
                  audio.echoNestAudioAnalysis.statusCode = request.response[@"meta"][@"status_code"];
                  audio.echoNestAudioAnalysis.timestamp = request.response[@"meta"][@"timestamp"];
                  audio.echoNestAudioAnalysis.title = request.response[@"meta"][@"title"];
                  [[NSNotificationCenter defaultCenter] postNotificationName:@"AudioNameChange" object:nil];
                  
                  audio.echoNestAudioAnalysis.analysisChannels = request.response[@"track"][@"analysis_channels"];
                  audio.echoNestAudioAnalysis.analysisSampleRate = request.response[@"track"][@"analysis_sample_rate"];
                  audio.echoNestAudioAnalysis.codeVersion = request.response[@"track"][@"code_version"];
                  audio.echoNestAudioAnalysis.codeString = request.response[@"track"][@"codestring"];
                  audio.echoNestAudioAnalysis.decoder = request.response[@"track"][@"decoder"];
                  audio.echoNestAudioAnalysis.decoderVersion = request.response[@"track"][@"decoder_version"];
                  audio.echoNestAudioAnalysis.duration = request.response[@"track"][@"duration"];
                  audio.echoNestAudioAnalysis.echoPrintVersion = request.response[@"track"][@"echoprint_version"];
                  audio.echoNestAudioAnalysis.echoPrintString = request.response[@"track"][@"echoprintstring"];
                  audio.echoNestAudioAnalysis.endOfFadeIn = request.response[@"track"][@"end_of_fade_in"];
                  audio.echoNestAudioAnalysis.key = request.response[@"track"][@"key"];
                  audio.echoNestAudioAnalysis.keyConfidence = request.response[@"track"][@"key_confidence"];
                  audio.echoNestAudioAnalysis.loudness = request.response[@"track"][@"loudness"];
                  audio.echoNestAudioAnalysis.mode = request.response[@"track"][@"mode"];
                  audio.echoNestAudioAnalysis.modeConfidence = request.response[@"track"][@"mode_confidence"];
                  audio.echoNestAudioAnalysis.numberOfSamples = request.response[@"track"][@"num_samples"];
                  audio.echoNestAudioAnalysis.offsetSeconds = request.response[@"track"][@"offset_seconds"];
                  audio.echoNestAudioAnalysis.rhythmVersion = request.response[@"track"][@"rhythm_version"];
                  audio.echoNestAudioAnalysis.rhythmString = request.response[@"track"][@"rhythmstring"];
                  audio.echoNestAudioAnalysis.sampleMD5 = request.response[@"track"][@"sample_md5"];
                  audio.echoNestAudioAnalysis.startOfFadeOut = request.response[@"track"][@"start_of_fade_out"];
                  audio.echoNestAudioAnalysis.synchVersion = request.response[@"track"][@"synch_version"];
                  audio.echoNestAudioAnalysis.synchString = request.response[@"track"][@"synchstring"];
                  audio.echoNestAudioAnalysis.tempo = request.response[@"track"][@"tempo"];
                  audio.echoNestAudioAnalysis.tempoConfidence = request.response[@"track"][@"tempo_confidence"];
                  audio.echoNestAudioAnalysis.timeSignature = request.response[@"track"][@"time_signature"];
                  audio.echoNestAudioAnalysis.timeSignatureConfidence = request.response[@"track"][@"time_signature_confidence"];
                  audio.echoNestAudioAnalysis.windowSeconds = request.response[@"track"][@"window_seconds"];
                  
                  // Store all the sections
                  NSArray *sections = request.response[@"sections"];
                  for(int i = 0; i < sections.count; i ++)
                  {
                      EchoNestSection *section = [NSEntityDescription insertNewObjectForEntityForName:@"EchoNestSection" inManagedObjectContext:[CoreDataManager sharedManager].managedObjectContext];
                      NSDictionary *dictionarySection = sections[i];
                      section.confidence = dictionarySection[@"confidence"];
                      section.duration = dictionarySection[@"duration"];
                      section.key = dictionarySection[@"key"];
                      section.keyConfidence = dictionarySection[@"key_confidence"];
                      section.loudness = dictionarySection[@"loudness"];
                      section.mode = dictionarySection[@"mode"];
                      section.modeConfidence = dictionarySection[@"mode_confidence"];
                      section.start = dictionarySection[@"start"];
                      section.tempo = dictionarySection[@"tempo"];
                      section.tempoConfidence = dictionarySection[@"tempo_confidence"];
                      section.timeSignature = dictionarySection[@"time_signature"];
                      section.timeSignatureConfidence = dictionarySection[@"time_signature_confidence"];
                      [audio.echoNestAudioAnalysis addSectionsObject:section];
                  }
                  // Store all the bars
                  NSArray *bars = request.response[@"bars"];
                  for(int i = 0; i < bars.count; i ++)
                  {
                      EchoNestBar *bar = [NSEntityDescription insertNewObjectForEntityForName:@"EchoNestBar" inManagedObjectContext:[CoreDataManager sharedManager].managedObjectContext];
                      NSDictionary *dictionaryBar = bars[i];
                      bar.confidence = dictionaryBar[@"confidence"];
                      bar.duration = dictionaryBar[@"duration"];
                      bar.start = dictionaryBar[@"start"];
                      [audio.echoNestAudioAnalysis addBarsObject:bar];
                  }
                  // Store all the beats
                  NSArray *beats = request.response[@"beats"];
                  for(int i = 0; i < beats.count; i ++)
                  {
                      EchoNestBeat *beat = [NSEntityDescription insertNewObjectForEntityForName:@"EchoNestBeat" inManagedObjectContext:[CoreDataManager sharedManager].managedObjectContext];
                      NSDictionary *dictionaryBeat = beats[i];
                      beat.confidence = dictionaryBeat[@"confidence"];
                      beat.duration = dictionaryBeat[@"duration"];
                      beat.start = dictionaryBeat[@"start"];
                      [audio.echoNestAudioAnalysis addBeatsObject:beat];
                  }
                  // Store all the tatums
                  NSArray *tatums = request.response[@"tatums"];
                  for(int i = 0; i < tatums.count; i ++)
                  {
                      EchoNestTatum *tatum = [NSEntityDescription insertNewObjectForEntityForName:@"EchoNestTatum" inManagedObjectContext:[CoreDataManager sharedManager].managedObjectContext];
                      NSDictionary *dictionaryTatum = tatums[i];
                      tatum.confidence = dictionaryTatum[@"confidence"];
                      tatum.duration = dictionaryTatum[@"duration"];
                      tatum.start = dictionaryTatum[@"start"];
                      [audio.echoNestAudioAnalysis addTatumsObject:tatum];
                  }
                  // Store all the segments
                  NSArray *segments = request.response[@"segments"];
                  for(int i = 0; i < segments.count; i ++)
                  {
                      EchoNestSegment *segment = [NSEntityDescription insertNewObjectForEntityForName:@"EchoNestSegment" inManagedObjectContext:[CoreDataManager sharedManager].managedObjectContext];
                      NSDictionary *dictionarySegment = segments[i];
                      segment.confidence = dictionarySegment[@"confidence"];
                      segment.duration = dictionarySegment[@"duration"];
                      segment.loudnessMax = dictionarySegment[@"loudness_max"];
                      segment.loudnessMaxTime = dictionarySegment[@"loudness_max_time"];
                      segment.loudnessStart = dictionarySegment[@"loudness_start"];
                      NSArray *pitches = dictionarySegment[@"pitches"];
                      for(int i2 = 0; i2 < pitches.count; i2 ++)
                      {
                          EchoNestPitch *pitch = [NSEntityDescription insertNewObjectForEntityForName:@"EchoNestPitch" inManagedObjectContext:[CoreDataManager sharedManager].managedObjectContext];
                          pitch.pitch = pitches[i2];
                          pitch.index = @(i2);
                          [segment addPitchesObject:pitch];
                      }
                      segment.start = dictionarySegment[@"start"];
                      NSArray *timbres = dictionarySegment[@"timbre"];
                      for(int i2 = 0; i2 < timbres.count; i2 ++)
                      {
                          EchoNestTimbre *timbre = [NSEntityDescription insertNewObjectForEntityForName:@"EchoNestTimbre" inManagedObjectContext:[CoreDataManager sharedManager].managedObjectContext];
                          timbre.timbre = timbres[i2];
                          timbre.index = @(i2);
                          [segment addTimbresObject:timbre];
                      }
                      
                      [audio.echoNestAudioAnalysis addSegmentsObject:segment];
                  }
                  
                  //audio.endOffset = audio.echoNestAudioAnalysis.startOfFadeOut;
                  //audio.startOffset = audio.echoNestAudioAnalysis.endOfFadeIn;
                  audio.sequence.endTime = audio.echoNestAudioAnalysis.duration;
                  audio.sequence.title = audio.echoNestAudioAnalysis.title;
                  
                  // Initialize the tatums if there aren't many commands yet
                  if(audio.sequence.commands.count < 5)
                  {
                      [[CoreDataManager sharedManager] updateSequenceTatumsForNewAudioForSequence:audio.sequence];
                  }
                  
                  audio.echoNestUploadProgress = @(1.0);
                  // Tell the label to update
                  [[NSNotificationCenter defaultCenter] postNotificationName:@"AudioAnalysisProgress" object:nil];
                  [[CoreDataManager sharedManager] saveContext];
                  
                  [[NSNotificationCenter defaultCenter] postNotificationName:@"CurrentSequenceChange" object:nil];
              }];
         }
         // Analysis isn't ready, keep polling
         else
         {
             [self performSelector:@selector(checkForAudioAnalysisCompletionWithAudio:) withObject:audio afterDelay:1.0];
         }
     }];
}

@end
