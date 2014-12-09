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

@interface SequenceViewController ()

@property (strong, nonatomic) AVAudioPlayer *audioPlayer;
@property (assign, nonatomic) BOOL isPlayButton;
@property (strong, nonatomic) NSTimer *audioTimer;
@property (strong, nonatomic) NSDate *playStartDate;
@property (assign, nonatomic) float playStartTime;
@property (assign, nonatomic) BOOL isPlaySelectionButton;

@property (strong, nonatomic) Audio *currentAudio;

@end

@implementation SequenceViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do view setup here.
    
    if(![CoreDataManager sharedManager].currentSequence)
    {
        [[CoreDataManager sharedManager] getLatestOrCreateNewSequence];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadSequenceFromNotification:) name:@"CurrentSequenceChange" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentTimeChange:) name:@"CurrentTimeChange" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeCommandtype:) name:@"ChangeCommandType" object:nil];
    
    self.isPlayButton = YES;
    self.isPlaySelectionButton = YES;
    [self reloadAudio];
    [self currentTimeChange:nil];
}

- (void)viewWillAppear
{
    [self reloadSequence];
    int numberOfAudioChannels = [[SequenceLogic sharedInstance] numberOfAudioChannels];
    float startY = CHANNEL_HEIGHT;
    if(numberOfAudioChannels > 0 && numberOfAudioChannels < 10)
    {
        startY = numberOfAudioChannels * CHANNEL_HEIGHT + 5;
    }
    else if(numberOfAudioChannels >= 10)
    {
        startY = 10 * CHANNEL_HEIGHT + 5;
    }
    [self.splitView setPosition:startY ofDividerAtIndex:0];
}

- (void)reloadSequenceFromNotification:(NSNotification *)notification
{
    [self reloadSequence];
}

- (void)changeCommandtype:(NSNotification *)notification
{
    [self.commandTypeSegmentedControl setSelectedSegment:[SequenceLogic sharedInstance].commandType];
}

- (void)currentTimeChange:(NSNotification *)notification
{
    self.timeLabel.stringValue = [NSString stringWithFormat:@"%03d.%03d", (int)[SequenceLogic sharedInstance].currentTime, (int)(([SequenceLogic sharedInstance].currentTime - (int)[SequenceLogic sharedInstance].currentTime) * 1000)];
    self.playStartDate = [NSDate date];
    self.playStartTime = [SequenceLogic sharedInstance].currentTime;
    
    // Only update the audio if the user dragged the time marker
    if(notification.object != self)
    {
        self.audioPlayer.currentTime = [SequenceLogic sharedInstance].currentTime;
    }
    else
    {
        // Loop back to beginning
        if([SequenceLogic sharedInstance].currentTime > [[CoreDataManager sharedManager].currentSequence.endTime floatValue])
        {
            [self.audioPlayer stop];
            self.audioPlayer.currentTime = 0;
            [self.audioPlayer play];
            [SequenceLogic sharedInstance].currentTime = 0;
            self.playStartDate = [NSDate date];
            self.playStartTime = [SequenceLogic sharedInstance].currentTime;
        }
        // If we are playing a selection
        else if(!self.isPlaySelectionButton && [SequenceLogic sharedInstance].currentTime > [((SequenceView *)(self.sequenceScrollView.documentView)).mouseBoxSelectEndTatum.time floatValue])
        {
            /*float newTime = [((SequenceView *)(self.sequenceScrollView.documentView)).mouseBoxSelectStartTatum.time floatValue];
            self.audioPlayer.currentTime = newTime;
            [SequenceLogic sharedInstance].currentTime = newTime;
            self.playStartDate = [NSDate date];
            self.playStartTime = [SequenceLogic sharedInstance].currentTime;*/
            self.isPlaySelectionButton = !self.isPlaySelectionButton;
            [self.playSelectionButton setState:0];
            self.playSelectionButton.title = @"Play";
            [self.audioPlayer pause];
            [self.audioTimer invalidate];
            self.audioTimer = nil;
        }
        
        // Scroll to center
        NSRect visibleRect = [self.timelineScrollView documentVisibleRect];
        NSRect viewFrame = ((SequenceTimelineView *)self.timelineScrollView.documentView).frame;
        float smallestTime = [[SequenceLogic sharedInstance] xToTime:visibleRect.size.width / 2];
        float largestTime = [[SequenceLogic sharedInstance] xToTime:viewFrame.size.width - visibleRect.size.width / 2];
        float newLeftX;
        if([SequenceLogic sharedInstance].currentTime > smallestTime && [SequenceLogic sharedInstance].currentTime < largestTime)
        {
            newLeftX = [[SequenceLogic sharedInstance] timeToX:[SequenceLogic sharedInstance].currentTime] - visibleRect.size.width / 2.0;
        }
        else if([SequenceLogic sharedInstance].currentTime < smallestTime)
        {
            // left edge
            newLeftX = 0;
        }
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
    }
}

