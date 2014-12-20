//
//  SequenceDataView.m
//  LightMaster
//
//  Created by James Adams on 12/5/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import "SequenceDataView.h"
#import "SequenceLogic.h"
#import "CoreDataManager.h"
#import "NSManagedObjectContext+Queryable.h"
#import "Sequence.h"
#import "SequenceTatum.h"
#import "CommandOn.h"
#import "CommandFade.h"
#import "ControlBox.h"
#import "Channel.h"

@interface SequenceDataView()

@property (strong, nonatomic) NSBezierPath *sequenceTatumPaths;
@property (assign, nonatomic) NSPoint currentMousePoint;
@property (strong, nonatomic) NSEvent *mouseEvent;
@property (strong, nonatomic) NSTimer *autoScrollTimer;
@property (strong, nonatomic) NSTrackingArea *trackingArea;

@property (assign, nonatomic) BOOL sequenceTatumIsSelected;
@property (strong, nonatomic) SequenceTatum *selectedSequenceTatum;

@property (strong, nonatomic) SequenceTatum *mouseBoxSelectOriginalStartTatum;
@property (assign, nonatomic) int mouseBoxSelectTopChannel;
@property (assign, nonatomic) int mouseBoxSelectOriginalTopChannel;
@property (assign, nonatomic) int mouseBoxSelectBottomChannel;
@property (assign, nonatomic) BOOL mouseGroupSelect;
@property (assign, nonatomic) BOOL retainMouseGroupSelect;

@property (assign, nonatomic) BOOL shiftKey;
@property (assign, nonatomic) BOOL commandKey;
@property (assign, nonatomic) BOOL optionKey;
@property (assign, nonatomic) BOOL newTatum;
@property (assign, nonatomic) float newCommandBrightness;

@property (strong, nonatomic) NSArray *controlBoxes;
@property (strong, nonatomic) NSMutableArray *channels;

@property (assign, nonatomic) float dirtyRectLeftTime;
@property (assign, nonatomic) float dirtyRectRightTime;
@property (assign, nonatomic) int dirtyRectTopChannel;
@property (assign, nonatomic) int dirtyRectBottomChannel;
@property (assign, nonatomic) NSRect dirtyRect;

@end

@implementation SequenceDataView

- (void)setup
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sequenceChange:) name:@"CurrentSequenceChange" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deselectMouse:) name:@"DeselectMouse" object:nil];
    
    self.newCommandBrightness = 1.0;
    
    if(![CoreDataManager sharedManager].currentSequence)
    {
        [[CoreDataManager sharedManager] getLatestOrCreateNewSequence];
    }
    [self fetchControlBoxAndChannelData];
}

- (void)sequenceChange:(NSNotification *)notification
{
    [self fetchControlBoxAndChannelData];
    [self setNeedsDisplay:YES];
}

- (void)deselectMouse:(NSNotification *)notification
{
    self.mouseGroupSelect = NO;
    self.retainMouseGroupSelect = NO;
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

#pragma mark - Drawing

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    // Get the bounds of where we should be drawing
    self.dirtyRect = dirtyRect;
    self.dirtyRectLeftTime = [[SequenceLogic sharedInstance] xToTime:dirtyRect.origin.x];
    self.dirtyRectRightTime = [[SequenceLogic sharedInstance] xToTime:dirtyRect.origin.x + dirtyRect.size.width];
    self.dirtyRectTopChannel = dirtyRect.origin.y / CHANNEL_HEIGHT;
    self.dirtyRectBottomChannel = (dirtyRect.origin.y + dirtyRect.size.height) / CHANNEL_HEIGHT;
    
    if(self.isAudioAnalysisView)
    {
        self.frame = NSMakeRect(0, 0, [[SequenceLogic sharedInstance] timeToX:[[CoreDataManager sharedManager].currentSequence.endTime floatValue] + 1.0], [[SequenceLogic sharedInstance] numberOfAudioChannels] * CHANNEL_HEIGHT);
    }
    else
    {
        self.frame = NSMakeRect(0, 0, [[SequenceLogic sharedInstance] timeToX:[[CoreDataManager sharedManager].currentSequence.endTime floatValue] + 1.0], [[SequenceLogic sharedInstance] numberOfChannels] * CHANNEL_HEIGHT);
    }
    
    if(self.trackingArea)
    {
        [self removeTrackingArea:self.trackingArea];
    }
    self.trackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds] options:(NSTrackingActiveAlways | NSTrackingInVisibleRect | NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved) owner:self userInfo:nil];
    [self addTrackingArea:self.trackingArea];
    
    // clear the background
    [[NSColor blackColor] set];
    NSRectFill(dirtyRect);
    
    // Draw commands
    [self drawCommands];
    
    // Draw channel seperators
    [self drawChannelLines];
    
    // Draw Sequence Tatums
    [self drawSequenceTatums];
    
    // Draw mouse selection box
    [self drawMouseGroupSelectionBox];
}

