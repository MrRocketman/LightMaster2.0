//
//  SequenceViewController.h
//  LightMaster
//
//  Created by James Adams on 11/25/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SequenceScrollView, SequenceChannelScrollView, SequenceTimelineScrollView, SequenceAudioAnalysisChannelScrollView, SequenceAudioAnalysisScrollView;

@interface SequenceViewController : NSViewController

@property (strong, nonatomic) IBOutlet NSView *toolbarView;
@property (strong, nonatomic) IBOutlet NSPopUpButton *serialPortButton;
@property (strong, nonatomic) IBOutlet NSButton *skipBackButton;
@property (strong, nonatomic) IBOutlet NSButton *playButton;
@property (strong, nonatomic) IBOutlet NSButton *playSelectionButton;
@property (strong, nonatomic) IBOutlet NSTextField *timeLabel;
@property (strong, nonatomic) IBOutlet NSSegmentedControl *commandTypeSegmentedControl;
@property (strong, nonatomic) IBOutlet NSButton *sequenceListButton;

@property (strong, nonatomic) IBOutlet NSTextField *titleLabel;

@property (strong, nonatomic) IBOutlet SequenceScrollView *sequenceScrollView;
@property (strong, nonatomic) IBOutlet SequenceChannelScrollView *channelScrollView;
@property (strong, nonatomic) IBOutlet SequenceTimelineScrollView *timelineScrollView;
@property (strong, nonatomic) IBOutlet SequenceAudioAnalysisScrollView *audioAnalysisScrollView;
@property (strong, nonatomic) IBOutlet SequenceAudioAnalysisChannelScrollView *audioAnalysisChannelScrollView;

- (IBAction)skipBackButtonPress:(id)sender;
- (IBAction)playButtonPress:(id)sender;
- (IBAction)playSelectionButtonPress:(id)sender;

@end