- (void)reloadAudio
{
    NSError *error = nil;
    self.audioPlayer = [[AVAudioPlayer alloc] initWithData:[CoreDataManager sharedManager].currentSequence.audio.audioFile fileTypeHint:[[CoreDataManager sharedManager].currentSequence.audio.audioFilePath pathExtension] error:&error];
    //NSLog(@"Audio error %@, %@", error, [error userInfo]);
    self.audioPlayer.currentTime = 1.0;
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

- (IBAction)skipBackButtonPress:(id)sender
{
    [SequenceLogic sharedInstance].currentTime = 0;
    self.audioPlayer.currentTime = 0;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CurrentTimeChange" object:self];
}

- (IBAction)playButtonPress:(id)sender
{
    if(self.isPlayButton)
    {
        [self.audioPlayer play];
        self.playButton.title = @"Pause";
        self.playStartDate = [NSDate date];
        self.playStartTime = [SequenceLogic sharedInstance].currentTime;
        self.audioTimer = [NSTimer scheduledTimerWithTimeInterval:0.03 target:self selector:@selector(audioTimerFire:) userInfo:nil repeats:YES];
    }
    else
    {
        [self.audioPlayer pause];
        self.playButton.title = @"Play";
        [self.audioTimer invalidate];
        self.audioTimer = nil;
    }
    
    self.isPlayButton = !self.isPlayButton;
}

- (IBAction)playSelectionButtonPress:(id)sender
{
    if(self.isPlaySelectionButton)
    {
        [SequenceLogic sharedInstance].currentTime = [((SequenceView *)(self.sequenceScrollView.documentView)).mouseBoxSelectStartTatum.time floatValue];
        self.audioPlayer.currentTime = [SequenceLogic sharedInstance].currentTime;
        [self.audioPlayer play];
        self.playButton.title = @"Pause";
        self.playStartDate = [NSDate date];
        self.playStartTime = [SequenceLogic sharedInstance].currentTime;
        self.audioTimer = [NSTimer scheduledTimerWithTimeInterval:0.03 target:self selector:@selector(audioTimerFire:) userInfo:nil repeats:YES];
    }
    else
    {
        [self.audioPlayer pause];
        self.playButton.title = @"Play";
        [self.audioTimer invalidate];
        self.audioTimer = nil;
    }
    
    self.isPlaySelectionButton = !self.isPlaySelectionButton;
}

- (void)audioTimerFire:(NSTimer *)timer
{
    [SequenceLogic sharedInstance].currentTime = [[NSDate date] timeIntervalSinceDate:self.playStartDate] + self.playStartTime;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CurrentTimeChange" object:self];
}

- (IBAction)commandTypeSegmentedControlChange:(id)sender
{
    [SequenceLogic sharedInstance].commandType = (int)self.commandTypeSegmentedControl.selectedSegment;
}

@end
