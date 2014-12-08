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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeCommandtype:) name:@"ChangeCommandType" object:nil];
    
    self.isPlayButton = YES;
    [self reloadAudio];
    [self currentTimeChange:nil];
}

- (void)viewWillAppear
{
    [[CoreDataManager sharedManager] getLatestOrCreateNewSequence];
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
        // Scroll to center
        NSRect visibleRect = [self.timelineScrollView documentVisibleRect];
        float leftEdgeTime = [[SequenceLogic sharedInstance] xToTime:visibleRect.origin.x];
        float rightEdgeTime = [[SequenceLogic sharedInstance] xToTime:visibleRect.origin.x + visibleRect.size.width];
        if([SequenceLogic sharedInstance].currentTime > (rightEdgeTime - leftEdgeTime) / 2.0 || [SequenceLogic sharedInstance].currentTime < (rightEdgeTime - leftEdgeTime) / 2.0)
        {
            float newLeftX = [[SequenceLogic sharedInstance] timeToX:[SequenceLogic sharedInstance].currentTime - (rightEdgeTime - leftEdgeTime) / 2.0];
            if(newLeftX < 0)
            {
                newLeftX = 0;
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
}

- (void)reloadAudio
{
    NSError *error = nil;
    self.audioPlayer = [[AVAudioPlayer alloc] initWithData:[CoreDataManager sharedManager].currentSequence.audio.audioFile fileTypeHint:[[CoreDataManager sharedManager].currentSequence.audio.audioFilePath pathExtension] error:&error];
    //NSLog(@"Audio error %@, %@", error, [error userInfo]);
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
    NSLog(@"play selection");
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