- (void)drawCommands
{
    // Draw each channel
    int channelIndex = 0;
    for(NSArray *channels in self.channels)
    {
        for(Channel *channel in channels)
        {
            // Only draw the channel if it needs to be
            if(channelIndex >= self.dirtyRectTopChannel && channelIndex <= self.dirtyRectBottomChannel)
            {
                NSBezierPath *channelPath = [NSBezierPath bezierPath];
                
                // Add the commands
                for(Command *theCommand in channel.commands)
                {
                    // Only add this commands if it's for this sequence and needs to be drawn
                    float startTime = [theCommand.startTatum.time floatValue];
                    float endTime = [theCommand.endTatum.time floatValue];
                    if(theCommand.sequence == [CoreDataManager sharedManager].currentSequence && ((startTime >= self.dirtyRectLeftTime && startTime <= self.dirtyRectRightTime) || (endTime >= self.dirtyRectLeftTime && endTime <= self.dirtyRectRightTime) || (startTime < self.dirtyRectLeftTime && endTime > self.dirtyRectRightTime)))
                    {
                        // Add the command
                        if([theCommand isMemberOfClass:[CommandOn class]])
                        {
                            CommandOn *command = (CommandOn *)theCommand;
                            float leftX = [[SequenceLogic sharedInstance] timeToX:[command.startTatum.time floatValue]];
                            float rightX = [[SequenceLogic sharedInstance] timeToX:[command.endTatum.time floatValue]];
                            float topY = channelIndex * CHANNEL_HEIGHT + (CHANNEL_HEIGHT * (1.0 - [command.brightness floatValue]));
                            float bottomY = (channelIndex + 1) * CHANNEL_HEIGHT - 1;
                            [channelPath moveToPoint:NSMakePoint(leftX, topY)];
                            [channelPath lineToPoint:NSMakePoint(leftX, bottomY)];
                            [channelPath lineToPoint:NSMakePoint(rightX, bottomY)];
                            [channelPath lineToPoint:NSMakePoint(rightX, topY)];
                            [channelPath lineToPoint:NSMakePoint(leftX, topY)];
                        }
                        else if([theCommand isMemberOfClass:[CommandFade class]])
                        {
                            CommandFade *command = (CommandFade *)theCommand;
                            float leftX = [[SequenceLogic sharedInstance] timeToX:[command.startTatum.time floatValue]];
                            float rightX = [[SequenceLogic sharedInstance] timeToX:[command.endTatum.time floatValue]];
                            float modifiedStartBrightness = ([command.startBrightness floatValue] > 0.1 ? (1.0 - [command.startBrightness floatValue]) : (0.9 - [command.startBrightness floatValue]));
                            float modifiedEndBrightness = ([command.endBrightness floatValue] > 0.1 ? (1.0 - [command.endBrightness floatValue]) : (0.9 - [command.endBrightness floatValue]));
                            float leftY = channelIndex * CHANNEL_HEIGHT + (CHANNEL_HEIGHT * modifiedStartBrightness);
                            float rightY = channelIndex * CHANNEL_HEIGHT + (CHANNEL_HEIGHT * modifiedEndBrightness);
                            float bottomY = (channelIndex + 1) * CHANNEL_HEIGHT - 1;
                            [channelPath moveToPoint:NSMakePoint(leftX, leftY)];
                            [channelPath lineToPoint:NSMakePoint(leftX, bottomY)];
                            [channelPath lineToPoint:NSMakePoint(rightX, bottomY)];
                            [channelPath lineToPoint:NSMakePoint(rightX, rightY)];
                            [channelPath lineToPoint:NSMakePoint(leftX, leftY)];
                        }
                    }
                }
                
                [(NSColor *)channel.color set];
                [channelPath fill];
            }
            
            channelIndex ++;
        }
    }
}

- (void)drawChannelLines
{
    NSBezierPath *linesPath = [NSBezierPath bezierPath];
    
    // Draw each channel line
    int channelIndex = 0;
    for(NSArray *channels in self.channels)
    {
        for(int i = 0; i < channels.count; i ++)
        {
            // Only draw the line if it needs to be
            if(channelIndex >= self.dirtyRectTopChannel && channelIndex <= self.dirtyRectBottomChannel)
            {
                NSPoint startPoint = NSMakePoint(self.dirtyRect.origin.x, channelIndex * CHANNEL_HEIGHT);
                NSPoint endPoint = NSMakePoint(self.dirtyRect.origin.x + self.dirtyRect.size.width, channelIndex * CHANNEL_HEIGHT);
                
                [linesPath moveToPoint:startPoint];
                [linesPath lineToPoint:endPoint];
            }
            
            channelIndex ++;
        }
    }
    
    [[NSColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1.0] set];
    [linesPath setLineWidth:1.0];
    [linesPath stroke];
}

