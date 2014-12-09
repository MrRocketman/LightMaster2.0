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

@end

@implementation SequenceDataView

- (void)setup
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sequenceChange:) name:@"CurrentSequenceChange" object:nil];
    
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
    NSRectFill(self.bounds);
    
    // Draw commands
    [self drawCommands];
    
    // Draw channel seperators
    [self drawChannelLines];
    
    // Draw Sequence Tatums
    [self drawSequenceTatums];
    
    // Draw the currentTimeMarker
    //[self drawCurrentTimeMarker];
    
    // Draw mouse selection box
    [self drawMouseGroupSelectionBox];
}

- (void)drawCommands
{
    // Get visible bounds
    NSRect visibleRect = [(NSScrollView *)self.superview.superview documentVisibleRect];
    float leftTime = [[SequenceLogic sharedInstance] xToTime:visibleRect.origin.x - visibleRect.size.width / 2];
    float rightTime = [[SequenceLogic sharedInstance] xToTime:visibleRect.origin.x + visibleRect.size.width * 1.5];
    int totalChannelIndex = 0;
    
    for(int controlBoxIndex = 0; controlBoxIndex < self.controlBoxes.count; controlBoxIndex ++)
    {
        NSArray *channels = self.channels[controlBoxIndex];
        for(int channelIndex = 0; channelIndex < channels.count; channelIndex ++)
        {
            NSBezierPath *commandPath = [NSBezierPath bezierPath];
            NSSet *commands = ((Channel *)channels[channelIndex]).commands;
            for(Command *theCommand in commands)
            {
                float startTime = [theCommand.startTatum.time floatValue];
                float endTime = [theCommand.endTatum.time floatValue];
                if((startTime >= leftTime && startTime <= rightTime) || (endTime >= leftTime && endTime <= rightTime) || (startTime < leftTime && endTime > rightTime))
                {
                    if([theCommand isMemberOfClass:[CommandOn class]])
                    {
                        CommandOn *command = (CommandOn *)theCommand;
                        float leftX = [[SequenceLogic sharedInstance] timeToX:[command.startTatum.time floatValue]];
                        float rightX = [[SequenceLogic sharedInstance] timeToX:[command.endTatum.time floatValue]];
                        float topY = totalChannelIndex * CHANNEL_HEIGHT + (CHANNEL_HEIGHT * (1.0 - [command.brightness floatValue]));
                        float bottomY = (totalChannelIndex + 1) * CHANNEL_HEIGHT - 1;
                        [commandPath moveToPoint:NSMakePoint(leftX, topY)];
                        [commandPath lineToPoint:NSMakePoint(leftX, bottomY)];
                        [commandPath lineToPoint:NSMakePoint(rightX, bottomY)];
                        [commandPath lineToPoint:NSMakePoint(rightX, topY)];
                        [commandPath lineToPoint:NSMakePoint(leftX, topY)];
                    }
                    else if([theCommand isMemberOfClass:[CommandFade class]])
                    {
                        CommandFade *command = (CommandFade *)theCommand;
                        float leftX = [[SequenceLogic sharedInstance] timeToX:[command.startTatum.time floatValue]];
                        float rightX = [[SequenceLogic sharedInstance] timeToX:[command.endTatum.time floatValue]];
                        float modifiedStartBrightness = ([command.startBrightness floatValue] > 0.1 ? (1.0 - [command.startBrightness floatValue]) : (0.9 - [command.startBrightness floatValue]));
                        float modifiedEndBrightness = ([command.endBrightness floatValue] > 0.1 ? (1.0 - [command.endBrightness floatValue]) : (0.9 - [command.endBrightness floatValue]));
                        float leftY = totalChannelIndex * CHANNEL_HEIGHT + (CHANNEL_HEIGHT * modifiedStartBrightness);
                        float rightY = totalChannelIndex * CHANNEL_HEIGHT + (CHANNEL_HEIGHT * modifiedEndBrightness);
                        float bottomY = (totalChannelIndex + 1) * CHANNEL_HEIGHT - 1;
                        [commandPath moveToPoint:NSMakePoint(leftX, leftY)];
                        [commandPath lineToPoint:NSMakePoint(leftX, bottomY)];
                        [commandPath lineToPoint:NSMakePoint(rightX, bottomY)];
                        [commandPath lineToPoint:NSMakePoint(rightX, rightY)];
                        [commandPath lineToPoint:NSMakePoint(leftX, leftY)];
                    }
                }
            }
            
            [(NSColor *)(((Channel *)[((NSArray *)self.channels[controlBoxIndex]) objectAtIndex:channelIndex]).color) set];
            [commandPath fill];
            
            totalChannelIndex ++;
        }
    }
}

