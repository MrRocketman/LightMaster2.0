//
//  SequenceViewController.m
//  LightMaster
//
//  Created by James Adams on 11/25/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import "SequenceViewController.h"
#import "CoreDataManager.h"
#import "SequenceScrollView.h"
#import "SequenceView.h"
#import "SequenceChannelScrollView.h"
#import "SequenceTimelineScrollView.h"
#import "SequenceTimelineView.h"
#import "SequenceAudioAnalysisScrollView.h"
#import "SequenceAudioAnalysisChannelScrollView.h"
#import "SequenceLogic.h"
#import "NSManagedObjectContext+Queryable.h"
#import <AVFoundation/AVFoundation.h>
#import "Audio.h"
#import "Sequence.h"
#import "SequenceTatum.h"
#import "ORSSerialPortManager.h"
#import "ORSSerialPort.h"

@interface SequenceViewController ()

@property (strong, nonatomic) AVAudioPlayer *audioPlayer;
@property (assign, nonatomic) BOOL isPlayButton;
@property (assign, nonatomic) BOOL isPlaySelection;
@property (assign, nonatomic) BOOL isPlayFromCurrentTime;
@property (strong, nonatomic) NSTimer *audioTimer;
@property (assign, nonatomic) float splitViewY;
@property (strong, nonatomic) Audio *currentAudio;
@property (assign, nonatomic) float lastChannelUpdateTime;

@end

@implementation SequenceViewController

- (void)awakeFromNib
{
    self.serialPortManager = [ORSSerialPortManager sharedSerialPortManager];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do view setup here.
    
    if(![CoreDataManager sharedManager].currentSequence)
    {
        [[CoreDataManager sharedManager] getLatestOrCreateNewSequence];
        [[SequenceLogic sharedInstance] resetCommandsSendComplete];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadSequenceFromNotification:) name:@"CurrentSequenceChange" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentTimeChange:) name:@"CurrentTimeChange" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeCommandtype:) name:@"ChangeCommandType" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playPause:) name:@"PlayPause" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playPauseSelection:) name:@"PlayPauseSelection" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playPauseFromCurrentTime:) name:@"PlayPauseFromCurrentTime" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deselectMouse:) name:@"DeselectMouse" object:nil];
    
    [self.serialPortButton selectItemAtIndex:0];
    //[self serialPortSelectionChange:nil];
    [self performSelector:@selector(serialPortSelectionChange:) withObject:nil afterDelay:2.0];
    
    self.isPlayButton = YES;
    [self reloadAudio];
    [self currentTimeChange:nil];
}

- (void)viewWillAppear
{
    [self reloadSequence];
    int numberOfAudioChannels = [[SequenceLogic sharedInstance] numberOfAudioChannels];
    self.splitViewY = CHANNEL_HEIGHT;
    if(numberOfAudioChannels > 0 && numberOfAudioChannels < 10)
    {
        self.splitViewY = numberOfAudioChannels * CHANNEL_HEIGHT + 2;
    }
    else if(numberOfAudioChannels >= 10)
    {
        self.splitViewY = 10 * CHANNEL_HEIGHT + 2;
    }
    [self.splitView setPosition:self.splitViewY ofDividerAtIndex:0];
}

#pragma mark - SplitViewDelegate