- (void)drawSequenceTatums
{
    NSArray *tatums = [[[[[CoreDataManager sharedManager].managedObjectContext ofType:@"SequenceTatum"] where:@"sequence == %@", [CoreDataManager sharedManager].currentSequence] orderBy:@"time"] toArray];
    
    self.sequenceTatumPaths = [NSBezierPath bezierPath];
    for(int i = 0; i < tatums.count; i ++)
    {
        SequenceTatum *tatum = (SequenceTatum *)tatums[i];
        
        // Update the tatum position if it's selected
        if(self.sequenceTatumIsSelected && self.selectedSequenceTatum == tatum)
        {
            if(self.optionKey && !self.newTatum)
            {
                [[[CoreDataManager sharedManager] managedObjectContext] deleteObject:tatum];
            }
            else
            {
                tatum.time = @([[SequenceLogic sharedInstance] xToTime:self.currentMousePoint.x]);
                NSBezierPath *selectedTatumPath = [NSBezierPath bezierPath];
                [self addSequenceTatumWithTime:[tatum.time floatValue] toBezierPath:selectedTatumPath];
                [[NSColor yellowColor] set];
                [selectedTatumPath fill];
            }
            
            // Tell any other views to update
            [[NSNotificationCenter defaultCenter] postNotificationName:@"SequenceTatumChange" object:nil];
        }
        else
        {
            // Draw the normal sequence Tatums
            NSPoint startPoint = [self addSequenceTatumWithTime:[tatum.time floatValue] toBezierPath:self.sequenceTatumPaths];
            
            // Select a sequenceTatum
            if(self.sequenceTatumIsSelected && !self.selectedSequenceTatum && self.currentMousePoint.x >= startPoint.x - 1 && self.currentMousePoint.x <= startPoint.x + 1)
            {
                self.selectedSequenceTatum = tatum;
            }
            
            // Start a mouse group select
            if(self.mouseGroupSelect)
            {
                SequenceTatum *nextTatum;
                float tatumX, nextTatumX;
                if(i < tatums.count - 1)
                {
                    nextTatum = (SequenceTatum *)tatums[i + 1];
                }
                else
                {
                    nextTatum = tatum;
                }
                tatumX = [[SequenceLogic sharedInstance] timeToX:[tatum.time floatValue]];
                nextTatumX = [[SequenceLogic sharedInstance] timeToX:[nextTatum.time floatValue]];
                
                if(self.currentMousePoint.x >= tatumX && self.currentMousePoint.x < nextTatumX)
                {
                    // Initial click
                    if(![SequenceLogic sharedInstance].mouseBoxSelectStartTatum)
                    {
                        [SequenceLogic sharedInstance].mouseBoxSelectStartTatum = tatum;
                        [SequenceLogic sharedInstance].mouseBoxSelectEndTatum = nextTatum;
                        self.mouseBoxSelectOriginalStartTatum = [SequenceLogic sharedInstance].mouseBoxSelectStartTatum;
                        self.mouseBoxSelectTopChannel = ((int)(self.currentMousePoint.y / CHANNEL_HEIGHT));
                        self.mouseBoxSelectOriginalTopChannel = self.mouseBoxSelectTopChannel;
                        self.mouseBoxSelectBottomChannel = self.mouseBoxSelectTopChannel + 1;
                    }
                    // Dragging update
                    else
                    {
                        // Left and right checking
                        if([nextTatum.time floatValue] > [self.mouseBoxSelectOriginalStartTatum.time floatValue])
                        {
                            [SequenceLogic sharedInstance].mouseBoxSelectEndTatum = nextTatum;
                            if(self.mouseBoxSelectOriginalStartTatum != [SequenceLogic sharedInstance].mouseBoxSelectStartTatum)
                            {
                                [SequenceLogic sharedInstance].mouseBoxSelectStartTatum = self.mouseBoxSelectOriginalStartTatum;
                            }
                        }
                        else
                        {
                            [SequenceLogic sharedInstance].mouseBoxSelectStartTatum = tatum;
                        }
                        
                        // Up and down checking
                        if(self.currentMousePoint.y / CHANNEL_HEIGHT > self.mouseBoxSelectOriginalTopChannel)
                        {
                            self.mouseBoxSelectBottomChannel = (int)((self.currentMousePoint.y > self.frame.size.height ? self.frame.size.height / CHANNEL_HEIGHT : self.currentMousePoint.y / CHANNEL_HEIGHT + 1));
                            if(self.mouseBoxSelectOriginalTopChannel != self.mouseBoxSelectTopChannel)
                            {
                                self.mouseBoxSelectTopChannel = self.mouseBoxSelectOriginalTopChannel;
                            }
                        }
                        else
                        {
                            self.mouseBoxSelectTopChannel = (int)((self.currentMousePoint.y < 0 ? 0 : self.currentMousePoint.y / CHANNEL_HEIGHT));
                        }
                    }
                }
            }
        }
    }
    
    [[NSColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1.0] set];
    [self.sequenceTatumPaths fill];
}

- (NSPoint)addSequenceTatumWithTime:(float)time toBezierPath:(NSBezierPath *)path
{
    if(time >= self.dirtyRectLeftTime && time <= self.dirtyRectRightTime)
    {
        NSPoint startPoint = NSMakePoint([[SequenceLogic sharedInstance] timeToX:time], self.dirtyRect.origin.y);
        NSPoint endPoint = NSMakePoint(startPoint.x, self.dirtyRect.origin.y + self.dirtyRect.size.height);
        
        [path moveToPoint:NSMakePoint(startPoint.x - 1, startPoint.y)];
        [path lineToPoint:NSMakePoint(endPoint.x - 1, endPoint.y)];
        [path lineToPoint:NSMakePoint(endPoint.x + 1, endPoint.y)];
        [path lineToPoint:NSMakePoint(startPoint.x + 1, startPoint.y)];
        
        return startPoint;
    }
    
    return NSZeroPoint;
}

- (void)drawMouseGroupSelectionBox
{
    if((self.mouseGroupSelect || self.retainMouseGroupSelect) && [SequenceLogic sharedInstance].mouseBoxSelectStartTatum)
    {
        float leftX = [[SequenceLogic sharedInstance] timeToX:[[SequenceLogic sharedInstance].mouseBoxSelectStartTatum.time floatValue]];
        float rightX = [[SequenceLogic sharedInstance] timeToX:[[SequenceLogic sharedInstance].mouseBoxSelectEndTatum.time floatValue]];
        float topY = self.mouseBoxSelectTopChannel * CHANNEL_HEIGHT;
        float bottomY = self.mouseBoxSelectBottomChannel * CHANNEL_HEIGHT;
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(leftX, topY)];
        [path lineToPoint:NSMakePoint(leftX, bottomY)];
        [path lineToPoint:NSMakePoint(rightX, bottomY)];
        [path lineToPoint:NSMakePoint(rightX, topY)];
        [path lineToPoint:NSMakePoint(leftX, topY)];
        
        [[NSColor redColor] set];
        [path setLineWidth:3.0];
        [path stroke];
    }
}

