//
//  SequenceHeaderView.m
//  LightMaster
//
//  Created by James Adams on 12/9/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import "SequenceHeaderView.h"
#import "SequenceLogic.h"
#import "CoreDataManager.h"
#import "NSManagedObjectContext+Queryable.h"
#import "Channel.h"
#import "ControlBox.h"

@interface SequenceHeaderView()

@property (strong, nonatomic) NSArray *controlBoxes;
@property (strong, nonatomic) NSMutableArray *channels;
@property (assign, nonatomic) NSRect dirtyRect;
@property (assign, nonatomic) int dirtyRectTopChannel;
@property (assign, nonatomic) int dirtyRectBottomChannel;

@end

@implementation SequenceHeaderView

- (void)setup
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sequenceChange:) name:@"CurrentSequenceChange" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(update:) name:@"UpdateDimmingDisplay" object:nil];
    
    [self fetchControlBoxAndChannelData];
}

- (void)sequenceChange:(NSNotification *)notification
{
    [self fetchControlBoxAndChannelData];
    [self setNeedsDisplay:YES];
}

- (void)update:(NSNotification *)notification
{
    [self setNeedsDisplay:YES];
}

- (BOOL)isFlipped
{
    return YES;
}

- (void)fetchControlBoxAndChannelData
{
    // Fetch controlBoxes
    if(self.isAudioAnalysisView)
    {
        // Analysis ControlBoxes
        self.controlBoxes = [[[[[CoreDataManager sharedManager].managedObjectContext ofType:@"ControlBox"] where:@"analysisSequence == %@", [CoreDataManager sharedManager].currentSequence] orderBy:@"idNumber"] toArray];
    }
    else
    {
        // ControlBoxes
        self.controlBoxes = [[[[[CoreDataManager sharedManager].managedObjectContext ofType:@"ControlBox"] where:@"sequence CONTAINS %@", [CoreDataManager sharedManager].currentSequence] orderBy:@"idNumber"] toArray];
    }
    
    self.channels = nil;
    self.channels = [NSMutableArray new];
    // Fetch channels
    for(ControlBox *controlBox in self.controlBoxes)
    {
        [self.channels addObject:[[[[[CoreDataManager sharedManager].managedObjectContext ofType:@"Channel"] where:@"controlBox == %@", controlBox] orderBy:@"idNumber"] toArray]];
    }
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    self.dirtyRect = dirtyRect;
    self.dirtyRectTopChannel = dirtyRect.origin.y / CHANNEL_HEIGHT;
    self.dirtyRectBottomChannel = (dirtyRect.origin.y + dirtyRect.size.height) / CHANNEL_HEIGHT;
    
    self.frame = NSMakeRect(0, 0, self.frame.size.width, [[SequenceLogic sharedInstance] numberOfChannels] * CHANNEL_HEIGHT);
    
    // clear the background
    [[NSColor blackColor] set];
    NSRectFill(self.bounds);
    
    [self drawHeaders];
    [self drawChannels];
}

#pragma mark - Drawing Methods

- (void)drawHeaders
{
    int channelIndex = 0;
    
    // ControlBoxes
    for(ControlBox *box in self.controlBoxes)
    {
        int bottomChannelIndex = channelIndex + (int)box.channels.count;
        // Only draw the boxes that need redrawing
        if((channelIndex >= self.dirtyRectTopChannel && channelIndex <= self.dirtyRectBottomChannel) || (bottomChannelIndex >= self.dirtyRectTopChannel && bottomChannelIndex <= self.dirtyRectBottomChannel))
        {
            [self drawRectWithChannelIndex:channelIndex text:box.title textOffset:10 color:[NSColor grayColor] halfWidth:YES rightHalf:NO channelHeight:(int)box.channels.count];
        }
        
        channelIndex += (int)box.channels.count;
    }
}

- (void)drawChannels
{
    int totalChannelIndex = 0;
    
    // Channels
    for(int controlBoxIndex = 0; controlBoxIndex < self.controlBoxes.count; controlBoxIndex ++)
    {
        NSArray *channels = self.channels[controlBoxIndex];
        for(int channelIndex = 0; channelIndex < channels.count; channelIndex ++)
        {
            // Only draw the channels that need redrawing
            if(totalChannelIndex >= self.dirtyRectTopChannel && totalChannelIndex <= self.dirtyRectBottomChannel)
            {
                Channel *channel = channels[channelIndex];
                [self drawRectWithChannelIndex:totalChannelIndex text:channel.title textOffset:10 color:[channel.color colorWithAlphaComponent:[[SequenceLogic sharedInstance] currentBrightnessForChannel:channel]] halfWidth:YES rightHalf:YES channelHeight:1];
            }
            
            totalChannelIndex ++;
        }
    }
}

- (void)drawRectWithChannelIndex:(int)index text:(NSString *)text textOffset:(int)textOffset color:(NSColor *)color halfWidth:(BOOL)halfWidth rightHalf:(BOOL)rightHalf channelHeight:(int)channelMultiples
{
    NSBezierPath *bezierPath = [NSBezierPath bezierPath];
    
    float topY = CHANNEL_HEIGHT * index;
    float bottomY = CHANNEL_HEIGHT * (index + channelMultiples);
    float leftX = (rightHalf ? self.bounds.size.width / 2 : 0);
    float rightX = self.bounds.size.width / (halfWidth ? (rightHalf ? 1 : 2) : 1);
    
    // Draw the box
    [bezierPath moveToPoint:NSMakePoint(leftX, topY)];
    [bezierPath lineToPoint:NSMakePoint(leftX, bottomY)];
    [bezierPath lineToPoint:NSMakePoint(rightX, bottomY)];
    [bezierPath lineToPoint:NSMakePoint(rightX, topY)];
    [bezierPath lineToPoint:NSMakePoint(leftX, topY)];
    [color set];
    [bezierPath fill];
    [[NSColor blackColor] set];
    [bezierPath stroke];
    
    // Draw the text
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Helvetica" size:CHANNEL_HEIGHT - 5], NSFontAttributeName, nil];
    NSRect textFrame = NSMakeRect(textOffset + leftX, topY, self.bounds.size.width / (halfWidth ? (rightHalf ? 1 : 2) : 1), CHANNEL_HEIGHT);
    [text drawInRect:textFrame withAttributes:attributes];
}

@end
