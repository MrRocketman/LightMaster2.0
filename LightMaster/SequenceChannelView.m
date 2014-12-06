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
    //[[NSColor lightGrayColor] set];
    //NSRectFill(self.bounds);
    
    [self drawHeaders];
    [self drawChannels];
}

- (void)drawHeaders
{
    int channelIndex = 0;
    
    // ControlBoxes
    NSArray *controlBoxes = [[[[[CoreDataManager sharedManager].managedObjectContext ofType:@"ControlBox"] where:@"sequence CONTAINS %@", [CoreDataManager sharedManager].currentSequence] orderBy:@"idNumber"] toArray];
    for(ControlBox *box in controlBoxes)
    {
        NSBezierPath *controlBoxPath = [NSBezierPath bezierPath];
        [self drawHeaderWithChannelIndex:channelIndex text:box.title textOffset:10 color:[NSColor grayColor] halfWidth:YES andBezierPath:controlBoxPath channelHeight:(int)box.channels.count];
        channelIndex += (int)box.channels.count;
    }
}

- (void)drawChannels
{
    // Skip audio
    int channelIndex = 0;
    
    // ControlBoxes
    NSArray *controlBoxes = [[[[[CoreDataManager sharedManager].managedObjectContext ofType:@"ControlBox"] where:@"sequence CONTAINS %@", [CoreDataManager sharedManager].currentSequence] orderBy:@"idNumber"] toArray];
    NSArray *channels = [[[[[[CoreDataManager sharedManager].managedObjectContext ofType:@"Channel"] where:@"controlBox IN %@", controlBoxes] orderBy:@"controlBox.idNumber"] orderBy:@"idNumber"] toArray];
    for(Channel *channel in channels)
    {
        NSBezierPath *channelPath = [NSBezierPath bezierPath];
        [self drawChannelWithIndex:channelIndex text:channel.title textOffset:10 color:channel.color andBezierPath:channelPath];
        channelIndex ++;
    }
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
        [color set];
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