#pragma mark Mouse Methods

- (void)rightMouseDown:(NSEvent*)theEvent
{
    // !!!: Add/delete/redo sequence tatums
}

- (void)mouseDown:(NSEvent *)theEvent
{
    NSPoint eventLocation = [theEvent locationInWindow];
    self.currentMousePoint = [self convertPoint:eventLocation fromView:nil];
    
    // clicking a tatum
    if([self.sequenceTatumPaths containsPoint:self.currentMousePoint])
    {
        // Select tatum
        self.sequenceTatumIsSelected = YES;
    }
    else
    {
        // new/delete tatum
        if(self.optionKey)
        {
            [[CoreDataManager sharedManager] addSequenceTatumToSequence:[CoreDataManager sharedManager].currentSequence atTime:[[SequenceLogic sharedInstance] xToTime:self.currentMousePoint.x]];
            [[CoreDataManager sharedManager] saveContext];
            self.sequenceTatumIsSelected = YES;
            self.newTatum = YES;
        }
        // start new box select
        else
        {
            // deselect shift drag selection
            if(self.retainMouseGroupSelect)
            {
                self.mouseGroupSelect = NO;
                self.retainMouseGroupSelect = NO;
            }
            else
            {
                self.mouseGroupSelect = YES;
                // retain the selection in select mode
                if([SequenceLogic sharedInstance].commandType == CommandTypeSelect)
                {
                    self.retainMouseGroupSelect = YES;
                }
                [SequenceLogic sharedInstance].mouseBoxSelectStartTatum = nil;
                [SequenceLogic sharedInstance].mouseBoxSelectEndTatum = nil;
            }
        }
    }
    
    [self setNeedsDisplay:YES];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    NSPoint eventLocation = [theEvent locationInWindow];
    self.currentMousePoint = [self convertPoint:eventLocation fromView:nil];
    self.mouseEvent = theEvent;
    
    if(self.autoScrollTimer == nil)
    {
        [self.autoScrollTimer invalidate];
        self.autoScrollTimer = nil;
        self.autoScrollTimer = [NSTimer scheduledTimerWithTimeInterval:AUTO_SCROLL_REFRESH_RATE target:self selector:@selector(autoScroll:) userInfo:nil repeats:YES];
    }
    
    [self setNeedsDisplay:YES];
}

- (void)mouseUp:(NSEvent *)theEvent
{
    if(self.sequenceTatumIsSelected)
    {
        self.sequenceTatumIsSelected = NO;
        self.selectedSequenceTatum = nil;
        // Save the sequenceTatum time change
        [[CoreDataManager sharedManager] saveContext];
    }
    else if(self.mouseGroupSelect)
    {
        self.mouseGroupSelect = NO;
        
        // If this is a create command click, add the command
        if(!self.retainMouseGroupSelect)
        {
            [self addCommandsForMouseGroupSelect];
        }
    }
    
    [self.autoScrollTimer invalidate];
    self.autoScrollTimer = nil;
    
    [self setNeedsDisplay:YES];
}

- (void)mouseMoved:(NSEvent *)theEvent
{
    NSPoint eventLocation = [theEvent locationInWindow];
    NSPoint currentMousePoint = [self convertPoint:eventLocation fromView:nil];
    
    if([self.sequenceTatumPaths containsPoint:currentMousePoint])
    {
        [[NSCursor resizeLeftRightCursor] set];
    }
    else
    {
        [[NSCursor arrowCursor] set];
    }
}

- (void)autoScroll:(NSTimer *)theTimer;
{
    [self autoscroll:self.mouseEvent];
}

#pragma mark - Keyboard Methods

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (void)flagsChanged:(NSEvent *)event
{
    self.shiftKey = ([event modifierFlags] & NSShiftKeyMask ? YES : NO);
    self.commandKey = ([event modifierFlags] & NSCommandKeyMask ? YES : NO);
    self.optionKey = ([event modifierFlags] & NSAlternateKeyMask ? YES : NO);
    if(!self.optionKey)
    {
        self.newTatum = NO;
    }
}

