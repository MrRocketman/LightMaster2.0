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

@interface SequenceViewController ()

@end

@implementation SequenceViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do view setup here.
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadSequenceFromNotification:) name:@"CurrentSequenceChange" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentTimeChange:) name:@"CurrentTimeChange" object:nil];
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
}

- (void)reloadSequence
{
    [self.sequenceScrollView updateViews];
    [self.channelScrollView updateViews];
    [self.timelineScrollView updateViews];
    [self.audioAnalysisScrollView updateViews];
    [self.audioAnalysisChannelScrollView updateViews];
}

- (IBAction)skipBackButtonPress:(id)sender
{
    [SequenceLogic sharedInstance].currentTime = 0;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CurrentTimeChange" object:nil];
}

- (IBAction)playButtonPress:(id)sender
{
    NSLog(@"play/pause");
}

- (IBAction)playSelectionButtonPress:(id)sender
{
    NSLog(@"play selection");
}

@end
