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
#import "EchoNestAudioAnalysis.h"
#import "EchoNestSection.h"
#import "EchoNestBar.h"
#import "EchoNestBeat.h"
#import "EchoNestTatum.h"
#import "EchoNestSegment.h"
#import "EchoNestPitch.h"

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
    if(self.currentTime > self.lastChannelUpdateTime + 0.06)
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

/*- (void)echoNestAutoGenForCurrentSeguence
{
    float intensity = 1.0;
    const int pitchesToUse = 12;
    const float epsilon = 0.01;
    
    // Delete all previous data for the sequence
    [[CoreDataManager sharedManager].currentSequence removeCommands:[CoreDataManager sharedManager].currentSequence.commands];
    
    // Get the first audioAnalysis for this sequence (autogen does not yet support multiple audioAnalysi)
    EchoNestAudioAnalysis *audioAnalysis = [CoreDataManager sharedManager].currentSequence.audio.echoNestAudioAnalysis;
    
    // If the sequence has an analysis, autogen commands
    if(audioAnalysis != nil)
    {
        // Variables
        NSSet *beats = audioAnalysis.beats;
        NSSet *tatums = audioAnalysis.tatums;
        NSSet *segments = audioAnalysis.segments;
        NSSet *sections = audioAnalysis.sections;
        
        // Get the ControlBoxes
        NSArray *controlBoxes = [[[[[CoreDataManager sharedManager].managedObjectContext ofType:@"ControlBox"] where:@"sequence CONTAINS %@", [CoreDataManager sharedManager].currentSequence] orderBy:@"idNumber"] toArray];
        
        // Find the min and max loudness of the audioAnalysis
        float minLoudness = 10000.0;
        float maxLoudness = -10000.0;
        for(EchoNestSegment *segment in segments)
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
        NSLog(@"loudness Min:%f max:%f range:%f", minLoudness, maxLoudness, loudnessRange);
        
        // Main loop (looping through the sections, then segments, then beats and tatums)
        for(EchoNestSection *section in sections)
        {
            NSMutableArray *beatControlBoxes = [NSMutableArray new];
            NSMutableArray *tatumControlBoxes = [NSMutableArray new];
            NSMutableArray *segmentControlBoxes = [NSMutableArray new];
            NSMutableArray *controlBoxesAvailable = [controlBoxes copy];
            int numberOfBoxesToUseForBeat = (controlBoxesAvailable.count > 3 ? 1 : 0); // just 1 for now
            int numberOfBoxesToUseForTatum = (controlBoxesAvailable.count > 3 ? 1 : 0); // just 1 for now
            int numberOfBoxesToUseForSegment;
            int numberOfAvailableChannelsForBeats = 0;
            int numberOfAvailableChannelsForTatums = 0;
            int numberOfAvailableChannelsForSegments = 0;
            
            // Pick controlBoxes for the beat
            for(int i = 0; i < numberOfBoxesToUseForBeat; i ++)
            {
                // Pick a random control box index
                int controlBoxIndexToUse = arc4random() % controlBoxesAvailable.count;
                [beatControlBoxes addObject:controlBoxesAvailable[controlBoxIndexToUse]];
                [controlBoxesAvailable removeObject:controlBoxesAvailable[controlBoxIndexToUse]];
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
                [controlBoxesAvailable removeObject:controlBoxesAvailable[controlBoxIndexToUse]];
            }
            // Get the numberOfAvailableChannels for beatControlBoxes
            for(int i = 0; i < tatumControlBoxes.count; i ++)
            {
                numberOfAvailableChannelsForTatums += (int)((ControlBox *)tatumControlBoxes[i]).channels.count;
            }
            
            // Section info
            float averageLoudnessForSection = [section.loudness floatValue];
            float numberOfSegmentsUsedForAverageLoudness = 0;
            float sectionStartTime = [section.start floatValue];
            float sectionEndTime = sectionStartTime + [section.duration floatValue];
            
            // Determine how many controlBoxes to use
            numberOfBoxesToUseForSegment = (int)((averageLoudnessForSection - minLoudness) / loudnessRange * intensity * controlBoxesAvailable.count + 0.5);
            if(numberOfBoxesToUseForSegment == 0)
            {
                numberOfBoxesToUseForSegment = 1;
            }
            // If we are using 2 or fewer boxes, assign all boxes to segment data
            if(numberOfBoxesToUseForBeat == 0 && numberOfBoxesToUseForTatum == 0)
            {
                numberOfBoxesToUseForSegment = controlBoxesAvailable.count;
            }
            
            // Pick controlBoxes for the segments
            for(int i = 0; i < numberOfBoxesToUseForSegment; i ++)
            {
                // Pick a random control box index
                int controlBoxIndexToUse = arc4random() % controlBoxesAvailable.count;
                [segmentControlBoxes addObject:controlBoxesAvailable[controlBoxIndexToUse]];
                [controlBoxesAvailable removeObject:controlBoxesAvailable[controlBoxIndexToUse]];
            }
            // Get the numberOfAvailableChannels for segmentControlBoxes
            for(int i = 0; i < segmentControlBoxes.count; i ++)
            {
                numberOfAvailableChannelsForSegments += (int)((ControlBox *)segmentControlBoxes[i]).channels.count;
            }
            
            // Make an array so we can store which channel belongs to which pitch
            NSMutableArray *pitchChannelArrays = [NSMutableArray new];
            for(int i = 0; i < pitchesToUse; i ++)
            {
                // Add an array for each pitch to store the channels in
                [pitchChannelArrays addObject:[NSMutableArray new]];
            }
            
            // Loop through each controlBox and assign it's channel to each pitch
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
            
            // Now loop through each segment
            EchoNestSegment *previousSegment;
            for(EchoNestSegment *segment in segments)
            {
                NSSet *previousSegmentPitches = previousSegment.pitches;
                float segmentLoudness = [segment.loudnessStart floatValue];
                float segmentStartTime = [segment.start floatValue];
                float segmentEndTime = segmentStartTime + [segment.duration floatValue];
                
                // Only use segments that are withing the current section
                if(segmentStartTime >= sectionStartTime - epsilon && segmentEndTime <= sectionEndTime + epsilon)
                {
                    // Create the commands for the segments
                    for(EchoNestPitch *pitch in segment.pitches)
                    {
                        int currentPitchIndex = pitchesToUse[pitchCounter];
                        float previousPitchValue = [[previousSegmentPitches objectAtIndex:currentPitchIndex] floatValue];
                        float currentPitchValue = [[currentSegmentPitches objectAtIndex:currentPitchIndex] floatValue];
                        float nextPitchValue = [[nextSegmentPitches objectAtIndex:currentPitchIndex] floatValue];
                        float nextNextPitchValue = [[nextNextSegmentPitches objectAtIndex:currentPitchIndex] floatValue];
                        //NSLog(@"pitchIndex:%d currentPitch:%f previousPitch:%f", currentPitchIndex, currentPitchValue, previousPitchValue);
                        
                        // Create a new command (volume increased, therefore it has to be a new 'ding')
                        if(currentPitchValue >= previousPitchValue + 0.1 && currentPitchValue >= 0.3) // && currentPitch > 0.5???
                        {
                            NSLog(@"yes for pitch:%d", currentPitchIndex);
                            NSMutableArray *availbleSegmentChannelIndexPaths = [segmentChannelIndexPathArrays objectAtIndex:currentPitchIndex];
                            NSLog(@"availableChannels:%d", (int)[availbleSegmentChannelIndexPaths count]);
                            
                            for(int i = 0; i < [availbleSegmentChannelIndexPaths count]; i ++)
                            {
                                // Create the newCommand and set it's start/end time
                                NSMutableDictionary *commandClusterForNewCommand = [self commandClusterForCurrentSequenceAtIndex:(int)[[availbleSegmentChannelIndexPaths objectAtIndex:i] indexAtPosition:0]];
                                int newCommandIndex = [self createCommandAndReturnNewCommandIndexForCommandCluster:commandClusterForNewCommand];
                                [self setChannelIndex:(int)[[availbleSegmentChannelIndexPaths objectAtIndex:i] indexAtPosition:1] forCommandAtIndex:newCommandIndex whichIsPartOfCommandCluster:commandClusterForNewCommand];
                                [self setStartTime:currentSegmentStartTime forCommandAtIndex:newCommandIndex whichIsPartOfCommandCluster:commandClusterForNewCommand];
                                float newCommandEndTime;
                                // Note lasts more than this segment
                                if(nextPitchValue <= currentPitchValue)
                                {
                                    // Note lasts at least 2 segments
                                    if((nextPitchValue <= currentPitchValue && nextPitchValue >= 0.3 && [[nextSegment objectForKey:@"confidence"] floatValue] >= 0.3) || (currentPitchValue - nextPitchValue <= 0.1 && currentPitchValue - nextPitchValue >= 0.0 && [[nextSegment objectForKey:@"confidence"] floatValue] < 0.3))
                                    {
                                        // Note lasts three segments
                                        if((nextNextPitchValue <= nextPitchValue && nextNextPitchValue >= 0.3 && [[nextNextSegment objectForKey:@"confidence"] floatValue] >= 0.3) || (nextPitchValue - nextNextPitchValue <= 0.1 && nextPitchValue - nextNextPitchValue >= 0.0 && [[nextNextSegment objectForKey:@"confidence"] floatValue] < 0.3))
                                        {
                                            NSLog(@"three segments");
                                            newCommandEndTime = currentSegmentStartTime + ([[nextNextSegment objectForKey:@"start"] floatValue] - currentSegmentStartTime) + [[nextNextSegment objectForKey:@"duration"] floatValue] - 0.1;
                                        }
                                        // Note lasts two segments but the third segment is a new note
                                        else if(nextNextPitchValue >= nextPitchValue + 0.1 && nextPitchValue >= 0.2)
                                        {
                                            NSLog(@"two segments, third is new note");
                                            newCommandEndTime = currentSegmentStartTime + ([[nextSegment objectForKey:@"start"] floatValue] - currentSegmentStartTime) + [[nextSegment objectForKey:@"duration"] floatValue] - 0.1;
                                        }
                                        // Note lasts two segments and the third segment is not a note
                                        else
                                        {
                                            NSLog(@"two segments");
                                            newCommandEndTime = currentSegmentStartTime + ([[nextSegment objectForKey:@"start"] floatValue] - currentSegmentStartTime) + [[nextSegment objectForKey:@"duration"] floatValue];
                                        }
                                    }
                                    // Note just lasts one segment
                                    else
                                    {
                                        NSLog(@"one segment fade out");
                                        newCommandEndTime = [[currentSegment objectForKey:@"start"] floatValue] + [[currentSegment objectForKey:@"duration"] floatValue];
                                    }
                                }
                                else
                                {
                                    NSLog(@"One segment");
                                    newCommandEndTime = [[currentSegment objectForKey:@"start"] floatValue] + [[currentSegment objectForKey:@"duration"] floatValue] - 0.1;
                                }
                                [self setEndTime:newCommandEndTime forCommandAtIndex:newCommandIndex whichIsPartOfCommandCluster:commandClusterForNewCommand];
                                NSLog(@"c start:%f end:%f", currentSegmentStartTime, newCommandEndTime);
                            }
                        }
                    }
                    
                    // Now create the commands for the tatums within the doman of the current segment
                    for( ; (currentTatumIndex < [tatums count] && tatumControlBoxesCount > 0); currentTatumIndex ++)
                    {
                        NSDictionary *tatum = [tatums objectAtIndex:currentTatumIndex];
                        float tatumStartTime = [[tatum objectForKey:@"start"] floatValue];
                        
                        // This tatum should have commands added
                        if(tatumStartTime >= currentSegmentStartTime && tatumStartTime < currentSegmentEndTime && [[tatum objectForKey:@"confidence"] floatValue] >= 0.10)
                        {
                            //int numberOfChannelsVariation = arc4random() % (int)(numberOfAvailableChannelsForTatums * 0.20) - (int)(numberOfAvailableChannelsForTatums * 0.10); // Add/subtract a 10% variation to the numberOfChannels
                            int numberOfChannelsToUse = ((currentSegmentLoudness - minLoudness) / loudnessRange) * autogenv2Intensity * numberOfAvailableChannelsForTatums / 2;// + numberOfChannelsVariation;
                            
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
                            // Make an array of the availble channels for tatum commands for easy command insertion (controlBoxIndex at index 0, channelIndex at index 1)
                            NSMutableArray *availbleTatumChannelIndexPaths = [[NSMutableArray alloc] init];
                            for(int i = 0; i < tatumControlBoxesCount; i ++)
                            {
                                for(int i2 = 0; i2 < [self channelsCountForControlBox:[self controlBoxForCurrentSequenceAtIndex:tatumControlBoxIndexes[i]]]; i2 ++)
                                {
                                    [availbleTatumChannelIndexPaths addObject:[[NSIndexPath indexPathWithIndex:tatumControlBoxIndexes[i]] indexPathByAddingIndex:i2]];
                                }
                            }
                            
                            // Create the commands for this tatum
                            for(int i = 0; i < numberOfChannelsToUse; i ++)
                            {
                                // Randomly pick a channel/controlBox to use
                                int tatumChannelIndexPathToUse = arc4random() % [availbleTatumChannelIndexPaths count];
                                NSMutableDictionary *commandClusterForNewCommand = [self commandClusterForCurrentSequenceAtIndex:(int)[[availbleTatumChannelIndexPaths objectAtIndex:tatumChannelIndexPathToUse] indexAtPosition:0]];
                                // Create the newCommand and set it's start/end time
                                int newCommandIndex = [self createCommandAndReturnNewCommandIndexForCommandCluster:commandClusterForNewCommand];
                                [self setChannelIndex:(int)[[availbleTatumChannelIndexPaths objectAtIndex:tatumChannelIndexPathToUse] indexAtPosition:1] forCommandAtIndex:newCommandIndex whichIsPartOfCommandCluster:commandClusterForNewCommand];
                                [self setStartTime:[[tatum objectForKey:@"start"] floatValue] forCommandAtIndex:newCommandIndex whichIsPartOfCommandCluster:commandClusterForNewCommand];
                                float newCommandEndTime = [[tatum objectForKey:@"start"] floatValue] + [[tatum objectForKey:@"duration"] floatValue] - 0.1;
                                [self setEndTime:newCommandEndTime forCommandAtIndex:newCommandIndex whichIsPartOfCommandCluster:commandClusterForNewCommand];
                                
                                // Remove this channel/controlBox from the availble channels to use
                                [availbleTatumChannelIndexPaths removeObjectAtIndex:tatumChannelIndexPathToUse];
                            }
                        }
                        // We are done looking if we get past the endTime of the current segment since the data is sorted
                        else if(tatumStartTime >= currentSegmentEndTime)
                        {
                            break;
                        }
                    }
                    
                    // Now create the commands for the beats within the doman of the current segment
                    for( ; (currentBeatIndex < [beats count] && beatControlBoxesCount > 0); currentBeatIndex ++)
                    {
                        NSDictionary *beat = [beats objectAtIndex:currentBeatIndex];
                        float beatStartTime = [[beat objectForKey:@"start"] floatValue];
                        
                        // This beat should have commands added
                        if(beatStartTime >= currentSegmentStartTime && beatStartTime < currentSegmentEndTime && [[beat objectForKey:@"confidence"] floatValue] >= 0.10)
                        {
                            //int numberOfChannelsVariation = arc4random() % (int)(numberOfAvailableChannelsForBeats * 0.20) - (int)(numberOfAvailableChannelsForBeats * 0.10); // Add/subtract a 10% variation to the numberOfChannels
                            int numberOfChannelsToUse = ((currentSegmentLoudness - minLoudness) / loudnessRange) * autogenv2Intensity * numberOfAvailableChannelsForBeats / 2;// + numberOfChannelsVariation;
                            
                            // Limit the numberOfChannelsToUse
                            if(numberOfChannelsToUse > numberOfAvailableChannelsForBeats)
                            {
                                numberOfChannelsToUse = numberOfAvailableChannelsForBeats;
                            }
                            else if(numberOfChannelsToUse < 0)
                            {
                                numberOfChannelsToUse = 0;
                            }
                            else if(numberOfChannelsToUse == 0)
                            {
                                numberOfChannelsToUse ++;
                            }
                            // Make an array of the availble channels for beat commands for easy command insertion (controlBoxIndex at index 0, channelIndex at index 1)
                            NSMutableArray *availbleBeatChannelIndexPaths = [[NSMutableArray alloc] init];
                            for(int i = 0; i < beatControlBoxesCount; i ++)
                            {
                                for(int i2 = 0; i2 < [self channelsCountForControlBox:[self controlBoxForCurrentSequenceAtIndex:beatControlBoxIndexes[i]]]; i2 ++)
                                {
                                    [availbleBeatChannelIndexPaths addObject:[[NSIndexPath indexPathWithIndex:beatControlBoxIndexes[i]] indexPathByAddingIndex:i2]];
                                }
                            }
                            
                            // Create the commands for this beat
                            for(int i = 0; i < numberOfChannelsToUse; i ++)
                            {
                                // Randomly pick a channel/controlBox to use
                                int beatChannelIndexPathToUse = arc4random() % [availbleBeatChannelIndexPaths count];
                                NSMutableDictionary *commandClusterForNewCommand = [self commandClusterForCurrentSequenceAtIndex:(int)[[availbleBeatChannelIndexPaths objectAtIndex:beatChannelIndexPathToUse] indexAtPosition:0]];
                                // Create the newCommand and set it's start/end time
                                int newCommandIndex = [self createCommandAndReturnNewCommandIndexForCommandCluster:commandClusterForNewCommand];
                                [self setChannelIndex:(int)[[availbleBeatChannelIndexPaths objectAtIndex:beatChannelIndexPathToUse] indexAtPosition:1] forCommandAtIndex:newCommandIndex whichIsPartOfCommandCluster:commandClusterForNewCommand];
                                [self setStartTime:[[beat objectForKey:@"start"] floatValue] forCommandAtIndex:newCommandIndex whichIsPartOfCommandCluster:commandClusterForNewCommand];
                                float newCommandEndTime = [[beat objectForKey:@"start"] floatValue] + [[beat objectForKey:@"duration"] floatValue] - 0.1;
                                [self setEndTime:newCommandEndTime forCommandAtIndex:newCommandIndex whichIsPartOfCommandCluster:commandClusterForNewCommand];
                                
                                // Remove this channel/controlBox from the availble channels to use
                                [availbleBeatChannelIndexPaths removeObjectAtIndex:beatChannelIndexPathToUse];
                            }
                        }
                        // We are done looking if we get past the endTime of the current segment since the data is sorted
                        else if(beatStartTime >= currentSegmentEndTime)
                        {
                            break;
                        }
                    }
                }
            }
        }
        
        [[CoreDataManager sharedManager] saveContext];
        //[[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
        //[[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateLibraryContent" object:nil];
    }
}*/

@end