- (void)keyDown:(NSEvent *)keyboardEvent
{
    // Check for new command clicks
    if(!keyboardEvent.isARepeat)
    {
        if(keyboardEvent.keyCode == 18 || keyboardEvent.keyCode == 83) // '1'
        {
            self.newCommandBrightness = 0.1;
        }
        else if(keyboardEvent.keyCode == 19 || keyboardEvent.keyCode == 84) // '2'
        {
            self.newCommandBrightness = 0.2;
            if(self.optionKey)
            {
                [self subdivideTatums:1];
            }
        }
        else if(keyboardEvent.keyCode == 20 || keyboardEvent.keyCode == 85) // '3'
        {
            self.newCommandBrightness = 0.3;
            if(self.optionKey)
            {
                [self subdivideTatums:2];
            }
        }
        else if(keyboardEvent.keyCode == 21 || keyboardEvent.keyCode == 86) // '4'
        {
            self.newCommandBrightness = 0.4;
            if(self.optionKey)
            {
                [self subdivideTatums:3];
            }
        }
        else if(keyboardEvent.keyCode == 23 || keyboardEvent.keyCode == 87) // '5'
        {
            self.newCommandBrightness = 0.5;
            if(self.optionKey)
            {
                [self subdivideTatums:4];
            }
        }
        else if(keyboardEvent.keyCode == 22 || keyboardEvent.keyCode == 88) // '6'
        {
            self.newCommandBrightness = 0.6;
            if(self.optionKey)
            {
                [self subdivideTatums:5];
            }
        }
        else if(keyboardEvent.keyCode == 26 || keyboardEvent.keyCode == 89) // '7'
        {
            self.newCommandBrightness = 0.7;
            if(self.optionKey)
            {
                [self subdivideTatums:6];
            }
        }
        else if(keyboardEvent.keyCode == 28 || keyboardEvent.keyCode == 91) // '8'
        {
            self.newCommandBrightness = 0.8;
            if(self.optionKey)
            {
                [self subdivideTatums:7];
            }
        }
        else if(keyboardEvent.keyCode == 25 || keyboardEvent.keyCode == 92) // '9'
        {
            self.newCommandBrightness = 0.9;
            if(self.optionKey)
            {
                [self subdivideTatums:8];
            }
        }
        else if(keyboardEvent.keyCode == 51) // 'delete'
        {
            if(self.retainMouseGroupSelect)
            {
                [self deleteCommandsForSelection];
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ChangeCommandType" object:nil];
        }
        else if(keyboardEvent.keyCode == 49) // 'space'
        {
            if(self.optionKey)
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"PlayPauseFromCurrentTime" object:nil];
            }
            else if(self.retainMouseGroupSelect)
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"PlayPauseSelection" object:nil];
            }
            else
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"PlayPause" object:nil];
            }
        }
        else if(keyboardEvent.keyCode == 1) // 's'
        {
            // select mode
            [SequenceLogic sharedInstance].commandType = CommandTypeSelect;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ChangeCommandType" object:nil];
        }
        else if(keyboardEvent.keyCode == 31) // 'o'
        {
            // command on
            int previousCommandType = [SequenceLogic sharedInstance].commandType;
            [SequenceLogic sharedInstance].commandType = CommandTypeOn;
            [self addCommandsForMouseGroupSelect];
            [SequenceLogic sharedInstance].commandType = previousCommandType;
            self.retainMouseGroupSelect = NO;
            
            //[[NSNotificationCenter defaultCenter] postNotificationName:@"ChangeCommandType" object:nil];
        }
        else if(keyboardEvent.keyCode == 32) // 'u'
        {
            // fade up
            int previousCommandType = [SequenceLogic sharedInstance].commandType;
            [SequenceLogic sharedInstance].commandType = CommandTypeUp;
            [self addCommandsForMouseGroupSelect];
            [SequenceLogic sharedInstance].commandType = previousCommandType;
            self.retainMouseGroupSelect = NO;
            
            //[[NSNotificationCenter defaultCenter] postNotificationName:@"ChangeCommandType" object:nil];
        }
        else if(keyboardEvent.keyCode == 2) // 'd'
        {
            // fade down
            int previousCommandType = [SequenceLogic sharedInstance].commandType;
            [SequenceLogic sharedInstance].commandType = CommandTypeDown;
            [self addCommandsForMouseGroupSelect];
            [SequenceLogic sharedInstance].commandType = previousCommandType;
            self.retainMouseGroupSelect = NO;
            
            //[[NSNotificationCenter defaultCenter] postNotificationName:@"ChangeCommandType" object:nil];
        }
        else if(keyboardEvent.keyCode == 17) // 't'
        {
            // twinkle
            int previousCommandType = [SequenceLogic sharedInstance].commandType;
            [SequenceLogic sharedInstance].commandType = CommandTypeTwinkle;
            [self addCommandsForMouseGroupSelect];
            [SequenceLogic sharedInstance].commandType = previousCommandType;
            self.retainMouseGroupSelect = NO;
            
            //[[NSNotificationCenter defaultCenter] postNotificationName:@"ChangeCommandType" object:nil];
        }
        else if(keyboardEvent.keyCode == 35) // 'p'
        {
            // pulse
            int previousCommandType = [SequenceLogic sharedInstance].commandType;
            [SequenceLogic sharedInstance].commandType = CommandTypePulse;
            [self addCommandsForMouseGroupSelect];
            [SequenceLogic sharedInstance].commandType = previousCommandType;
            self.retainMouseGroupSelect = NO;
            
            //[[NSNotificationCenter defaultCenter] postNotificationName:@"ChangeCommandType" object:nil];
        }
        else if(keyboardEvent.keyCode == 8 && self.commandKey && self.retainMouseGroupSelect) // 'c'
        {
            // Copy data
            [SequenceLogic sharedInstance].startTatumForCopy = [SequenceLogic sharedInstance].mouseBoxSelectStartTatum;
            [SequenceLogic sharedInstance].endTatumForCopy = [SequenceLogic sharedInstance].mouseBoxSelectEndTatum;
            [SequenceLogic sharedInstance].topChannelForCopy = self.mouseBoxSelectTopChannel;
            [SequenceLogic sharedInstance].bottomChannelForCopy = self.mouseBoxSelectBottomChannel;
            
            // Store the commands to copy (so they can be pasted to the audioAnalysis section if wanted)
            NSMutableArray *commandArraysToCopy = [NSMutableArray new];
            int i = 0;
            const float epsilon = 0.001;
            float copyStartTime = [[SequenceLogic sharedInstance].startTatumForCopy.time floatValue];
            float copyEndTime = [[SequenceLogic sharedInstance].endTatumForCopy.time floatValue];
            for(NSArray *channels in self.channels)
            {
                for(Channel *channel in channels)
                {
                    // Only use the selected channels
                    if(i >= [SequenceLogic sharedInstance].topChannelForCopy && i < [SequenceLogic sharedInstance].bottomChannelForCopy)
                    {
                        NSArray *commandsToCopy = [[[[CoreDataManager sharedManager].managedObjectContext ofType:@"Command"] where:@"sequence == %@ AND channel == %@ AND startTatum.time > %f AND endTatum.time < %f", [CoreDataManager sharedManager].currentSequence, channel, copyStartTime - epsilon, copyEndTime + epsilon] toArray];
                        [commandArraysToCopy addObject:commandsToCopy];
                    }
                    
                    // Increment our channel counter
                    i ++;
                }
            }
            [SequenceLogic sharedInstance].commandArraysToCopy = (NSArray *)commandArraysToCopy;
        }
        else if(keyboardEvent.keyCode == 9 && self.commandKey && self.retainMouseGroupSelect && [SequenceLogic sharedInstance].startTatumForCopy) // 'v'
        {
            if(self.optionKey)
            {
                [self pasteDataWithPasteEpsilon:0.2];
            }
            else if(self.shiftKey)
            {
                [self pasteDataToExistingTatums];
            }
            else
            {
                [self pasteDataWithPasteEpsilon:0.05];
            }
            
            
            self.retainMouseGroupSelect = NO;
            [[CoreDataManager sharedManager] saveContext];
            [self setNeedsDisplay:YES];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"SequenceTatumChange" object:nil];
        }
        else
        {
            [super keyDown:keyboardEvent];
        }
    }
}