- (void)drawChannelLines
{
    NSBezierPath *linesPath = [NSBezierPath bezierPath];
    
    int largestY = NSMaxY(self.bounds);
    for (int i = 0; i < largestY; i += CHANNEL_HEIGHT)
    {
        NSPoint startPoint = NSMakePoint(NSMinX(self.bounds), i);
        NSPoint endPoint = NSMakePoint(NSMaxX(self.bounds), i);
        
        [linesPath moveToPoint:startPoint];
        [linesPath lineToPoint:endPoint];
    }
    
    [[NSColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1.0] set];
    [linesPath setLineWidth:1.0];
    [linesPath stroke];
}

- (void)drawSequenceTatums
{
    NSRect visibleRect = [(NSScrollView *)self.superview.superview documentVisibleRect];
    NSArray *visibleTatums = [[[[[CoreDataManager sharedManager].managedObjectContext ofType:@"SequenceTatum"] where:@"sequence == %@ AND time >= %f AND time <= %f", [CoreDataManager sharedManager].currentSequence, [[SequenceLogic sharedInstance] xToTime:visibleRect.origin.x - visibleRect.size.width / 2], [[SequenceLogic sharedInstance] xToTime:visibleRect.origin.x + visibleRect.size.width * 1.5]] orderBy:@"time"] toArray];
    
    self.sequenceTatumPaths = [NSBezierPath bezierPath];
    for(int i = 0; i < visibleTatums.count; i ++)
    {
        SequenceTatum *tatum = (SequenceTatum *)visibleTatums[i];
        
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
                [self addSequenceTatum:tatum toBezierPath:selectedTatumPath];
                [[NSColor yellowColor] set];
                [selectedTatumPath fill];
            }
            
            // Tell any other views to update
            [[NSNotificationCenter defaultCenter] postNotificationName:@"SequenceTatumChange" object:nil];
        }
        else
        {
            // Draw the normal sequence Tatums
            NSPoint startPoint = [self addSequenceTatum:tatum toBezierPath:self.sequenceTatumPaths];
            
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
                if(i < visibleTatums.count - 1)
                {
                    nextTatum = (SequenceTatum *)visibleTatums[i + 1];
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
    //[self.sequenceTatumPaths setLineWidth:1.0];
    [self.sequenceTatumPaths fill];
}

- (NSPoint)addSequenceTatum:(SequenceTatum *)tatum toBezierPath:(NSBezierPath *)path
{
    NSPoint startPoint = NSMakePoint([[SequenceLogic sharedInstance] timeToX:[tatum.time floatValue]], NSMinY(self.bounds));
    NSPoint endPoint = NSMakePoint(startPoint.x, NSMaxY(self.bounds));
    
    [path moveToPoint:NSMakePoint(startPoint.x - 1, startPoint.y)];
    [path lineToPoint:NSMakePoint(endPoint.x - 1, endPoint.y)];
    [path lineToPoint:NSMakePoint(endPoint.x + 1, endPoint.y)];
    [path lineToPoint:NSMakePoint(startPoint.x + 1, startPoint.y)];
    
    return startPoint;
}

- (void)drawCurrentTimeMarker
{
    NSRect markerLineFrame = NSMakeRect([[SequenceLogic sharedInstance] timeToX:[SequenceLogic sharedInstance].currentTime], 0, 1, self.frame.size.height);
    [[NSColor redColor] set];
    NSRectFill(markerLineFrame);
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
    // new/delete tatum
    else if(self.optionKey)
    {
        [[CoreDataManager sharedManager] addSequenceTatumToSequence:[CoreDataManager sharedManager].currentSequence atTime:[[SequenceLogic sharedInstance] xToTime:self.currentMousePoint.x]];
        [[CoreDataManager sharedManager] saveContext];
        self.sequenceTatumIsSelected = YES;
        self.newTatum = YES;
    }
    // deselect shift drag selection
    else if(self.retainMouseGroupSelect)
    {
        self.mouseGroupSelect = NO;
    }
    // start new drag
    else
    {
        self.mouseGroupSelect = YES;
        [SequenceLogic sharedInstance].mouseBoxSelectStartTatum = nil;
        [SequenceLogic sharedInstance].mouseBoxSelectEndTatum = nil;
    }
    
    // start new shift drag
    if(self.shiftKey || self.commandKey)
    {
        self.retainMouseGroupSelect = YES;
    }
    // deselect shift drag if we aren't dragging a tatum
    else if(!self.sequenceTatumIsSelected)
    {
        self.retainMouseGroupSelect = NO;
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
    NSRect visibleRect = [(NSScrollView *)self.superview.superview documentVisibleRect];
    if(self.currentMousePoint.x > visibleRect.origin.x + visibleRect.size.width - 10 || self.currentMousePoint.x < visibleRect.origin.x + 10)
    {
        BOOL didAutoscroll = [self autoscroll:self.mouseEvent];
        if(didAutoscroll)
        {
            [self setNeedsDisplay:YES];
        }
    }
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
            [self subdivideTatums:1];
        }
        else if(keyboardEvent.keyCode == 19 || keyboardEvent.keyCode == 84) // '2'
        {
            self.newCommandBrightness = 0.2;
            [self subdivideTatums:2];
        }
        else if(keyboardEvent.keyCode == 20 || keyboardEvent.keyCode == 85) // '3'
        {
            self.newCommandBrightness = 0.3;
            [self subdivideTatums:3];
        }
        else if(keyboardEvent.keyCode == 21 || keyboardEvent.keyCode == 86) // '4'
        {
            self.newCommandBrightness = 0.4;
            [self subdivideTatums:4];
        }
        else if(keyboardEvent.keyCode == 23 || keyboardEvent.keyCode == 87) // '5'
        {
            self.newCommandBrightness = 0.5;
            [self subdivideTatums:5];
        }
        else if(keyboardEvent.keyCode == 22 || keyboardEvent.keyCode == 88) // '6'
        {
            self.newCommandBrightness = 0.6;
            [self subdivideTatums:6];
        }
        else if(keyboardEvent.keyCode == 26 || keyboardEvent.keyCode == 89) // '7'
        {
            self.newCommandBrightness = 0.7;
            [self subdivideTatums:7];
        }
        else if(keyboardEvent.keyCode == 28 || keyboardEvent.keyCode == 91) // '8'
        {
            self.newCommandBrightness = 0.8;
            [self subdivideTatums:8];
        }
        else if(keyboardEvent.keyCode == 25 || keyboardEvent.keyCode == 92) // '9'
        {
            self.newCommandBrightness = 0.9;
            [self subdivideTatums:9];
        }
        else if(keyboardEvent.keyCode == 51) // 'delete'
        {
            // delete
            [SequenceLogic sharedInstance].commandType = CommandTypeDelete;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ChangeCommandType" object:nil];
        }
        else if(keyboardEvent.keyCode == 31) // 'o'
        {
            // command on
            [SequenceLogic sharedInstance].commandType = CommandTypeOn;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ChangeCommandType" object:nil];
        }
        else if(keyboardEvent.keyCode == 32) // 'u'
        {
            // fade up
            [SequenceLogic sharedInstance].commandType = CommandTypeUp;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ChangeCommandType" object:nil];
        }
        else if(keyboardEvent.keyCode == 2) // 'd'
        {
            // fade down
            [SequenceLogic sharedInstance].commandType = CommandTypeDown;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ChangeCommandType" object:nil];
        }
        else if(keyboardEvent.keyCode == 17) // 't'
        {
            // twinkle
            [SequenceLogic sharedInstance].commandType = CommandTypeTwinkle;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ChangeCommandType" object:nil];
        }
        else if(keyboardEvent.keyCode == 35) // 'p'
        {
            // pulse
            [SequenceLogic sharedInstance].commandType = CommandTypePulse;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ChangeCommandType" object:nil];
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
        int controlBoxIndex;
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
        
        // See if we are replacing any commands
        float startTatumTime = [[SequenceLogic sharedInstance].mouseBoxSelectStartTatum.time floatValue];
        float endTatumTime = [[SequenceLogic sharedInstance].mouseBoxSelectEndTatum.time floatValue];
        NSArray *commandsToRemove = [[[[[CoreDataManager sharedManager].managedObjectContext ofType:@"Command"] where:@"channel == %@ AND ((startTatum.time > %f AND startTatum.time < %f) OR (endTatum.time > %f AND endTatum.time < %f) OR (startTatum.time < %f AND endTatum.time > %f) OR (startTatum.time >= %f AND endTatum.time <= %f))", channel, startTatumTime, endTatumTime, startTatumTime, endTatumTime, startTatumTime, endTatumTime, startTatumTime, endTatumTime] orderBy:@"startTatum.time"] toArray];
        for(Command *command in commandsToRemove)
        {
            [[CoreDataManager sharedManager].managedObjectContext deleteObject:command];
        }
        
        // Add the appropriate command
        if([SequenceLogic sharedInstance].commandType != CommandTypeDelete)
        {
            if([SequenceLogic sharedInstance].commandType == CommandTypeOn)
            {
                CommandOn *command = [NSEntityDescription insertNewObjectForEntityForName:@"CommandOn" inManagedObjectContext:[CoreDataManager sharedManager].managedObjectContext];
                command.startTatum = [SequenceLogic sharedInstance].mouseBoxSelectStartTatum;
                command.endTatum = [SequenceLogic sharedInstance].mouseBoxSelectEndTatum;
                command.brightness = @(self.newCommandBrightness);
                command.channel = channel;
                command.uuid = [[NSUUID UUID] UUIDString];
            }
            else if([SequenceLogic sharedInstance].commandType == CommandTypeUp)
            {
                CommandFade *command = [NSEntityDescription insertNewObjectForEntityForName:@"CommandFade" inManagedObjectContext:[CoreDataManager sharedManager].managedObjectContext];
                command.startTatum = [SequenceLogic sharedInstance].mouseBoxSelectStartTatum;
                command.endTatum = [SequenceLogic sharedInstance].mouseBoxSelectEndTatum;
                command.startBrightness = @(0.0);
                command.endBrightness = @(self.newCommandBrightness);
                command.channel = channel;
                command.uuid = [[NSUUID UUID] UUIDString];
            }
            else if([SequenceLogic sharedInstance].commandType == CommandTypeDown)
            {
                CommandFade *command = [NSEntityDescription insertNewObjectForEntityForName:@"CommandFade" inManagedObjectContext:[CoreDataManager sharedManager].managedObjectContext];
                command.startTatum = [SequenceLogic sharedInstance].mouseBoxSelectStartTatum;
                command.endTatum = [SequenceLogic sharedInstance].mouseBoxSelectEndTatum;
                command.startBrightness = @(self.newCommandBrightness);
                command.endBrightness = @(0.0);
                command.channel = channel;
                command.uuid = [[NSUUID UUID] UUIDString];
            }
        }
        
        currentMouseIndex ++;
    }
    
    [[CoreDataManager sharedManager] saveContext];
}

@end
