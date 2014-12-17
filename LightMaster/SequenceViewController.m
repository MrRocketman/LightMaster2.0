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
#import "ORSSerialPortManager.h"
#import "ORSSerialPort.h"

@interface SequenceViewController ()

@property (assign, nonatomic) float splitViewY;

@end

@implementation SequenceViewController

- (void)awakeFromNib
{
    self.serialPortManager = [ORSSerialPortManager sharedSerialPortManager];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeCommandtype:) name:@"ChangeCommandType" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playPauseButtonUpdate:) name:@"PlayPauseButtonUpdate" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pause:) name:@"Pause" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentTimeChange:) name:@"CurrentTimeChange" object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do view setup here.
    
    [self.serialPortButton selectItemAtIndex:0];
    //[self serialPortSelectionChange:nil];
    [self performSelector:@selector(serialPortSelectionChange:) withObject:nil afterDelay:2.0];
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

- (void)reloadSequence
{
    [self.sequenceScrollView updateViews];
    [self.channelScrollView updateViews];
    [self.timelineScrollView updateViews];
    [self.audioAnalysisScrollView updateViews];
    [self.audioAnalysisChannelScrollView updateViews];
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
    [[SequenceLogic sharedInstance] skipBack];
}

- (IBAction)playButtonPress:(id)sender
{
    [[SequenceLogic sharedInstance] playPause:nil];
}

- (IBAction)commandTypeSegmentedControlChange:(id)sender
{
    [SequenceLogic sharedInstance].commandType = (int)self.commandTypeSegmentedControl.selectedSegment;
}

- (void)playPauseButtonUpdate:(NSNotification *)notification
{
    if([notification.object boolValue])
    {
        self.playButton.title = @"Pause";
    }
    else
    {
        self.playButton.title = @"Play";
        
        // Update channel brightness levels
        [self.audioAnalysisChannelScrollView updateViews];
        [self.channelScrollView updateViews];
    }
}

- (void)pause:(NSNotification *)notification
{
    [self.playButton setState:0];
}

- (void)currentTimeChange:(NSNotification *)notification
{
    self.timeLabel.stringValue = [NSString stringWithFormat:@"%03d.%03d", (int)[SequenceLogic sharedInstance].currentTime, (int)(([SequenceLogic sharedInstance].currentTime - (int)[SequenceLogic sharedInstance].currentTime) * 1000)];
    
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
}

@end