- (void)keyUp:(NSEvent *)keyboardEvent
{
    self.newCommandBrightness = 1.0;
    
    [super keyUp:keyboardEvent];
}

#pragma mark Logic

- (void)subdivideTatums:(int)count
{
    if(self.retainMouseGroupSelect)
    {
        float startTime = [[SequenceLogic sharedInstance].mouseBoxSelectStartTatum.time floatValue];
        float endTime = [[SequenceLogic sharedInstance].mouseBoxSelectEndTatum.time floatValue];
        float interval = (endTime - startTime) / (count + 1);
        
        for(float i = 1; i <= count; i ++)
        {
            SequenceTatum *newTatum = [NSEntityDescription insertNewObjectForEntityForName:@"SequenceTatum" inManagedObjectContext:[CoreDataManager sharedManager].managedObjectContext];
            newTatum.time = @(startTime + i * interval);
            newTatum.sequence = [CoreDataManager sharedManager].currentSequence;
        }
        
        [[CoreDataManager sharedManager] saveContext];
        [self setNeedsDisplay:YES];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SequenceTatumChange" object:nil];
    }
}

- (void)addCommandsForMouseGroupSelect
{
    int currentMouseIndex = self.mouseBoxSelectTopChannel;
    while(currentMouseIndex < self.mouseBoxSelectBottomChannel)
    {
        // Figure out which control box
        int channelCount = 0;
        int controlBoxIndex = 0;
        for(int i = 0; i < self.controlBoxes.count; i ++)
        {
            ControlBox *controlBox = self.controlBoxes[i];
            
            if(currentMouseIndex > controlBox.channels.count - 1 + channelCount)
            {
                channelCount += controlBox.channels.count;
            }
            else
            {
                controlBoxIndex = i;
                break;
            }
        }
        // Figure out which channel
        NSArray *channels = self.channels[controlBoxIndex];
        Channel *channel = channels[currentMouseIndex - channelCount];
        
        // Add the appropriate command
        if([SequenceLogic sharedInstance].commandType == CommandTypeOn)
        {
            // Add the command on
            [[SequenceLogic sharedInstance] addCommandForChannel:channel startTatum:[SequenceLogic sharedInstance].mouseBoxSelectStartTatum endTatum:[SequenceLogic sharedInstance].mouseBoxSelectEndTatum startBrightness:self.newCommandBrightness endBrightness:self.newCommandBrightness];
        }
        else if([SequenceLogic sharedInstance].commandType == CommandTypeUp)
        {
            // Add command fade up
            [[SequenceLogic sharedInstance] addCommandForChannel:channel startTatum:[SequenceLogic sharedInstance].mouseBoxSelectStartTatum endTatum:[SequenceLogic sharedInstance].mouseBoxSelectEndTatum startBrightness:0.0 endBrightness:self.newCommandBrightness];
        }
        else if([SequenceLogic sharedInstance].commandType == CommandTypeDown)
        {
            // Add command fade down
            [[SequenceLogic sharedInstance] addCommandForChannel:channel startTatum:[SequenceLogic sharedInstance].mouseBoxSelectStartTatum endTatum:[SequenceLogic sharedInstance].mouseBoxSelectEndTatum startBrightness:self.newCommandBrightness endBrightness:0.0];
        }
        
        currentMouseIndex ++;
    }
    
    [[CoreDataManager sharedManager] saveContext];
    [self setNeedsDisplay:YES];
}

