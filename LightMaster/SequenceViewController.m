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
#import "SequenceChannelScrollView.h"
#import "SequenceTimelineScrollView.h"
#import "SequenceAudioAnalysisScrollView.h"
#import "SequenceAudioAnalysisChannelScrollView.h"
#import "SequenceLogic.h"
#import "NSManagedObjectContext+Queryable.h"
#import <AVFoundation/AVFoundation.h>
#import "Audio.h"
#import "Sequence.h"

@interface SequenceViewController ()

@property (strong, nonatomic) AVAudioPlayer *audioPlayer;
@property (assign, nonatomic) BOOL isPlayButton;
@property (strong, nonatomic) NSTimer *audioTimer;
@property (strong, nonatomic) NSDate *playStartDate;
@property (assign, nonatomic) float playStartTime;

@end

@implementation SequenceViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do view setup here.
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadSequenceFromNotification:) name:@"CurrentSequenceChange" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentTimeChange:) name:@"CurrentTimeChange" object:nil];
    
    self.isPlayButton = YES;
    [self reloadAudio];
}

- (void)viewWillAppear
{
    [[CoreDataManager sharedManager] getLatestOrCreateNewSequence];
    [self reloadSequence];
    int numberOfAudioChannels = [[SequenceLogic sharedInstance] numberOfAudioChannels];
    float startY = CHANNEL_HEIGHT;
    if(numberOfAudioChannels > 0 && numberOfAudioChannels < 10)
    {
        startY = numberOfAudioChannels * CHANNEL_HEIGHT;
    }
    else if(numberOfAudioChannels >= 10)
    {
        startY = 10 * CHANNEL_HEIGHT;
    }
    [self.splitView setPosition:startY ofDividerAtIndex:0];
}

- (void)reloadSequenceFromNotification:(NSNotification *)notification
{
    [self reloadSequence];
}

- (void)currentTimeChange:(NSNotification *)notification
{
    self.timeLabel.stringValue = [NSString stringWithFormat:@"%03d.%03d", (int)[SequenceLogic sharedInstance].currentTime, (int)(([SequenceLogic sharedInstance].currentTime - (int)[SequenceLogic sharedInstance].currentTime) * 1000)];
    self.audioPlayer.currentTime = [SequenceLogic sharedInstance].currentTime;
}

- (void)reloadAudio
{
    NSError *error = nil;
    NSLog(@"currentsequence:%@", [CoreDataManager sharedManager].currentSequence);
    //NSLog(@"audioFile:%@", [CoreDataManager sharedManager].currentSequence.audio.audioFile);
    self.audioPlayer = [[AVAudioPlayer alloc] initWithData:[CoreDataManager sharedManager].currentSequence.audio.audioFile error:&error];
    NSLog(@"Audio error %@, %@", error, [error userInfo]);
    self.audioPlayer.currentTime = 1.0;
}

- (void)reloadSequence
{
    [self.sequenceScrollView updateViews];
    [self.channelScrollView updateViews];
    [self.timelineScrollView updateViews];
    [self.audioAnalysisScrollView updateViews];
    [self.audioAnalysisChannelScrollView updateViews];
    
    [self reloadAudio];
}

- (IBAction)skipBackButtonPress:(id)sender
{
    [SequenceLogic sharedInstance].currentTime = 0;
    self.audioPlayer.currentTime = 0;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CurrentTimeChange" object:nil];
}

- (IBAction)playButtonPress:(id)sender
{
    NSLog(@"play/pause");
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
    NSLog(@"play selection");
}

- (void)audioTimerFire:(NSTimer *)timer
{
    [SequenceLogic sharedInstance].currentTime = [[NSDate date] timeIntervalSinceDate:self.playStartDate] + self.playStartTime;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CurrentTimeChange" object:nil];
}

@end