// Controls the MAX position of a split
-(CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMaximumPosition ofSubviewAt:(NSInteger)dividerIndex
{
    int numberOfAudioChannels = [[SequenceLogic sharedInstance] numberOfAudioChannels];
    float maxY = numberOfAudioChannels * CHANNEL_HEIGHT + 2;
    if(maxY > self.view.frame.size.height - 200)
    {
        maxY = self.view.frame.size.height - 200;
    }
    return maxY;
}

// Controls the MIN position of a split
-(CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex
{
    return 20;
}

#pragma mark - Other

- (void)reloadSequenceFromNotification:(NSNotification *)notification
{
    [self reloadSequence];
}

- (void)changeCommandtype:(NSNotification *)notification
{
    [self.commandTypeSegmentedControl setSelectedSegment:[SequenceLogic sharedInstance].commandType];
}

- (void)deselectMouse:(NSNotification *)notification
{
    self.lastChannelUpdateTime = -1;
    [[SequenceLogic sharedInstance] resetCommandsSendComplete];
}

- (void)currentTimeChange:(NSNotification *)notification
{
    self.timeLabel.stringValue = [NSString stringWithFormat:@"%03d.%03d", (int)[SequenceLogic sharedInstance].currentTime, (int)(([SequenceLogic sharedInstance].currentTime - (int)[SequenceLogic sharedInstance].currentTime) * 1000)];
    
    // Only update the audio if the user dragged the time marker
    if(notification.object != self)
    {
        self.audioPlayer.currentTime = [SequenceLogic sharedInstance].currentTime;
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

- (void)reloadSequence
{
    [self.sequenceScrollView updateViews];
    [self.channelScrollView updateViews];
    [self.timelineScrollView updateViews];
    [self.audioAnalysisScrollView updateViews];
    [self.audioAnalysisChannelScrollView updateViews];
    
    if(self.currentAudio != [CoreDataManager sharedManager].currentSequence.audio)
    {
        [self reloadAudio];
    }
}

#pragma mark - Button Actions

- (IBAction)serialPortSelectionChange:(id)sender
{
    // Remove the old port
    [SequenceLogic sharedInstance].serialPort.delegate = nil;
    [[SequenceLogic sharedInstance].serialPort close];
    [SequenceLogic sharedInstance].serialPort = nil;
    
    // Open the new port
    //ORSSerialPort *serialPort = [ORSSerialPort serialPortWithPath:[[self.serialPortButton selectedItem] title]];
    ORSSerialPort *serialPort = self.serialPortManager.availablePorts[self.serialPortButton.indexOfSelectedItem];
    [serialPort setDelegate:[SequenceLogic sharedInstance]];
    [serialPort setBaudRate:@57600];
    [serialPort open];
    [SequenceLogic sharedInstance].serialPort = serialPort;
}

- (IBAction)skipBackButtonPress:(id)sender
{
    [SequenceLogic sharedInstance].currentTime = 0;
    self.audioPlayer.currentTime = 0;
    self.lastChannelUpdateTime = -1;
    [[SequenceLogic sharedInstance] resetCommandsSendComplete];
    [self updateTime];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CurrentTimeChange" object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DeselectMouse" object:nil];
}

- (IBAction)playButtonPress:(id)sender
{
    [self playPause:nil];
}

- (void)playPause
{
    if(self.isPlayButton)
    {
        [self.audioPlayer play];
        self.playButton.title = @"Pause";
        self.audioTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(audioTimerFire:) userInfo:nil repeats:YES];
        [SequenceLogic sharedInstance].showChannelBrightness = YES;
        self.lastChannelUpdateTime = -1;
    }
    else
    {
        [self.audioPlayer pause];
        self.playButton.title = @"Play";
        [self.audioTimer invalidate];
        self.audioTimer = nil;
        [SequenceLogic sharedInstance].showChannelBrightness = NO;
        
        // Update channel brightness levels
        [self.audioAnalysisChannelScrollView updateViews];
        [self.channelScrollView updateViews];
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
        [SequenceLogic sharedInstance].currentTime = [[SequenceLogic sharedInstance].mouseBoxSelectStartTatum.time floatValue] - 0.05;
        self.audioPlayer.currentTime = [SequenceLogic sharedInstance].currentTime;
    }
    
    [self playPause];
}

- (void)playPauseFromCurrentTime:(NSNotification *)notification
{
    self.isPlayFromCurrentTime = YES;
    self.isPlaySelection = NO;
    
    if(self.isPlayButton)
    {
        [SequenceLogic sharedInstance].currentTime = [[SequenceLogic sharedInstance].mouseBoxSelectStartTatum.time floatValue];
        self.audioPlayer.currentTime = [SequenceLogic sharedInstance].currentTime;
    }
    
    [self playPause];
}

#pragma mark - Time

- (void)audioTimerFire:(NSTimer *)timer
{
    [SequenceLogic sharedInstance].currentTime = self.audioPlayer.currentTime;//[[NSDate date] timeIntervalSinceDate:self.playStartDate] + self.playStartTime;
    [self updateTime];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CurrentTimeChange" object:self];
}

- (void)updateTime
{
    // Loop back to beginning
    if([SequenceLogic sharedInstance].currentTime > [[CoreDataManager sharedManager].currentSequence.endTime floatValue])
    {
        [self.audioPlayer stop];
        self.audioPlayer.currentTime = 0;
        self.lastChannelUpdateTime = -1;
        [[SequenceLogic sharedInstance] resetCommandsSendComplete];
        [self.audioPlayer play];
        [SequenceLogic sharedInstance].currentTime = 0;
    }
    // If we are playing a selection
    else if(self.isPlaySelection && [SequenceLogic sharedInstance].currentTime >= [[SequenceLogic sharedInstance].mouseBoxSelectEndTatum.time floatValue])
    {
        self.isPlaySelection = NO;
        self.isPlayButton = !self.isPlayButton;
        [self.playButton setState:0];
        self.playButton.title = @"Play";
        [self.audioPlayer pause];
        [self.audioTimer invalidate];
        self.audioTimer = nil;
        [SequenceLogic sharedInstance].showChannelBrightness = NO;
        // Update channel brightness levels
        [self.audioAnalysisChannelScrollView updateViews];
        [self.channelScrollView updateViews];
        self.lastChannelUpdateTime = -1;
    }
    
    // Scroll to center
    NSRect visibleRect = [self.timelineScrollView documentVisibleRect];
    NSRect viewFrame = ((SequenceTimelineView *)self.timelineScrollView.documentView).frame;
    float smallestTime = [[SequenceLogic sharedInstance] xToTime:visibleRect.origin.x];
    float middleTime = [[SequenceLogic sharedInstance] xToTime:visibleRect.origin.x + visibleRect.size.width / 2];
    float largestTime = [[SequenceLogic sharedInstance] xToTime:viewFrame.size.width - visibleRect.size.width / 2];
    float newLeftX;
    // Current time is from the middle of the screen onward
    if([SequenceLogic sharedInstance].currentTime >= middleTime && [SequenceLogic sharedInstance].currentTime < largestTime)
    {
        // Go to center
        float xDifference = [[SequenceLogic sharedInstance] timeToX:[SequenceLogic sharedInstance].currentTime] - visibleRect.size.width / 2.0 - visibleRect.origin.x;
        newLeftX = [[SequenceLogic sharedInstance] timeToX:[SequenceLogic sharedInstance].currentTime] - visibleRect.size.width / 2.0;
        // Accelerate forward if the current time is beyond the center
        if(xDifference > 10)
        {
            newLeftX -= xDifference - (xDifference / 5.0);
        }
    }
    // Current time if from the left of the screen to the middle
    else if([SequenceLogic sharedInstance].currentTime < middleTime && [SequenceLogic sharedInstance].currentTime >= smallestTime)
    {
        newLeftX = visibleRect.origin.x;
    }
    // Current time is less than the left edge
    else if([SequenceLogic sharedInstance].currentTime < smallestTime)
    {
        // left edge
        newLeftX = 0;
    }
    // Current time is greater than the far edge
    else
    {
        // right edge
        newLeftX = viewFrame.size.width - visibleRect.size.width;
    }
    
    NSRect sequenceVisibleRect = [self.sequenceScrollView documentVisibleRect];
    NSRect audioAnalysisVisibleRect = [self.audioAnalysisScrollView documentVisibleRect];
    [self.sequenceScrollView.contentView scrollToPoint:NSMakePoint(newLeftX, sequenceVisibleRect.origin.y)];
    [self.sequenceScrollView reflectScrolledClipView:self.sequenceScrollView.contentView];
    [self.timelineScrollView.contentView scrollToPoint:NSMakePoint(newLeftX, visibleRect.origin.y)];
    [self.timelineScrollView reflectScrolledClipView:self.timelineScrollView.contentView];
    [self.audioAnalysisScrollView.contentView scrollToPoint:NSMakePoint(newLeftX, audioAnalysisVisibleRect.origin.y)];
    [self.audioAnalysisScrollView reflectScrolledClipView:self.audioAnalysisScrollView.contentView];
    
    // Update channel brightness at 30Hz
    [[SequenceLogic sharedInstance] updateCommandsForCurrentTime];
    if([SequenceLogic sharedInstance].currentTime > self.lastChannelUpdateTime + 0.06)
    {
        self.lastChannelUpdateTime = [SequenceLogic sharedInstance].currentTime;
        //[[SequenceLogic sharedInstance] updateCommandsForCurrentTime];
        
        [self.audioAnalysisChannelScrollView updateViews];
        [self.channelScrollView updateViews];
    }
}

- (IBAction)commandTypeSegmentedControlChange:(id)sender
{
    [SequenceLogic sharedInstance].commandType = (int)self.commandTypeSegmentedControl.selectedSegment;
}

@end