- (void)deleteCommandsForSelection
{
    int currentMouseIndex = self.mouseBoxSelectTopChannel;
    while(currentMouseIndex < self.mouseBoxSelectBottomChannel)
    {
        // Figure out which control box
        int channelCount = 0;
        int controlBoxIndex = 0;
        for(int i = 0; i < self.controlBoxes.count; i ++)
        {
            ControlBox *controlBox = self.controlBoxes[i];
            
            if(currentMouseIndex > controlBox.channels.count - 1 + channelCount)
            {
                channelCount += controlBox.channels.count;
            }
            else
            {
                controlBoxIndex = i;
                break;
            }
        }
        // Figure out which channel
        NSArray *channels = self.channels[controlBoxIndex];
        Channel *channel = channels[currentMouseIndex - channelCount];
        
        // Delete any commands that we are overlapping
        // See if we are replacing any commands
        const float epsilon = 0.0001;
        float startTatumTime = [[SequenceLogic sharedInstance].mouseBoxSelectStartTatum.time floatValue];
        float endTatumTime = [[SequenceLogic sharedInstance].mouseBoxSelectEndTatum.time floatValue];
        NSArray *commandsToRemove = [[[[[CoreDataManager sharedManager].managedObjectContext ofType:@"Command"] where:@"sequence == %@ AND channel == %@ AND ((startTatum.time > %f AND startTatum.time < %f) OR (endTatum.time > %f AND endTatum.time < %f) OR (startTatum.time < %f AND endTatum.time > %f) OR (startTatum.time > %f AND startTatum.time < %f) OR (endTatum.time > %f AND endTatum.time < %f))", [CoreDataManager sharedManager].currentSequence, channel, startTatumTime, endTatumTime, startTatumTime, endTatumTime, startTatumTime, endTatumTime, startTatumTime - epsilon, startTatumTime + epsilon, endTatumTime - epsilon, endTatumTime + epsilon] orderBy:@"startTatum.time"] toArray];
        for(Command *command in commandsToRemove)
        {
            [[CoreDataManager sharedManager].managedObjectContext deleteObject:command];
        }
        
        currentMouseIndex ++;
    }
    
    [[CoreDataManager sharedManager] saveContext];
    self.retainMouseGroupSelect = NO;
    [self setNeedsDisplay:YES];
}

- (void)pasteDataWithPasteEpsilon:(float)pasteEpsilon
{
    // Pase data
    const float epsilon = 0.001;
    float copyStartTime = [[SequenceLogic sharedInstance].startTatumForCopy.time floatValue];
    float copyEndTime = [[SequenceLogic sharedInstance].endTatumForCopy.time floatValue];
    float pasteStartTime = [[SequenceLogic sharedInstance].mouseBoxSelectStartTatum.time floatValue];
    
    // Paste tatums from the copy area. Don't replace existing tatums in the same spot
    NSArray *tatumsToCopy = [[[[[CoreDataManager sharedManager].managedObjectContext ofType:@"SequenceTatum"] where:@"sequence == %@ AND time > %f AND time < %f", [CoreDataManager sharedManager].currentSequence, copyStartTime - epsilon, copyEndTime + epsilon] orderBy:@"time"] toArray];
    for(SequenceTatum *tatum in tatumsToCopy)
    {
        float newTatumTime = pasteStartTime + [tatum.time floatValue] - copyStartTime;
        SequenceTatum *sameTatum = [[[[[[CoreDataManager sharedManager].managedObjectContext ofType:@"SequenceTatum"] where:@"sequence == %@ AND time > %f AND time < %f", [CoreDataManager sharedManager].currentSequence, newTatumTime - pasteEpsilon, newTatumTime + pasteEpsilon] orderBy:@"time"] toArray] firstObject];
        // Add the tatum if one doesn't already exist
        if(!sameTatum)
        {
            [[CoreDataManager sharedManager] addSequenceTatumToSequence:[CoreDataManager sharedManager].currentSequence atTime:newTatumTime];
        }
    }
    
    // Paste commands from the copy area, one channel at a time
    int i = 0;
    int copiedChannelsCounter = 0;
    for(NSArray *channels in self.channels)
    {
        for(int count = 0; count < channels.count; count ++)
        {
            // Only use the selected channels
            if(i >= [SequenceLogic sharedInstance].topChannelForCopy && i < [SequenceLogic sharedInstance].bottomChannelForCopy)
            {
                // Figure out which channel index we are pasting into
                int newChannelIndexForCommand = self.mouseBoxSelectTopChannel + copiedChannelsCounter;
                // Find the new channel
                BOOL done = NO;
                Channel *newChannel;
                int index = 0;
                for(NSArray *tempChannels in self.channels)
                {
                    for(Channel *tempChannel in tempChannels)
                    {
                        if(index == newChannelIndexForCommand)
                        {
                            done = YES;
                            newChannel = tempChannel;
                            break;
                        }
                        
                        index ++;
                    }
                    
                    if(done)
                    {
                        break;
                    }
                }
                
                // Only paste if we are in a valid range
                if(index < (self.isAudioAnalysisView ? [SequenceLogic sharedInstance].numberOfAudioChannels : [SequenceLogic sharedInstance].numberOfChannels))
                {
                    NSArray *commandsToCopy = [SequenceLogic sharedInstance].commandArraysToCopy[copiedChannelsCounter];
                    for(Command *command in commandsToCopy)
                    {
                        // Find the new startTatum
                        float newTatumTime = pasteStartTime + [command.startTatum.time floatValue] - copyStartTime;
                        SequenceTatum *startTatum = [[[[[[CoreDataManager sharedManager].managedObjectContext ofType:@"SequenceTatum"] where:@"sequence == %@ AND time > %f AND time < %f", [CoreDataManager sharedManager].currentSequence, newTatumTime - pasteEpsilon, newTatumTime + pasteEpsilon] orderBy:@"time"] toArray] firstObject];
                        // Find the new endTatum
                        newTatumTime = pasteStartTime + [command.endTatum.time floatValue] - copyStartTime;
                        SequenceTatum *endTatum = [[[[[[CoreDataManager sharedManager].managedObjectContext ofType:@"SequenceTatum"] where:@"sequence == %@ AND time > %f AND time < %f", [CoreDataManager sharedManager].currentSequence, newTatumTime - pasteEpsilon, newTatumTime + pasteEpsilon] orderBy:@"time"] toArray] firstObject];
                        
                        // Only paste if we have a start and end tatum
                        if(startTatum && endTatum)
                        {
                            if([command isMemberOfClass:[CommandOn class]])
                            {
                                [[SequenceLogic sharedInstance] addCommandForChannel:newChannel startTatum:startTatum endTatum:endTatum startBrightness:[((CommandOn *)command).brightness floatValue] endBrightness:[((CommandOn *)command).brightness floatValue]];
                            }
                            else if([command isMemberOfClass:[CommandFade class]])
                            {
                                [[SequenceLogic sharedInstance] addCommandForChannel:newChannel startTatum:startTatum endTatum:endTatum startBrightness:[((CommandFade *)command).startBrightness floatValue] endBrightness:[((CommandFade *)command).endBrightness floatValue]];
                            }
                        }
                    }
                }
                
                // Increment how many of the copy channels we have finished
                copiedChannelsCounter ++;
            }
            
            // Increment our channel counter
            i ++;
        }
    }
}

