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

@end

@implementation SequenceHeaderView

- (void)setup
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sequenceChange:) name:@"CurrentSequenceChange" object:nil];
    
    [self fetchControlBoxAndChannelData];
}

- (void)sequenceChange:(NSNotification *)notification
{
    [self fetchControlBoxAndChannelData];
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
    
    self.frame = NSMakeRect(0, 0, self.frame.size.width, [[SequenceLogic sharedInstance] numberOfChannels] * CHANNEL_HEIGHT);
    
    // clear the background
    //[[NSColor lightGrayColor] set];
    //NSRectFill(self.bounds);
    
    [self drawHeaders];
    [self drawChannels];
}

- (void)drawHeaders
{
    int channelIndex = 0;
    
    // ControlBoxes
    for(ControlBox *box in self.controlBoxes)
    {
        [self drawControlBox:box withIndex:channelIndex];
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
            [self drawChannel:channels[channelIndex] withIndex:totalChannelIndex];
            totalChannelIndex ++;
        }
    }
}

#pragma mark - Helper Drawing Methods

- (void)drawControlBox:(ControlBox *)controlBox withIndex:(int)index
{
    //NSLog(@"color:%@", [NSColor grayColor]);
    [self drawRectWithChannelIndex:index text:controlBox.title textOffset:10 color:[NSColor grayColor] alpha:1.0 halfWidth:YES rightHalf:NO channelHeight:(int)controlBox.channels.count];
}

- (void)drawChannel:(Channel *)channel withIndex:(int)index
{
    NSColor *color = [channel.color colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    //NSColor *color = channel.color;
    NSLog(@"colorspace:%@", color.colorSpace);
    NSLog(@"color:%@", color);
    NSLog(@"red:%f", color.redComponent);
    [self drawRectWithChannelIndex:index text:channel.title textOffset:10 color:color alpha:[[CoreDataManager sharedManager] currentBrightnessForChannel:channel] halfWidth:YES rightHalf:YES channelHeight:1];
}

- (void)drawRectWithChannelIndex:(int)index text:(NSString *)text textOffset:(int)textOffset color:(NSColor *)color alpha:(float)alpha halfWidth:(BOOL)halfWidth rightHalf:(BOOL)rightHalf channelHeight:(int)channelMultiples
{
    //NSLog(@"color:%@", color);
    //NSLog(@"red:%f", color.redComponent);
    NSBezierPath *bezierPath = [NSBezierPath bezierPath];
    
    float topY = CHANNEL_HEIGHT * index;
    float bottomY = CHANNEL_HEIGHT * (index + channelMultiples);
    float leftX = (rightHalf ? self.bounds.size.width / 2 : 0);
    float rightX = self.bounds.size.width / (halfWidth ? (rightHalf ? 1 : 2) : 1);
    
    NSRect visibleRect = [(NSScrollView *)self.superview.superview documentVisibleRect];
    float visibleYSmall = visibleRect.origin.y - visibleRect.size.height / 2;
    float visibleYLarge = visibleRect.origin.y + visibleRect.size.height * 1.5;
    
    // Only draw if we are in the visiable range
    if((topY > visibleYSmall && topY < visibleYLarge) || (bottomY > visibleYSmall && bottomY < visibleYLarge))
    {
        // Draw the box
        [bezierPath moveToPoint:NSMakePoint(leftX, topY)];
        [bezierPath lineToPoint:NSMakePoint(leftX, bottomY)];
        [bezierPath lineToPoint:NSMakePoint(rightX, bottomY)];
        [bezierPath lineToPoint:NSMakePoint(rightX, topY)];
        [bezierPath lineToPoint:NSMakePoint(leftX, topY)];
        //NSLog(@"red:%f", color.redComponent);
        //[[NSColor colorWithRed:color.redComponent green:color.greenComponent blue:color.blueComponent alpha:alpha] set];
        [[color colorWithAlphaComponent:alpha] set];
        //[color set];
        [bezierPath fill];
        [[NSColor blackColor] set];
        [bezierPath stroke];
        
        // Draw the text
        NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Helvetica" size:CHANNEL_HEIGHT - 5], NSFontAttributeName, nil];
        NSRect textFrame = NSMakeRect(textOffset + leftX, topY, self.bounds.size.width / (halfWidth ? (rightHalf ? 1 : 2) : 1), CHANNEL_HEIGHT);
        [text drawInRect:textFrame withAttributes:attributes];
    }
}

@end
