//
//  SequenceView.m
//  LightMaster
//
//  Created by James Adams on 11/30/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import "SequenceView.h"
#import "CoreDataManager.h"
#import "NSManagedObjectContext+Queryable.h"
#import "Sequence.h"
#import "SequenceTatum.h"
#import "ControlBox.h"
#import "Channel.h"
#import "Audio.h"
#import "UserAudioAnalysis.h"
#import "UserAudioAnalysisTrack.h"
#import "UserAudioAnalysisTrackChannel.h"

@implementation SequenceView

- (void)awakeFromNib
{
    NSLog(@"awake x:%f y:%f w:%f y:%f", self.frame.origin.x, self.frame.origin.y, self.frame.size.width, self.frame.size.height);
}

- (BOOL)isFlipped
{
    return YES;
}

- (void)scrollViewBoundsChange:(NSNotification *)notification
{
    NSView *changedContentView = [notification object];
    NSPoint changedBoundsOrigin = [changedContentView bounds].origin;
    [self setBounds:NSMakeRect(changedBoundsOrigin.x - 30.0f, [self bounds].origin.y, [self bounds].size.width, [self bounds].size.height)];
    self.frame = NSMakeRect(0, 0, 10000, 1000);
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    // Calculate the frame
    int channelsCount = 1 + (int)[[[[CoreDataManager sharedManager].managedObjectContext ofType:@"Channel"] toArray] count] + (int)[[[[CoreDataManager sharedManager].managedObjectContext ofType:@"UserAudioAnalysisTrackChannel"] toArray] count] + (int)[CoreDataManager sharedManager].currentSequence.audio.userAudioAnalysis.tracks.count + ([CoreDataManager sharedManager].currentSequence.audio ? 1 : 0);
    int frameHeight = 0;
    int frameWidth = 5000;//[[CoreDataManager sharedManager] timeToX:[[CoreDataManager sharedManager].currentSequence.endTime floatValue]];
    // Set the Frame
    frameHeight = channelsCount * CHANNEL_HEIGHT;
    if(frameWidth <= self.superview.frame.size.width)
    {
        frameWidth = self.superview.frame.size.width;
    }
    if(frameHeight <= self.superview.frame.size.height)
    {
        frameHeight = self.superview.frame.size.height;
    }
    self.frame = NSMakeRect(0, 0, 10000, 1000);
    
    // clear the background
    [[NSColor greenColor] set];
    NSRectFill(dirtyRect);
}

@end
