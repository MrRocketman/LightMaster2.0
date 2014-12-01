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
    
}

- (BOOL)isFlipped
{
    return YES;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    // Calculate the frame
    /*int channelsCount = 1 + (int)[[[[CoreDataManager sharedManager].managedObjectContext ofType:@"Channel"] toArray] count] + (int)[[[[CoreDataManager sharedManager].managedObjectContext ofType:@"UserAudioAnalysisTrackChannel"] toArray] count] + (int)[CoreDataManager sharedManager].currentSequence.audio.userAudioAnalysis.tracks.count + ([CoreDataManager sharedManager].currentSequence.audio ? 1 : 0);
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
    }*/
    self.frame = NSMakeRect(0, 0, 10000, 1000);
    
    // clear the background
    [[NSColor greenColor] set];
    NSRectFill(self.bounds);
    
    // basic beat line
    NSBezierPath *basicBeatLine = [NSBezierPath bezierPath];
    
    int largestY = NSMaxY(self.bounds);
    for (int i = 0; i < largestY; i += 20)
    {
        NSPoint startPoint = NSMakePoint(NSMinX(self.bounds), i);
        NSPoint endPoint = NSMakePoint(NSMaxX(self.bounds), i);
        
        [basicBeatLine moveToPoint:startPoint];
        [basicBeatLine lineToPoint:endPoint];
    }
    
    [[NSColor whiteColor] set];
    [basicBeatLine setLineWidth:1.0];
    [basicBeatLine stroke];
    
    // basic beat line
    basicBeatLine = [NSBezierPath bezierPath];
    
    int largestX = NSMaxX(self.bounds);
    for (int i = 0; i < largestX; i += 10)
    {
        NSPoint startPoint = NSMakePoint(i, NSMinY(self.bounds));
        NSPoint endPoint = NSMakePoint(i, NSMaxY(self.bounds));
        
        [basicBeatLine moveToPoint:startPoint];
        [basicBeatLine lineToPoint:endPoint];
    }
    
    [[NSColor whiteColor] set];
    [basicBeatLine setLineWidth:1.0];
    [basicBeatLine stroke];
}

@end