- (void)pasteDataToExistingTatums
{
    // Pase to existing tatums
    const float epsilon = 0.001;
    NSArray *copyTatums = [[[[[CoreDataManager sharedManager].managedObjectContext ofType:@"SequenceTatum"] where:@"time >= %f AND time <= %f AND sequence == %@", [[SequenceLogic sharedInstance].startTatumForCopy.time floatValue] - epsilon, [[SequenceLogic sharedInstance].endTatumForCopy.time floatValue] + epsilon, [CoreDataManager sharedManager].currentSequence] orderBy:@"time"] toArray];
    NSArray *tatums = [[[[[CoreDataManager sharedManager].managedObjectContext ofType:@"SequenceTatum"] where:@"time >= %f AND sequence == %@", [[SequenceLogic sharedInstance].mouseBoxSelectStartTatum.time floatValue] - epsilon, [CoreDataManager sharedManager].currentSequence] orderBy:@"time"] toArray];
    SequenceTatum *endPasteTatum = tatums[copyTatums.count - 1];
    NSArray *pasteTatums = [[[[[CoreDataManager sharedManager].managedObjectContext ofType:@"SequenceTatum"] where:@"time >= %f AND time <= %f AND sequence == %@", [[SequenceLogic sharedInstance].mouseBoxSelectStartTatum.time floatValue] - epsilon, [endPasteTatum.time floatValue] + epsilon, [CoreDataManager sharedManager].currentSequence] orderBy:@"time"] toArray];
    
    // Paste commands from the copy area, one channel at a time
    int i = 0;
    int copiedChannelsCounter = 0;
    for(NSArray *channels in self.channels)
    {
        for(int count = 0; count < channels.count; count ++)
        {
            // Only use the selected channels
            if(i >= [SequenceLogic sharedInstance].topChannelForCopy && i < [SequenceLogic sharedInstance].bottomChannelForCopy)
            {
                // Figure out which channel index we are pasting into
                int newChannelIndexForCommand = self.mouseBoxSelectTopChannel + copiedChannelsCounter;
                // Find the new channel
                BOOL done = NO;
                Channel *newChannel;
                int index = 0;
                for(NSArray *tempChannels in self.channels)
                {
                    for(Channel *tempChannel in tempChannels)
                    {
                        if(index == newChannelIndexForCommand)
                        {
                            done = YES;
                            newChannel = tempChannel;
                            break;
                        }
                        
                        index ++;
                    }
                    
                    if(done)
                    {
                        break;
                    }
                }
                
                // Only paste if we are in a valid range
                if(index < (self.isAudioAnalysisView ? [SequenceLogic sharedInstance].numberOfAudioChannels : [SequenceLogic sharedInstance].numberOfChannels))
                {
                    NSArray *commandsToCopy = [SequenceLogic sharedInstance].commandArraysToCopy[copiedChannelsCounter];
                    for(Command *command in commandsToCopy)
                    {
                        // Find the new start and end tatums based on the number of tatums
                        int copyStartTatumIndex = 0;
                        int copyEndTatumIndex = 0;
                        int i2 = 0;
                        for(SequenceTatum *tatum in copyTatums)
                        {
                            if(tatum == command.startTatum)
                            {
                                copyStartTatumIndex = i2;
                            }
                            if(tatum == command.endTatum)
                            {
                                copyEndTatumIndex = i2;
                            }
                            
                            i2 ++;
                        }
                        SequenceTatum *startTatum;
                        if(copyStartTatumIndex < pasteTatums.count)
                        {
                            startTatum = pasteTatums[copyStartTatumIndex];
                        }
                        SequenceTatum *endTatum;
                        if(copyEndTatumIndex < pasteTatums.count)
                        {
                            endTatum = pasteTatums[copyEndTatumIndex];
                        }
                        
                        // Only paste if we have a start and end tatum
                        if(startTatum && endTatum)
                        {
                            if([command isMemberOfClass:[CommandOn class]])
                            {
                                [[SequenceLogic sharedInstance] addCommandForChannel:newChannel startTatum:startTatum endTatum:endTatum startBrightness:[((CommandOn *)command).brightness floatValue] endBrightness:[((CommandOn *)command).brightness floatValue]];
                            }
                            else if([command isMemberOfClass:[CommandFade class]])
                            {
                                [[SequenceLogic sharedInstance] addCommandForChannel:newChannel startTatum:startTatum endTatum:endTatum startBrightness:[((CommandFade *)command).startBrightness floatValue] endBrightness:[((CommandFade *)command).endBrightness floatValue]];
                            }
                        }
                    }
                }
                
                // Increment how many of the copy channels we have finished
                copiedChannelsCounter ++;
            }
            
            // Increment our channel counter
            i ++;
        }
    }
}

@end
