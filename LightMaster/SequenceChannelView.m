//
//  SequenceChannelView.m
//  LightMaster
//
//  Created by James Adams on 11/30/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import "SequenceChannelView.h"
#import "SequenceLogic.h"
#import "CoreDataManager.h"
#import "NSManagedObjectContext+Queryable.h"
#import "Sequence.h"
#import "UserAudioAnalysisTrack.h"
#import "UserAudioAnalysisTrackChannel.h"
#import "Channel.h"
#import "ControlBox.h"

@implementation SequenceChannelView

- (void)awakeFromNib
{
    
}

- (BOOL)isFlipped
{
    return YES;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    self.frame = NSMakeRect(0, 0, self.frame.size.width, [[SequenceLogic sharedInstance] numberOfChannels] * CHANNEL_HEIGHT);
    
    // clear the background
    //[[NSColor darkGrayColor] set];
    //NSRectFill(self.bounds);
    
    [self drawHeaders];
    [self drawChannels];
}

- (void)drawHeaders
{
    int channelIndex = 0;
    
    // Audio
    NSBezierPath *audioPath = [NSBezierPath bezierPath];
    [self drawHeaderWithChannelIndex:channelIndex text:@"Add Audio" textOffset:60 color:[NSColor darkGrayColor] halfWidth:NO andBezierPath:audioPath channelHeight:1];
    channelIndex ++;
    
    // New Analysis Track
    NSBezierPath *newAnalysisTrack = [NSBezierPath bezierPath];
    [self drawHeaderWithChannelIndex:channelIndex text:@"Add Analysis Track" textOffset:30 color:[NSColor darkGrayColor] halfWidth:NO andBezierPath:newAnalysisTrack channelHeight:1];
    channelIndex ++;
    
    // AnalysisTracks
    NSArray *userAudioAnalysisTracks = [[[[CoreDataManager sharedManager].managedObjectContext ofType:@"UserAudioAnalysisTrack"] where:@"sequence == %@", [CoreDataManager sharedManager].currentSequence] toArray];
    NSBezierPath *analysisTrackPath = [NSBezierPath bezierPath];
    for(UserAudioAnalysisTrack *track in userAudioAnalysisTracks)
    {
        [self drawHeaderWithChannelIndex:channelIndex text:track.title textOffset:10 color:[NSColor grayColor] halfWidth:YES andBezierPath:analysisTrackPath channelHeight:(int)track.channels.count];
        channelIndex ++;
    }
    
    // New ControlBox
    NSBezierPath *newControlBox = [NSBezierPath bezierPath];
    [self drawHeaderWithChannelIndex:channelIndex text:@"Add Control Box" textOffset:40 color:[NSColor darkGrayColor] halfWidth:NO andBezierPath:newControlBox channelHeight:1];
    channelIndex ++;
    
    // ControlBoxes
    NSArray *controlBoxes = [[[[CoreDataManager sharedManager].managedObjectContext ofType:@"ControlBox"] where:@"sequence CONTAINS %@", [CoreDataManager sharedManager].currentSequence] toArray];
    NSBezierPath *controlBoxPath = [NSBezierPath bezierPath];
    for(ControlBox *box in controlBoxes)
    {
        [self drawHeaderWithChannelIndex:channelIndex text:box.title textOffset:10 color:[NSColor grayColor] halfWidth:YES andBezierPath:controlBoxPath channelHeight:(int)box.channels.count];
    }
}

- (void)drawChannels
{
    
}

#pragma mark - Helper Drawing Methods

- (void)drawHeaderWithChannelIndex:(int)index text:(NSString *)text textOffset:(int)textOffset color:(NSColor *)color halfWidth:(BOOL)halfWidth andBezierPath:(NSBezierPath *)bezierPath channelHeight:(int)channelMultiples
{
    [self drawRectWithChannelIndex:index text:text textOffset:textOffset color:color halfWidth:halfWidth rightHalf:NO andBezierPath:bezierPath channelHeight:channelMultiples];
}

- (void)drawChannelWithIndex:(int)index text:(NSString *)text textOffset:(int)textOffset color:(NSColor *)color andBezierPath:(NSBezierPath *)bezierPath
{
    [self drawRectWithChannelIndex:index text:text textOffset:textOffset color:color halfWidth:YES rightHalf:YES andBezierPath:bezierPath channelHeight:1];
}

- (void)drawRectWithChannelIndex:(int)index text:(NSString *)text textOffset:(int)textOffset color:(NSColor *)color halfWidth:(BOOL)halfWidth rightHalf:(BOOL)rightHalf andBezierPath:(NSBezierPath *)bezierPath channelHeight:(int)channelMultiples
{
    [bezierPath moveToPoint:NSMakePoint((rightHalf ? self.bounds.size.width / 2 : 0), CHANNEL_HEIGHT * index)];
    [bezierPath lineToPoint:NSMakePoint((rightHalf ? self.bounds.size.width / 2 : 0), CHANNEL_HEIGHT * (index + channelMultiples))];
    [bezierPath lineToPoint:NSMakePoint(self.bounds.size.width / (halfWidth ? (rightHalf ? 1 : 2) : 1), CHANNEL_HEIGHT * (index + channelMultiples))];
    [bezierPath lineToPoint:NSMakePoint(self.bounds.size.width / (halfWidth ? (rightHalf ? 1 : 2) : 1), CHANNEL_HEIGHT * index)];
    [color set];
    [bezierPath fill];
    [[NSColor blackColor] set];
    [bezierPath stroke];
    if(![CoreDataManager sharedManager].currentSequence.audio)
    {
        NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Helvetica" size:CHANNEL_HEIGHT - 5], NSFontAttributeName, nil];
        NSRect textFrame = NSMakeRect(textOffset + (rightHalf ? self.bounds.size.width / 2 : 0), CHANNEL_HEIGHT * index, self.bounds.size.width / (halfWidth ? (rightHalf ? 1 : 2) : 1), CHANNEL_HEIGHT);
        [text drawInRect:textFrame withAttributes:attributes];
    }
}

@end
