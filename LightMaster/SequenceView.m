//
//  SequenceView.m
//  LightMaster
//
//  Created by James Adams on 11/25/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import "SequenceView.h"
#import "CoreDataManager.h"
#import "NSManagedObjectContext+Queryable.h"
#import "Sequence.h"
#import "ControlBox.h"
#import "Channel.h"
#import "Audio.h"
#import "UserAudioAnalysis.h"
#import "UserAudioAnalysisTrack.h"
#import "UserAudioAnalysisTrackChannel.h"

@interface SequenceView()

@end

@implementation SequenceView

#pragma mark - System methods

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if(self = [super initWithCoder:aDecoder])
    {
        // Register for the notifications on the scrollView
        [[self superview] setPostsBoundsChangedNotifications:YES];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollViewBoundsChange:) name:NSViewBoundsDidChangeNotification object:[self superview]];
        
        mouseDraggingEventObjectIndex = -1;
        selectedCommandIndex = -1;
        self.zoomLevel = 3.0;
    }
    
    return self;
}

- (BOOL)isFlipped
{
    return YES;
}

- (void)scrollViewBoundsChange:(NSNotification *)notification
{
    NSClipView *changedScrollView = [notification object];
    
    visibleFrame.origin = [changedScrollView documentVisibleRect].origin;
    visibleFrame.size = [changedScrollView documentVisibleRect].size;
    self.timeAtLeftEdgeOfView = (visibleFrame.origin.x / self.zoomLevel / PIXEL_TO_ZOOM_RATIO);
    [self setNeedsDisplay:YES];
}

- (int)timeToX:(float)time
{
    int x = [self widthForTimeInterval:time];
    
    return x;
}

- (float)xToTime:(int)x
{
    if(x > 0)
    {
        x -= HEADER_TOTAL_WIDTH;
        return  x / self.zoomLevel / PIXEL_TO_ZOOM_RATIO;
    }
    
    return 0;
}

- (int)widthForTimeInterval:(float)timeInterval
{
    return (timeInterval * self.zoomLevel * PIXEL_TO_ZOOM_RATIO) + HEADER_TOTAL_WIDTH;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    // Calculate the frame
    int channelsCount = 1 + (int)[[[[CoreDataManager sharedManager].managedObjectContext ofType:@"Channel"] toArray] count] + (int)[[[[CoreDataManager sharedManager].managedObjectContext ofType:@"UserAudioAnalysisTrackChannel"] toArray] count] + (int)[CoreDataManager sharedManager].currentSequence.audio.userAudioAnalysis.tracks.count + ([CoreDataManager sharedManager].currentSequence.audio ? 1 : 0);
    int frameHeight = 0;
    int frameWidth = [self timeToX:[[CoreDataManager sharedManager].currentSequence.endTime floatValue]] + HEADER_TOTAL_WIDTH;
    // Set the Frame
    frameHeight = channelsCount * CHANNEL_HEIGHT + TOP_BAR_HEIGHT;
    if(frameWidth <= self.superview.frame.size.width)
    {
        frameWidth = self.superview.frame.size.width;
    }
    if(frameHeight <= self.superview.frame.size.height)
    {
        frameHeight = self.superview.frame.size.height;
    }
    [self setFrame:NSMakeRect(0, 0, frameWidth, frameHeight)];
    
    [[NSColor darkGrayColor] set];
    NSRectFill(NSMakeRect(HEADER_TOTAL_WIDTH, 0, frameWidth - HEADER_TOTAL_WIDTH, frameHeight));
    
    [[NSColor grayColor] set];
    NSRectFill(NSMakeRect(0, 0, HEADER_TOTAL_WIDTH, frameHeight));
    
    // Check for timelineBar mouse clicks
    [self timelineBarMouseChecking];
    
    ///////////////////////////// Headers /////////////////////////////////////
    
    int headerChannelCount = 0;
    // Draw audio header
    [self drawChannelBackgroundWithX:0 y:headerChannelCount width:HEADER_TOTAL_WIDTH height:1 red:1.0 green:0.0 blue:0.0 alpha:1.0];
    headerChannelCount ++;
    // If there is audio
    if([CoreDataManager sharedManager].currentSequence.audio)
    {
        // Draw the audio track headers
        for(UserAudioAnalysisTrack *userAudioAnalysisTrack in [CoreDataManager sharedManager].currentSequence.audio.userAudioAnalysis.tracks)
        {
            [self drawChannelBackgroundWithX:0 y:headerChannelCount width:HEADER_WIDTH height:(userAudioAnalysisTrack.channels.count + 1) red:0.8 green:0.0 blue:0.0 alpha:1.0];
            headerChannelCount += userAudioAnalysisTrack.channels.count + 1;
        }
        
        // Draw the add audio track header
        [self drawChannelBackgroundWithX:0 y:headerChannelCount width:HEADER_TOTAL_WIDTH height:1 red:0.5 green:0.0 blue:0.0 alpha:1.0];
        headerChannelCount ++;
    }
    // Draw control box headers
    for(ControlBox *controlBox in [CoreDataManager sharedManager].currentSequence.controlBoxes)
    {
        [self drawChannelBackgroundWithX:0 y:headerChannelCount width:HEADER_WIDTH height:controlBox.channels.count red:0.0 green:1.0 blue:0.0 alpha:1.0];
        headerChannelCount += controlBox.channels.count;
    }
    
    /////////////////////////////// Header details //////////////////////////////////
    
    // Skip a slot for the audio header
    int headerDetailChannelCount = 1;
    // If there is audio
    if([CoreDataManager sharedManager].currentSequence.audio)
    {
        // Draw the audio channel headers
        for(UserAudioAnalysisTrack *userAudioAnalysisTrack in [CoreDataManager sharedManager].currentSequence.audio.userAudioAnalysis.tracks)
        {
            NSArray *channelsArray = [[[[[CoreDataManager sharedManager].managedObjectContext ofType:@"Channel"] where:@"track == %@", userAudioAnalysisTrack] orderBy:@"idNumber"] toArray];
            for(int i = 0; i < channelsArray.count; i ++)
            {
                [self drawChannelBackgroundWithX:HEADER_DETAIL_WIDTH y:headerChannelCount width:HEADER_WIDTH height:1 red:0.8 green:0.0 blue:0.0 alpha:1.0];
                headerDetailChannelCount ++;
                
                
                // Draw the channel index
                //NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
                //NSFont *font = [NSFont fontWithName:@"Helvetica Bold" size:12];
                //NSRect textFrame = NSMakeRect([data timeToX:[data timeAtLeftEdgeOfTimelineView]] + 3, bottomOfChannelLine.origin.y - 2, 20, CHANNEL_HEIGHT);
                //[attributes setObject:font forKey:NSFontAttributeName];
                //[attributes setObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
                
                //if(parentIsControlBox)
                //{
                //[[NSString stringWithFormat:@"%d", [[data numberForChannel:[data channelAtIndex:i forControlBox:[data controlBoxForCurrentSequenceAtIndex:parentFilePathIndex]]] intValue]] drawInRect:textFrame withAttributes:attributes];
            }
        }
        
        // Skip a slot for the add audio track header
        headerDetailChannelCount ++;
    }
    
    // Draw control box headers
    for(ControlBox *controlBox in [CoreDataManager sharedManager].currentSequence.controlBoxes)
    {
        NSArray *channelsArray = [[[[[CoreDataManager sharedManager].managedObjectContext ofType:@"Channel"] where:@"controlBox == %@", controlBox] orderBy:@"idNumber"] toArray];
        for(int i = 0; i < channelsArray.count; i ++)
        {
            [self drawChannelBackgroundWithX:HEADER_DETAIL_WIDTH y:headerChannelCount width:HEADER_WIDTH height:1 red:0.0 green:1.0 blue:0.0 alpha:1.0];
            headerDetailChannelCount ++;
        }
    }
    
    //////////////////////////////// Commands ///////////////////////////////
    
    // Draw the audio
    int channelCount = 0;
    // Draw audio
    if([CoreDataManager sharedManager].currentSequence.audio)
    {
        //[self drawRect:NSMakeRect(0, TOP_BAR_HEIGHT + headerChannelCount * CHANNEL_HEIGHT, HEADER_WIDTH + HEADER_DETAIL_WIDTH, CHANNEL_HEIGHT) withCornerRadius:COMMAND_CORNER_RADIUS fillColor:[NSColor colorWithDeviceRed:0.9 green:0.9 blue:0.9 alpha:0.7] andStroke:YES];
        //[self drawAudioClipsAtTrackIndex:trackIndex tracksTall:tracksTall];
        channelCount ++;
    }
    // Draw the userAudioAnalysis Commands
    for(UserAudioAnalysisTrack *userAudioAnalysisTrack in [CoreDataManager sharedManager].currentSequence.audio.userAudioAnalysis.tracks)
    {
        NSArray *channelsArray = [[[[[CoreDataManager sharedManager].managedObjectContext ofType:@"Channel"] where:@"track == %@", userAudioAnalysisTrack] orderBy:@"idNumber"] toArray];
        for(int i = 0; i < channelsArray.count; i ++)
        {
            //[self drawRect:NSMakeRect(HEADER_WIDTH, TOP_BAR_HEIGHT + channelCount * CHANNEL_HEIGHT, HEADER_DETAIL_WIDTH, CHANNEL_HEIGHT) withCornerRadius:COMMAND_CORNER_RADIUS fillColor:[NSColor colorWithDeviceRed:0.8 green:0.8 blue:0.8 alpha:0.7] andStroke:YES];
            //[self drawCommandClustersAtTrackIndex:trackIndex tracksTall:tracksTall parentIndex:i parentIsControlBox:YES];
            channelCount ++;
        }
    }
    channelCount ++;
    // Draw the commands
    for(ControlBox *controlBox in [CoreDataManager sharedManager].currentSequence.controlBoxes)
    {
        NSArray *channelsArray = [[[[[CoreDataManager sharedManager].managedObjectContext ofType:@"Channel"] where:@"controlBox == %@", controlBox] orderBy:@"idNumber"] toArray];
        for(int i = 0; i < channelsArray.count; i ++)
        {
            //[self drawRect:NSMakeRect(HEADER_WIDTH, TOP_BAR_HEIGHT + channelCount * CHANNEL_HEIGHT, HEADER_DETAIL_WIDTH, CHANNEL_HEIGHT) withCornerRadius:COMMAND_CORNER_RADIUS fillColor:[NSColor colorWithDeviceRed:0.6 green:0.6 blue:0.6 alpha:0.7] andStroke:YES];
            //[self drawCommandClustersAtTrackIndex:trackIndex tracksTall:tracksTall parentIndex:i parentIsControlBox:YES];
            channelCount ++;
        }
    }
    
    //////////////////////////////////// Extras //////////////////////////////////////////
    
    // Draw the channel seperators
    [self drawChannelGuidlines:channelsCount];
    
    // Draw the timeline on top of everything
    [self drawTimelineBar];
    
    // Draw the audio analysis data
    /*for(int i = 0; i < [data audioClipFilePathsCountForSequence:[data currentSequence]]; i ++)
    {
        NSDictionary *audioAnalysis = [data audioAnalysisForCurrentSequenceAtIndex:i];
        if(![[NSNull null] isEqual:audioAnalysis])
        {
            if(data.shouldDrawSegments)
            {
                [self drawSegmentsForAudioAnalysis:audioAnalysis];
            }
            if(data.shouldDrawTatums)
            {
                [self drawTatumsForAudioAnalysis:audioAnalysis];
            }
            if(data.shouldDrawBeats)
            {
                [self drawBeatsForAudioAnalysis:audioAnalysis];
            }
            if(data.shouldDrawBars)
            {
                [self drawBarsForAudioAnalysis:audioAnalysis];
            }
            if(data.shouldDrawSections)
            {
                [self drawSectionsForAudioAnalysis:audioAnalysis];
            }
        }
    }
    
    // Check for manual channel controls and new commandCluster/audioClip/channelGroup clicks
    if(mouseEvent != nil)
    {
        [self handleEmptySpaceMouseAction];
    }*/
}

#pragma mark - Helper Drawing Methods

- (void)drawChannelBackgroundWithX:(float)x y:(float)y width:(float)width height:(float)height red:(float)red green:(float)green blue:(float)blue alpha:(float)alpha
{
    [self drawRect:NSMakeRect(x, TOP_BAR_HEIGHT + (y * CHANNEL_HEIGHT) + 1, width, height * CHANNEL_HEIGHT - 2) withCornerRadius:COMMAND_CORNER_RADIUS fillColor:[NSColor colorWithDeviceRed:red green:green blue:blue alpha:alpha] andStroke:YES];
}

- (void)drawRect:(NSRect)aRect withCornerRadius:(float)radius fillColor:(NSColor *)color andStroke:(BOOL)yesOrNo
{
    NSBezierPath *thePath = [NSBezierPath bezierPathWithRoundedRect:aRect xRadius:radius yRadius:radius];
    
    [color setFill];
    [[NSColor whiteColor] setStroke];
    
    if(yesOrNo)
    {
        [thePath stroke];
    }
    [thePath fill];
}

- (void)drawTimelineBar
{
    // Draw the Top Bar
    NSRect topBarFrame = NSMakeRect(HEADER_TOTAL_WIDTH, visibleFrame.origin.y, self.frame.size.width, TOP_BAR_HEIGHT);
    [self drawRect:topBarFrame withCornerRadius:0 fillColor:[NSColor colorWithDeviceRed:0.9 green:0.9 blue:0.9 alpha:0.9] andStroke:NO];
    
    // Determine the grid spacing
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    NSFont *font = [NSFont fontWithName:@"Helvetica" size:10];
    [attributes setObject:font forKey:NSFontAttributeName];
    float timeSpan = [self xToTime:[self timeToX:self.timeAtLeftEdgeOfView] + self.frame.size.width - HEADER_TOTAL_WIDTH] - self.timeAtLeftEdgeOfView;
    float timeMarkerDifference = 0.0;
    if(timeSpan >= 60.0)
    {
        timeMarkerDifference = 6.0;
    }
    else if(timeSpan >= 50.0)
    {
        timeMarkerDifference = 5.0;
    }
    else if(timeSpan >= 40.0)
    {
        timeMarkerDifference = 4.0;
    }
    else if(timeSpan >= 30.0)
    {
        timeMarkerDifference = 3.0;
    }
    else if(timeSpan >= 20.0)
    {
        timeMarkerDifference = 2.0;
    }
    else if(timeSpan >= 15.0)
    {
        timeMarkerDifference = 1.5;
    }
    else if(timeSpan >= 10.0)
    {
        timeMarkerDifference = 1.0;
    }
    else if(timeSpan >= 5.0)
    {
        timeMarkerDifference = 0.5;
    }
    else if(timeSpan >= 2.5)
    {
        timeMarkerDifference = 0.25;
    }
    else if(timeSpan >= 1.25)
    {
        timeMarkerDifference = 0.125;
    }
    else
    {
        timeMarkerDifference = 0.0625;
    }
    
    // Draw the grid (+ 5 extras so the user doesn't see blank areas)
    float leftEdgeNearestTimeMaker = [self roundUpNumber:self.timeAtLeftEdgeOfView toNearestMultipleOfNumber:timeMarkerDifference];
    for(int i = 0; i < timeSpan / timeMarkerDifference + 6; i ++)
    {
        float timeMarker = (leftEdgeNearestTimeMaker + i * timeMarkerDifference);
        // Draw the times
        NSString *time = [NSString stringWithFormat:@"%.02f", timeMarker];
        NSRect textFrame = NSMakeRect([self timeToX:timeMarker], topBarFrame.origin.y + 5, 40, topBarFrame.size.height);
        [time drawInRect:textFrame withAttributes:attributes];
        
        // Draw grid lines
        //if(data.shouldDrawTime)
        //{
            //NSRect markerLineFrame = NSMakeRect(textFrame.origin.x, scrollViewOrigin.y, 1, superViewFrame.size.height - TOP_BAR_HEIGHT);
            //[[NSColor blackColor] set];
            //NSRectFill(markerLineFrame);
        //}
    }
    
    // Draw the currentTime marker
    NSPoint trianglePoint = NSMakePoint((float)[self timeToX:self.currentTime], topBarFrame.origin.y + TOP_BAR_HEIGHT);
    [self drawInvertedTriangleAndLineWithTipPoint:trianglePoint width:TOP_BAR_HEIGHT andHeight:TOP_BAR_HEIGHT];
}

- (void)drawInvertedTriangleAndLineWithTipPoint:(NSPoint)point width:(int)width andHeight:(int)height
{
    NSBezierPath *triangle = [NSBezierPath bezierPath];
    
    [triangle moveToPoint:point];
    [triangle lineToPoint:NSMakePoint(point.x - width / 2,  point.y - height)];
    [triangle lineToPoint:NSMakePoint(point.x + width / 2, point.y - height)];
    [triangle closePath];
    
    // Set the color according to whether it is clicked or not
    if(!currentTimeMarkerIsSelected)
    {
        [[NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:0.5] setFill];
    }
    else
    {
        [[NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:0.5] setFill];
    }
    [triangle fill];
    [[NSColor whiteColor] setStroke];
    [triangle stroke];
    
    NSRect markerLineFrame = NSMakeRect(point.x, TOP_BAR_HEIGHT, 1, self.frame.size.height - TOP_BAR_HEIGHT);
    [[NSColor redColor] set];
    NSRectFill(markerLineFrame);
}

- (void)drawChannelGuidlines:(int)channelsCount;
{
    for(int i = 0; i <= channelsCount; i ++)
    {
        NSRect bottomOfChannelLine = NSMakeRect(HEADER_WIDTH + HEADER_DETAIL_WIDTH, i * CHANNEL_HEIGHT + TOP_BAR_HEIGHT, self.frame.size.width, 1);
        
        NSColor *guidelineColor = [NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:1.0];
        [guidelineColor setFill];
        NSRectFill(bottomOfChannelLine);
    }
}

#pragma mark - Audio analysis drawing methods

/*- (void)drawGridLinesForEchoNestDataArray:(NSArray *)data withColor:(NSColor *)color
{
    NSRect superViewFrame = [[self superview] frame];
    float timeSpan = [data xToTime:[data timeToX:self.timeAtLeftEdgeOfView] + superViewFrame.size.width] - [data timeAtLeftEdgeOfTimelineView];
    float timeAtLeftEdge = [data timeAtLeftEdgeOfTimelineView];
    float timeAtRightEdge = timeAtLeftEdge + timeSpan;
    
    int visibleSectionIndex = 0;
    NSArray *sections = [audioAnalysis objectForKey:@"sections"];
    // Find the first visible section (since the data is sorted)
    while(visibleSectionIndex < [sections count] && (timeAtLeftEdge - 1 >= [[[sections objectAtIndex:visibleSectionIndex] objectForKey:@"start"] floatValue] || timeAtRightEdge + 1 <= [[[sections objectAtIndex:visibleSectionIndex] objectForKey:@"start"] floatValue]))
    {
        visibleSectionIndex ++;
    }
    
    // Now draw the visible sections (since the data is sorted)
    while(visibleSectionIndex < [sections count] && (timeAtLeftEdge - 1 < [[[sections objectAtIndex:visibleSectionIndex] objectForKey:@"start"] floatValue] && timeAtRightEdge + 1 > [[[sections objectAtIndex:visibleSectionIndex] objectForKey:@"start"] floatValue]))
    {
        // Draw grid lines
        NSRect markerLineFrame = NSMakeRect([data timeToX:[[[sections objectAtIndex:visibleSectionIndex] objectForKey:@"start"] floatValue]], scrollViewOrigin.y, 3, superViewFrame.size.height - TOP_BAR_HEIGHT);
        [color set];
        NSRectFill(markerLineFrame);
        
        visibleSectionIndex ++;
    }
}

#pragma mark - Data Drawing Methods

- (void)drawAudioClipsAtTrackIndex:(int)trackIndex tracksTall:(int)tracksTall
{
    tracksTall = 1;
    
    NSRect superViewFrame = [[self superview] frame];
    float timeSpan = [data xToTime:[data timeToX:[data timeAtLeftEdgeOfTimelineView]] + superViewFrame.size.width] - [data timeAtLeftEdgeOfTimelineView];
    float timeAtLeftEdge = [data timeAtLeftEdgeOfTimelineView];
    float timeAtRightEdge = timeAtLeftEdge + timeSpan;
    
    for(int i = 0; i < [data audioClipFilePathsCountForSequence:[data currentSequence]]; i ++)
    {
        NSMutableDictionary *currentAudioClip = [data audioClipForCurrentSequenceAtIndex:i];
        
        // Check to see if this audioClip is in the visible rangeself.timeAtLeftEdgeOfView
        if(([data startTimeForAudioClip:currentAudioClip] > timeAtLeftEdge && [data startTimeForAudioClip:currentAudioClip] < timeAtRightEdge) || ([data endTimeForAudioClip:currentAudioClip] > timeAtLeftEdge && [data endTimeForAudioClip:currentAudioClip] < timeAtRightEdge) || ([data startTimeForAudioClip:currentAudioClip] <= timeAtLeftEdge && [data endTimeForAudioClip:currentAudioClip] >= timeAtRightEdge))
        {
            NSRect audioClipRect = NSMakeRect([data timeToX:[data startTimeForAudioClip:currentAudioClip]], self.frame.size.height - trackIndex * CHANNEL_HEIGHT - tracksTall * CHANNEL_HEIGHT - TOP_BAR_HEIGHT + 1, [data widthForTimeInterval:[data endTimeForAudioClip:currentAudioClip] - [data startTimeForAudioClip:currentAudioClip]], CHANNEL_HEIGHT - 2);
            
            // AudioClip Mouse Checking here
            if(mouseEvent != nil && ((mouseAction == MNMouseDown && [[NSBezierPath bezierPathWithRect:audioClipRect] containsPoint:currentMousePoint]) || (mouseAction == MNMouseDragged && ((mouseDraggingEvent == MNMouseDragNotInUse && [[NSBezierPath bezierPathWithRect:audioClipRect] containsPoint:currentMousePoint]) || mouseDraggingEvent == MNAudioClipMouseDrag) && (mouseDraggingEventObjectIndex == -1 || mouseDraggingEventObjectIndex == i))))
            {
                [self drawRect:audioClipRect withCornerRadius:CLUSTER_CORNER_RADIUS fillColor:[NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:0.7] andStroke:YES];
                
                if(mouseAction == MNMouseDown)
                {
                    selectedAudioClip = currentAudioClip;
                    mouseClickDownPoint.x = mouseClickDownPoint.x - [data timeToX:[data startTimeForAudioClip:currentAudioClip]];
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"SelectAudioClip" object:selectedAudioClip];
                }
                else if(mouseAction == MNMouseDragged)
                {
                    mouseDraggingEvent = MNAudioClipMouseDrag;
                    mouseDraggingEventObjectIndex = i;
                    [data moveAudioClip:currentAudioClip toStartTime:[data xToTime:currentMousePoint.x - mouseClickDownPoint.x]];
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateLibraryContent" object:nil];
                }
                
                mouseEvent = nil;
            }
            else
            {
                [self drawRect:audioClipRect withCornerRadius:CLUSTER_CORNER_RADIUS fillColor:[NSColor colorWithDeviceRed:1.0 green:0.0 blue:0.0 alpha:0.7] andStroke:YES];
                selectedAudioClip = nil;
            }
        }
        
        trackIndex++;
    }
}

- (void)drawCommandClustersAtTrackIndex:(int)trackIndex tracksTall:(int)tracksTall parentIndex:(int)parentIndex parentIsControlBox:(BOOL)isControlBox
{
    NSRect superViewFrame = [[self superview] frame];
    NSRect visibleRect = [(NSClipView *)[self superview] documentVisibleRect];
    float timeSpan = [data xToTime:[data timeToX:[data timeAtLeftEdgeOfTimelineView]] + superViewFrame.size.width] - [data timeAtLeftEdgeOfTimelineView];
    float timeAtLeftEdge = [data timeAtLeftEdgeOfTimelineView];
    float timeAtRightEdge = timeAtLeftEdge + timeSpan;
    
    for(int i = 0; i < [data commandClusterFilePathsCountForSequence:[data currentSequence]]; i ++)
    {
        NSMutableDictionary *currentCommandCluster = [data commandClusterForCurrentSequenceAtIndex:i];
        float startTime = [data startTimeForCommandCluster:currentCommandCluster];
        float endTime = [data endTimeForCommandCluster:currentCommandCluster];
        float clusterYCoordinate = self.frame.size.height - trackIndex * CHANNEL_HEIGHT - tracksTall * CHANNEL_HEIGHT - TOP_BAR_HEIGHT + 1;
        float clusterHeight = CHANNEL_HEIGHT * tracksTall - 2;
        
        // Command Cluster is for this controlBox/channelGroup
        if((isControlBox ? [[data controlBoxFilePathForCommandCluster:currentCommandCluster] isEqualToString:[data controlBoxFilePathAtIndex:parentIndex forSequence:[data currentSequence]]] : [[data channelGroupFilePathForCommandCluster:currentCommandCluster] isEqualToString:[data channelGroupFilePathAtIndex:parentIndex forSequence:[data currentSequence]]]))
        {
            // Check to see if this commandCluster is in the visible range
            if(((startTime > timeAtLeftEdge && startTime < timeAtRightEdge) || (endTime > timeAtLeftEdge && endTime < timeAtRightEdge) || (startTime <= timeAtLeftEdge && endTime >= timeAtRightEdge)) && ((clusterYCoordinate > visibleRect.origin.y && clusterYCoordinate < visibleRect.origin.y + visibleRect.size.height) || (clusterYCoordinate + clusterHeight > visibleRect.origin.y && clusterYCoordinate + clusterHeight < visibleRect.origin.y + visibleRect.size.height) || (clusterYCoordinate <= visibleRect.origin.y && clusterYCoordinate + clusterHeight >= visibleRect.origin.y + visibleRect.size.height)))
            {
                NSRect commandClusterRect = NSMakeRect([data timeToX:startTime], clusterYCoordinate, [data widthForTimeInterval:endTime - startTime], clusterHeight);
                
                // There is a mouse event within the bounds of the commandCluster
                if(mouseEvent != nil && ([[NSBezierPath bezierPathWithRect:commandClusterRect] containsPoint:currentMousePoint] || ((mouseDraggingEvent == MNControlBoxCommandClusterMouseDrag || mouseDraggingEvent == MNControlBoxCommandClusterMouseDragStartTime || mouseDraggingEvent == MNControlBoxCommandClusterMouseDragEndTime || mouseDraggingEvent == MNControlBoxCommandClusterMouseDragBetweenChannels) && (mouseDraggingEventObjectIndex == -1 || mouseDraggingEventObjectIndex == i))))
                {
                    // Check the commands for mouse down clicks
                    [self checkCommandClusterForCommandMouseEvent:currentCommandCluster atTrackIndex:trackIndex tracksTall:tracksTall forControlBoxOrChannelGroup:MNChannelGroup];
                    
                    // Check for new command clicks
                    if(mouseEvent != nil && mouseAction == MNMouseDown && mouseEvent.modifierFlags & NSCommandKeyMask)
                    {
                        int channelIndex = (self.frame.size.height - currentMousePoint.y - (trackIndex * CHANNEL_HEIGHT + TOP_BAR_HEIGHT + 1)) / CHANNEL_HEIGHT;
                        float time = [data xToTime:currentMousePoint.x];
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"AddCommandAtChannelIndexAndTimeForCommandCluster" object:nil userInfo:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSNumber numberWithInt:channelIndex], [NSNumber numberWithFloat:time], currentCommandCluster, nil] forKeys:[NSArray arrayWithObjects:@"channelIndex", @"startTime", @"commandCluster", nil]]];
                        int newCommandIndex = [data commandsCountForCommandCluster:currentCommandCluster] - 1;
                        
                        mouseDraggingEvent = MNCommandMouseDragEndTime;
                        mouseClickDownPoint.x = mouseClickDownPoint.x - [data timeToX:[data endTimeForCommand:[data commandAtIndex:newCommandIndex fromCommandCluster:currentCommandCluster]]];
                        
                        selectedCommandIndex = newCommandIndex;
                        commandClusterIndexForSelectedCommand = (int)[[data commandClusterFilePathsForSequence:[data currentSequence]] indexOfObject:[data filePathForCommandCluster:currentCommandCluster]];
                        
                        mouseEvent = nil;
                    }
                    
                    // If a command didn't capture the mouse event, the commandCluster uses it
                    if(mouseEvent != nil)
                    {
                        // Cluster Mouse Checking Here
                        if(mouseAction == MNMouseDown)
                        {
                            // Duplicate a cluster if it's 'option clicked'
                            if(mouseEvent.modifierFlags & NSAlternateKeyMask)
                            {
                                NSString *newCommandClusterFilePath = [data createCopyOfCommandClusterAndReturnFilePath:currentCommandCluster];
                                [data addCommandClusterFilePath:newCommandClusterFilePath forSequence:[data currentSequence]];
                                
                                if(mouseEvent.modifierFlags & NSControlKeyMask)
                                {
                                    mouseDraggingEvent = MNControlBoxCommandClusterMouseDragBetweenChannels;
                                }
                                else
                                {
                                    mouseDraggingEvent = MNControlBoxCommandClusterMouseDrag;
                                }
                                mouseClickDownPoint.x = mouseClickDownPoint.x - [data timeToX:startTime];
                                self.selectedCommandClusterIndex = (int)[data commandClusterFilePathsCountForSequence:[data currentSequence]] - 1;
                                highlightedACluster = YES; // Trick the system
                                [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateLibraryContent" object:nil];
                                [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateLibrariesViewController" object:nil];
                                [[NSNotificationCenter defaultCenter] postNotificationName:@"SelectCommandCluster" object:[data commandClusterFromFilePath:newCommandClusterFilePath]];
                            }
                            else if(mouseEvent.modifierFlags & NSControlKeyMask)
                            {
                                mouseDraggingEvent = MNControlBoxCommandClusterMouseDragBetweenChannels;
                                mouseClickDownPoint.x = mouseClickDownPoint.x - [data timeToX:startTime];
                                
                                self.selectedCommandClusterIndex = i;
                                [[NSNotificationCenter defaultCenter] postNotificationName:@"SelectCommandCluster" object:currentCommandCluster];
                            }
                            // Select a cluster
                            else
                            {
                                // Adjust start time
                                if(currentMousePoint.x <= commandClusterRect.origin.x + TIME_ADJUST_PIXEL_BUFFER)
                                {
                                    mouseDraggingEvent = MNControlBoxCommandClusterMouseDragStartTime;
                                    mouseClickDownPoint.x = mouseClickDownPoint.x - [data timeToX:startTime];
                                }
                                // Adjust the end time
                                else if(currentMousePoint.x >= commandClusterRect.origin.x + commandClusterRect.size.width - TIME_ADJUST_PIXEL_BUFFER)
                                {
                                    mouseDraggingEvent = MNControlBoxCommandClusterMouseDragEndTime;
                                    mouseClickDownPoint.x = mouseClickDownPoint.x - [data timeToX:endTime];
                                }
                                // Just select the cluster
                                else
                                {
                                    mouseDraggingEvent = MNControlBoxCommandClusterMouseDrag;
                                    mouseClickDownPoint.x = mouseClickDownPoint.x - [data timeToX:startTime];
                                }
                                
                                self.selectedCommandClusterIndex = i;
                                [[NSNotificationCenter defaultCenter] postNotificationName:@"SelectCommandCluster" object:currentCommandCluster];
                            }
                            
                            mouseEvent = nil;
                        }
                        // Dragging of clusters
                        else if(mouseAction == MNMouseDragged && i == selectedCommandClusterIndex)
                        {
                            // Drag the start Time
                            if(mouseDraggingEvent == MNControlBoxCommandClusterMouseDragStartTime)
                            {
                                [data setStartTime:[data xToTime:currentMousePoint.x - mouseClickDownPoint.x] forCommandCluster:currentCommandCluster];
                            }
                            // Drag the end time
                            else if(mouseDraggingEvent == MNControlBoxCommandClusterMouseDragEndTime)
                            {
                                [data setEndTime:[data xToTime:currentMousePoint.x - mouseClickDownPoint.x] forCommandcluster:currentCommandCluster];
                            }
                            // Drag the entire cluster
                            else if(mouseDraggingEvent == MNControlBoxCommandClusterMouseDrag)
                            {
                                // Drag the cluster
                                [data moveCommandCluster:currentCommandCluster toStartTime:[data xToTime:currentMousePoint.x - mouseClickDownPoint.x]];
                                
                                // Mouse drag is moving the cluster to a different controlBox
                                if(currentMousePoint.y > commandClusterRect.origin.y + commandClusterRect.size.height || currentMousePoint.y < commandClusterRect.origin.y)
                                {
                                    int newTrackIndex = (self.frame.size.height - currentMousePoint.y - TOP_BAR_HEIGHT) / CHANNEL_HEIGHT;
                                    int newIndex = [self controlBoxIndexForTrackIndex:newTrackIndex];
                                    //NSLog(@"newI:%d mouseY:%f newTrackIndex:%d trackIndex:%d", newIndex, self.frame.size.height - currentMousePoint.y - TOP_BAR_HEIGHT, newTrackIndex, trackIndex);
                                    [data setControlBoxFilePath:[data controlBoxFilePathAtIndex:newIndex forSequence:[data currentSequence]] forCommandCluster:currentCommandCluster];
                                }
                            }
                            else if(mouseDraggingEvent == MNControlBoxCommandClusterMouseDragBetweenChannels)
                            {
                                // Mouse drag is moving the cluster to a different controlBox
                                if(currentMousePoint.y > commandClusterRect.origin.y + commandClusterRect.size.height || currentMousePoint.y < commandClusterRect.origin.y)
                                {
                                    int newTrackIndex = (self.frame.size.height - currentMousePoint.y - TOP_BAR_HEIGHT) / CHANNEL_HEIGHT;
                                    int newIndex = [self controlBoxIndexForTrackIndex:newTrackIndex];
                                    [data setControlBoxFilePath:[data controlBoxFilePathAtIndex:newIndex forSequence:[data currentSequence]] forCommandCluster:currentCommandCluster];
                                }
                            }
                            
                            mouseDraggingEventObjectIndex = i;
                            self.selectedCommandClusterIndex = i;
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateLibraryContent" object:nil];
                            
                            mouseEvent = nil;
                        }
                        // Mouse up
                        else if(i == selectedCommandClusterIndex)
                        {
                            selectedCommandClusterIndex = -1;
                            
                            mouseEvent = nil;
                        }
                        
                        // Draw this cluster as selected
                        if(i == selectedCommandClusterIndex)
                        {
                            [self drawRect:commandClusterRect withCornerRadius:CLUSTER_CORNER_RADIUS fillColor:[NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:0.7] andStroke:YES];
                            highlightedACluster = YES;
                        }
                        // Else just draw normally
                        else
                        {
                            [self drawRect:commandClusterRect withCornerRadius:CLUSTER_CORNER_RADIUS fillColor:[NSColor colorWithDeviceRed:0.2 green:0.4 blue:0.2 alpha:0.7] andStroke:YES];
                        }
                    }
                    // Else just draw normally
                    else
                    {
                        [self drawRect:commandClusterRect withCornerRadius:CLUSTER_CORNER_RADIUS fillColor:[NSColor colorWithDeviceRed:0.2 green:0.4 blue:0.2 alpha:0.7] andStroke:YES];
                    }
                }
                // No mouse events within the bounds of this cluster. Just draw everything normally
                else
                {
                    // Check the commands for mouse down clicks
                    [self checkCommandClusterForCommandMouseEvent:currentCommandCluster atTrackIndex:trackIndex tracksTall:tracksTall forControlBoxOrChannelGroup:MNChannelGroup];
                    
                    // Draw this cluster
                    [self drawRect:commandClusterRect withCornerRadius:CLUSTER_CORNER_RADIUS fillColor:[NSColor colorWithDeviceRed:0.2 green:0.4 blue:0.2 alpha:0.7] andStroke:YES];
                }
                
                // Draw the commands for this cluster
                [self drawCommandsForCommandCluster:currentCommandCluster atTrackIndex:trackIndex tracksTall:tracksTall forControlBoxOrChannelGroup:MNControlBox];
            }
        }
    }
}

- (void)drawCommandsForCommandCluster:(NSMutableDictionary *)commandCluster atTrackIndex:(int)trackIndex tracksTall:(int)tracksTall forControlBoxOrChannelGroup:(int)boxOrChannelGroup
{
    tracksTall = 1;
    int startingTrackIndex = trackIndex;
    int commandClusterIndex = (int)[[data commandClusterFilePathsForSequence:[data currentSequence]] indexOfObject:[data filePathForCommandCluster:commandCluster]];
    
    NSRect superViewFrame = [[self superview] frame];
    float timeSpan = [data xToTime:[data timeToX:[data timeAtLeftEdgeOfTimelineView]] + superViewFrame.size.width] - [data timeAtLeftEdgeOfTimelineView];
    float timeAtLeftEdge = [data timeAtLeftEdgeOfTimelineView];
    float timeAtRightEdge = timeAtLeftEdge + timeSpan;
    
    for(int i = 0; i < [data commandsCountForCommandCluster:commandCluster]; i ++)
    {
        NSMutableDictionary *currentCommand = [data commandAtIndex:i fromCommandCluster:commandCluster];
        trackIndex = [data channelIndexForCommand:currentCommand] + startingTrackIndex;
        float startTime = [data startTimeForCommand:currentCommand];
        float endTime = [data endTimeForCommand:currentCommand];
        
        // Check to see if this commandCluster is in the visible range
        if((startTime > timeAtLeftEdge && startTime < timeAtRightEdge) || (endTime > timeAtLeftEdge && endTime < timeAtRightEdge) || (startTime <= timeAtLeftEdge && endTime >= timeAtRightEdge))
        {
            NSRect commandRect;
            float x, y, width , height;
            x  = [data timeToX:startTime];
            y = self.frame.size.height - trackIndex * CHANNEL_HEIGHT - tracksTall * CHANNEL_HEIGHT - TOP_BAR_HEIGHT + 1;
            width = [data widthForTimeInterval:endTime - startTime];
            height = CHANNEL_HEIGHT - 2;
            
            // Command extends over the end of it's parent cluster, bind it to the end of the parent cluster
            if(endTime > [data endTimeForCommandCluster:commandCluster])
            {
                width = [data widthForTimeInterval:[data endTimeForCommandCluster:commandCluster] - startTime];
            }
            // Command extends over the beggining of it's parent cluster, bind it to the beginning of the parent cluster
            else if(startTime < [data startTimeForCommandCluster:commandCluster])
            {
                x = [data timeToX:[data startTimeForCommandCluster:commandCluster]];
                width = [data widthForTimeInterval:endTime - [data xToTime:x]];
            }
            commandRect = NSMakeRect(x, y, width, height);
            
            // Draw the command
            if(selectedCommandIndex == i && commandClusterIndexForSelectedCommand == commandClusterIndex)
            {
                [self drawRect:commandRect withCornerRadius:COMMAND_CORNER_RADIUS fillColor:[NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:0.7] andStroke:YES];
            }
            else
            {
                [self drawRect:commandRect withCornerRadius:COMMAND_CORNER_RADIUS fillColor:[NSColor colorWithDeviceRed:0.3 green:1.0 blue:0.3 alpha:0.7] andStroke:YES];
            }
        }
    }
}*/

#pragma mark - Math Methods

- (void)updateTimeAtLeftEdgeOfTimelineView:(NSTimer *)theTimer;
{
    if(mouseEvent)
    {
        BOOL didAutoscroll = [[self superview] autoscroll:mouseEvent];
        if(didAutoscroll)
        {
            self.currentTime = [self xToTime:self.currentTime + mouseEvent.deltaX];
            [self setNeedsDisplay:YES];
        }
    }
}

- (float)roundUpNumber:(float)numberToRound toNearestMultipleOfNumber:(float)multiple
{
    // Only works to the nearest thousandth
    int intNumberToRound = (int)(numberToRound * 1000000);
    int intMultiple = (int)(multiple * 1000000);
    
    if(multiple == 0)
    {
        return intNumberToRound / 1000000;
    }
    
    int remainder = intNumberToRound % intMultiple;
    if(remainder == 0)
    {
        return intNumberToRound / 1000000;
    }
    
    return (intNumberToRound + intMultiple - remainder) / 1000000.0;
}

- (int)controlBoxIndexForTrackIndex:(int)trackIndex
{
    int controlBoxIndex = -1;
    int i = 0;
    
    while(controlBoxIndex == -1 && controlBoxTrackIndexes[i] >= 0)
    {
        if(trackIndex >= controlBoxTrackIndexes[i] && (trackIndex < controlBoxTrackIndexes[i + 1] || controlBoxTrackIndexes[i + 1] == -1))
        {
            controlBoxIndex = i;
        }
        
        i ++;
    }
    
    return controlBoxIndex;
}

#pragma mark - Mouse Checking Methods

- (void)timelineBarMouseChecking
{
    // Draw the Top Bar
    NSRect topBarFrame = NSMakeRect(HEADER_TOTAL_WIDTH, visibleFrame.origin.y, self.frame.size.width, TOP_BAR_HEIGHT);
    
    NSPoint trianglePoint = NSMakePoint((float)[self timeToX:self.currentTime], topBarFrame.origin.y + TOP_BAR_HEIGHT);
    NSBezierPath *triangle = [NSBezierPath bezierPath];
    float width = TOP_BAR_HEIGHT;
    float height = TOP_BAR_HEIGHT;
    [triangle moveToPoint:trianglePoint];
    [triangle lineToPoint:NSMakePoint(trianglePoint.x - width / 2,  trianglePoint.y - height)];
    [triangle lineToPoint:NSMakePoint(trianglePoint.x + width / 2, trianglePoint.y - height)];
    [triangle closePath];
    
    // CurrentTime Marker Mouse checking
    if([triangle containsPoint:currentMousePoint] && mouseAction == MNMouseDown && mouseEvent != nil)
    {
        currentTimeMarkerIsSelected = YES;
        mouseEvent = nil;
    }
    else if(currentTimeMarkerIsSelected && mouseAction == MNMouseUp && mouseEvent != nil)
    {
        currentTimeMarkerIsSelected = NO;
        mouseEvent = nil;
    }
    
    // Mouse Checking
    if(mouseAction == MNMouseDragged && (mouseDraggingEvent == MNMouseDragNotInUse || mouseDraggingEvent == MNTimeMarkerMouseDrag) && currentTimeMarkerIsSelected && mouseEvent != nil)
    {
        mouseDraggingEvent = MNTimeMarkerMouseDrag;
        mouseDraggingEventObjectIndex = -1;
        float newCurrentTime = [self xToTime:currentMousePoint.x];
        
        // Bind the minimum time to 0
        if(newCurrentTime < 0.0)
        {
            newCurrentTime = 0.0;
        }
        
        // Move the cursor to the new position
        self.currentTime = newCurrentTime;
    }
    
    // TopBar Mouse Checking
    if([[NSBezierPath bezierPathWithRect:topBarFrame] containsPoint:currentMousePoint] && mouseAction == MNMouseDown && mouseEvent != nil && !currentTimeMarkerIsSelected)
    {
        self.currentTime = [self xToTime:currentMousePoint.x];
        mouseEvent = nil;
    }
}

- (void)handleEmptySpaceMouseAction
{
    // Check for new command clicks
    /*if(mouseEvent != nil && mouseAction == MNMouseDown && mouseEvent.modifierFlags & NSCommandKeyMask)
    {
        BOOL clusterWasCreated = NO;
        int trackIndex = 0;
        int tracksTall = 0;
        // Calculate the audio track
        if([data audioClipFilePathsCountForSequence:[data currentSequence]] > 0)
        {
            tracksTall = [data audioClipFilePathsCountForSequence:[data currentSequence]];
            trackIndex += tracksTall;
        }
        // Calculate the controlBox tracks
        for(int i = 0; (i < [data controlBoxFilePathsCountForSequence:[data currentSequence]] && clusterWasCreated == NO); i ++)
        {
            tracksTall = [data channelsCountForControlBox:[data controlBoxForCurrentSequenceAtIndex:i]];
            
            // Detemine the rect
            NSRect trackGroupRect = NSMakeRect(0, self.frame.size.height - trackIndex * CHANNEL_HEIGHT - tracksTall * CHANNEL_HEIGHT - TOP_BAR_HEIGHT, self.frame.size.width, CHANNEL_HEIGHT * tracksTall);
            
            // Check for the mouse point within the trackGroupRect
            if([[NSBezierPath bezierPathWithRect:trackGroupRect] containsPoint:currentMousePoint])
            {
                clusterWasCreated = YES;
                
                // Create the new cluster
                float time = [data xToTime:currentMousePoint.x];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"AddCommandClusterForControlBoxFilePathAndStartTime" object:nil userInfo:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[data controlBoxFilePathAtIndex:i forSequence:[data currentSequence]], [NSNumber numberWithFloat:time], nil] forKeys:[NSArray arrayWithObjects:@"controlBoxFilePath", @"startTime", nil]]];
                
                // Select it for end time dragging
                mouseDraggingEvent = MNControlBoxCommandClusterMouseDragEndTime;
                mouseClickDownPoint.x = mouseClickDownPoint.x - [data timeToX:time];
                self.selectedCommandClusterIndex = [data commandClusterFilePathsCountForSequence:[data currentSequence]] - 1;
                
                mouseEvent = nil;
            }
            
            trackIndex += tracksTall;
        }
        // Calculate the channelGroup tracks
        for(int i = 0; (i < [data channelGroupFilePathsCountForSequence:[data currentSequence]] && clusterWasCreated == NO); i ++)
        {
            tracksTall = [data itemsCountForChannelGroup:[data channelGroupForCurrentSequenceAtIndex:i]];
            
            // Detemine the rect
            NSRect trackGroupRect = NSMakeRect(0, self.frame.size.height - trackIndex * CHANNEL_HEIGHT - tracksTall * CHANNEL_HEIGHT - TOP_BAR_HEIGHT, self.frame.size.width, CHANNEL_HEIGHT * tracksTall);
            
            // Check for the mouse point within the trackGroupRect
            if([[NSBezierPath bezierPathWithRect:trackGroupRect] containsPoint:currentMousePoint])
            {
                clusterWasCreated = YES;
                
                // Create the new cluster
                float time = [data xToTime:currentMousePoint.x];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"AddCommandClusterForChannelGroupFilePathAndStartTime" object:nil userInfo:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[data channelGroupFilePathAtIndex:i forSequence:[data currentSequence]], [NSNumber numberWithFloat:time], nil] forKeys:[NSArray arrayWithObjects:@"channelGroupFilePath", @"startTime", nil]]];
                
                // Select it for end time dragging
                mouseDraggingEvent = MNControlBoxCommandClusterMouseDragEndTime;
                mouseClickDownPoint.x = mouseClickDownPoint.x - [data timeToX:time];
                self.selectedCommandClusterIndex = [data commandClusterFilePathsCountForSequence:[data currentSequence]] - 1;
                mouseEvent = nil;
            }
            
            trackIndex += tracksTall;
        }
    }*/
}

/*- (void)checkCommandClusterForCommandMouseEvent:(NSMutableDictionary *)commandCluster atTrackIndex:(int)trackIndex tracksTall:(int)tracksTall forControlBoxOrChannelGroup:(int)boxOrChannelGroup
{
    tracksTall = 1;
    int startingTrackIndex = trackIndex;
    
    for(int i = 0; i < [data commandsCountForCommandCluster:commandCluster]; i ++)
    {
        NSMutableDictionary *currentCommand = [data commandAtIndex:i fromCommandCluster:commandCluster];
        trackIndex = [data channelIndexForCommand:currentCommand] + startingTrackIndex;
        float startTime = [data startTimeForCommand:currentCommand];
        float endTime = [data endTimeForCommand:currentCommand];
        
        BOOL valildCommand = YES;
        NSRect commandRect;
        float x, y, width , height;
        x  = [data timeToX:startTime];
        y = self.frame.size.height - trackIndex * CHANNEL_HEIGHT - tracksTall * CHANNEL_HEIGHT - TOP_BAR_HEIGHT + 1;
        width = [data widthForTimeInterval:endTime - startTime];
        height = CHANNEL_HEIGHT - 2;
        
        // Command extends over the beggining of it's parent cluster, bind it to the beginning of the parent cluster
        if(startTime < [data startTimeForCommandCluster:commandCluster])
        {
            x = [data timeToX:[data startTimeForCommandCluster:commandCluster]];
            
            // Command is not visible within this cluster
            if(endTime <= [data startTimeForCommandCluster:commandCluster])
            {
                valildCommand = NO;
            }
            // Command end time is valid
            else if(endTime < [data endTimeForCommandCluster:commandCluster])
            {
                width = [data widthForTimeInterval:endTime - [data startTimeForCommandCluster:commandCluster]];
            }
            // Command extends over the end of it's parent cluster, bind it to the end of the parent cluster
            else if(endTime >= [data endTimeForCommandCluster:commandCluster])
            {
                width = [data widthForTimeInterval:[data endTimeForCommandCluster:commandCluster] - [data startTimeForCommandCluster:commandCluster]];
            }
        }
        // Command extends over the end of it's parent cluster, bind it to the end of the parent cluster
        else if(endTime > [data endTimeForCommandCluster:commandCluster])
        {
            // Command is not visible within this cluster
            if(startTime >= [data endTimeForCommandCluster:commandCluster])
            {
                valildCommand = NO;
            }
            // Command start time is valid
            else if(startTime > [data startTimeForCommandCluster:commandCluster])
            {
                width = [data widthForTimeInterval:[data endTimeForCommandCluster:commandCluster] - startTime];
            }
            // Command extends over the end of it's parent cluster, bind it to the end of the parent cluster
            else
            {
                x = [data timeToX:[data startTimeForCommandCluster:commandCluster]];
                width = [data widthForTimeInterval:[data endTimeForCommandCluster:commandCluster] - [data startTimeForCommandCluster:commandCluster]];
            }
        }
        
        commandRect = NSMakeRect(x, y, width, height);
        
        // Command Mouse Checking Here
        if(mouseEvent != nil && (mouseAction == MNMouseDown && [[NSBezierPath bezierPathWithRect:commandRect] containsPoint:currentMousePoint]) && valildCommand)
        {
            // Delete a command if it's 'command clicked'
            if(mouseEvent.modifierFlags & NSCommandKeyMask)
            {
                [data removeCommand:currentCommand fromCommandCluster:commandCluster];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateLibraryContent" object:nil];
            }
            // Duplicate a command if it's 'option clicked'
            else if(mouseEvent.modifierFlags & NSAlternateKeyMask)
            {
                int newCommandIndex = [data createCommandAndReturnNewCommandIndexForCommandCluster:commandCluster];
                [data setStartTime:startTime forCommandAtIndex:newCommandIndex whichIsPartOfCommandCluster:commandCluster];
                [data setEndTime:endTime forCommandAtIndex:newCommandIndex whichIsPartOfCommandCluster:commandCluster];
                [data setChannelIndex:[data channelIndexForCommand:currentCommand] forCommandAtIndex:newCommandIndex whichIsPartOfCommandCluster:commandCluster];
                [data setBrightness:[data brightnessForCommand:currentCommand] forCommandAtIndex:newCommandIndex whichIsPartOfCommandCluster:commandCluster];
                
                if(mouseEvent.modifierFlags & NSControlKeyMask)
                {
                    mouseDraggingEvent = MNCommandMouseDragBetweenChannels;
                }
                else
                {
                    mouseDraggingEvent = MNCommandMouseDrag;
                }
                mouseClickDownPoint.x = mouseClickDownPoint.x - [data timeToX:[data startTimeForCommand:[data commandAtIndex:newCommandIndex fromCommandCluster:commandCluster]]];
                
                selectedCommandIndex = newCommandIndex;
                commandClusterIndexForSelectedCommand = (int)[[data commandClusterFilePathsForSequence:[data currentSequence]] indexOfObject:[data filePathForCommandCluster:commandCluster]];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateLibraryContent" object:nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"SelectCommand" object:[NSArray arrayWithObjects:[NSNumber numberWithInt:selectedCommandIndex], [data filePathForCommandCluster:commandCluster], nil]];
            }
            // Select a command and lock the start/end times
            else if(mouseEvent.modifierFlags & NSControlKeyMask)
            {
                mouseDraggingEvent = MNCommandMouseDragBetweenChannels;
                mouseClickDownPoint.x = mouseClickDownPoint.x - [data timeToX:startTime];
                
                selectedCommandIndex = i;
                commandClusterIndexForSelectedCommand = (int)[[data commandClusterFilePathsForSequence:[data currentSequence]] indexOfObject:[data filePathForCommandCluster:commandCluster]];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"SelectCommand" object:[NSArray arrayWithObjects:[NSNumber numberWithInt:selectedCommandIndex], [data filePathForCommandCluster:commandCluster], nil]];
            }
            // Select a command
            else
            {
                // Adjust start time
                if(currentMousePoint.x <= x + TIME_ADJUST_PIXEL_BUFFER)
                {
                    mouseDraggingEvent = MNCommandMouseDragStartTime;
                    mouseClickDownPoint.x = mouseClickDownPoint.x - [data timeToX:startTime];
                }
                // Adjust the end time
                else if(currentMousePoint.x >= x + width - TIME_ADJUST_PIXEL_BUFFER)
                {
                    mouseDraggingEvent = MNCommandMouseDragEndTime;
                    mouseClickDownPoint.x = mouseClickDownPoint.x - [data timeToX:endTime];
                }
                else
                {
                    mouseDraggingEvent = MNCommandMouseDrag;
                    mouseClickDownPoint.x = mouseClickDownPoint.x - [data timeToX:startTime];
                }
                
                selectedCommandIndex = i;
                commandClusterIndexForSelectedCommand = (int)[[data commandClusterFilePathsForSequence:[data currentSequence]] indexOfObject:[data filePathForCommandCluster:commandCluster]];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"SelectCommand" object:[NSArray arrayWithObjects:[NSNumber numberWithInt:selectedCommandIndex], [data filePathForCommandCluster:commandCluster], nil]];
            }
            
            mouseEvent = nil;
        }
        // Dragging of commands
        else if(mouseEvent != nil && mouseAction == MNMouseDragged && i == selectedCommandIndex && commandClusterIndexForSelectedCommand == (int)[[data commandClusterFilePathsForSequence:[data currentSequence]] indexOfObject:[data filePathForCommandCluster:commandCluster]])
        {
            if(mouseDraggingEvent == MNCommandMouseDragStartTime)
            {
                [data setStartTime:[data xToTime:currentMousePoint.x - mouseClickDownPoint.x] forCommandAtIndex:i whichIsPartOfCommandCluster:commandCluster];
            }
            else if(mouseDraggingEvent == MNCommandMouseDragEndTime)
            {
                [data setEndTime:[data xToTime:currentMousePoint.x - mouseClickDownPoint.x] forCommandAtIndex:i whichIsPartOfCommandCluster:commandCluster];
            }
            else if(mouseDraggingEvent == MNCommandMouseDrag)
            {
                mouseDraggingEvent = MNCommandMouseDrag;
                // Drag the command
                [data moveCommandAtIndex:i toStartTime:[data xToTime:currentMousePoint.x - mouseClickDownPoint.x] whichIsPartOfCommandCluster:commandCluster];
                
                // Mouse drag is changing the channel index
                if(currentMousePoint.y > y + height || currentMousePoint.y < y)
                {
                    int newIndex = (self.frame.size.height - currentMousePoint.y - TOP_BAR_HEIGHT) / CHANNEL_HEIGHT - startingTrackIndex;
                    [data setChannelIndex:newIndex forCommandAtIndex:i whichIsPartOfCommandCluster:commandCluster];
                }
            }
            else if(mouseDraggingEvent == MNCommandMouseDragBetweenChannels)
            {
                // Mouse drag is changing the channel index
                if(currentMousePoint.y > y + height || currentMousePoint.y < y)
                {
                    int newIndex = (self.frame.size.height - currentMousePoint.y - TOP_BAR_HEIGHT) / CHANNEL_HEIGHT - startingTrackIndex;
                    [data setChannelIndex:newIndex forCommandAtIndex:i whichIsPartOfCommandCluster:commandCluster];
                }
            }
            
            mouseDraggingEventObjectIndex = i;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateLibraryContent" object:nil];
            
            mouseEvent = nil;
        }
        else if(mouseEvent != nil && i == selectedCommandIndex && commandClusterIndexForSelectedCommand == (int)[[data commandClusterFilePathsForSequence:[data currentSequence]] indexOfObject:[data filePathForCommandCluster:commandCluster]])
        {
            selectedCommandIndex = -1;
            commandClusterIndexForSelectedCommand = -1;
            
            mouseEvent = nil;
        }
    }
}*/

#pragma mark Mouse Methods

- (void)mouseDown:(NSEvent *)theEvent
{
    NSPoint eventLocation = [theEvent locationInWindow];
    currentMousePoint = [self convertPoint:eventLocation fromView:nil];
    mouseClickDownPoint = currentMousePoint;
    mouseAction = MNMouseDown;
    mouseEvent = theEvent;
    
    [autoScrollTimer invalidate];
    autoScrollTimer = nil;
    autoScrollTimer = [NSTimer scheduledTimerWithTimeInterval:AUTO_SCROLL_REFRESH_RATE target:self selector:@selector(updateTimeAtLeftEdgeOfTimelineView:) userInfo:nil repeats:YES];
    autoscrollTimerIsRunning = YES;
    
    [self setNeedsDisplay:YES];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    NSPoint eventLocation = [theEvent locationInWindow];
    currentMousePoint = [self convertPoint:eventLocation fromView:nil];
    mouseAction = MNMouseDragged;
    mouseEvent = theEvent;
    [self setNeedsDisplay:YES];
}

- (void)mouseUp:(NSEvent *)theEvent
{
    NSPoint eventLocation = [theEvent locationInWindow];
    currentMousePoint = [self convertPoint:eventLocation fromView:nil];
    mouseAction = MNMouseUp;
    mouseEvent = theEvent;
    mouseDraggingEvent = MNMouseDragNotInUse;
    mouseDraggingEventObjectIndex = -1;
    
    [autoScrollTimer invalidate];
    autoScrollTimer = nil;
    autoscrollTimerIsRunning = NO;
    
    [self setNeedsDisplay:YES];
}

#pragma mark - Keyboard Methods

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (void)keyDown:(NSEvent *)keyboardEvent
{
    NSLog(@"keyDown");
    // Check for new command clicks
    /*if(keyboardEvent.keyCode == 40 && ![keyboardEvent isARepeat])
    {
        //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(){
        int channelIndex = 0;
        NSMutableDictionary *commandCluster = [data commandClusterForCurrentSequenceAtIndex:data.mostRecentlySelectedCommandClusterIndex];
        float time = [data currentTime];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"AddCommandAtChannelIndexAndTimeForCommandCluster" object:nil userInfo:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSNumber numberWithInt:channelIndex], [NSNumber numberWithFloat:time], commandCluster, nil] forKeys:[NSArray arrayWithObjects:@"channelIndex", @"startTime", @"commandCluster", nil]]];
        //});
        
        //int newCommandIndex = [data commandsCountForCommandCluster:commandCluster] - 1;
         
         //mouseDraggingEvent = MNCommandMouseDragEndTime;
         //mouseClickDownPoint.x = mouseClickDownPoint.x - [data timeToX:[data endTimeForCommand:[data commandAtIndex:newCommandIndex fromCommandCluster:commandCluster]]];
         
         //selectedCommandIndex = newCommandIndex;
         //commandClusterIndexForSelectedCommand = (int)[[data commandClusterFilePathsForSequence:[data currentSequence]] indexOfObject:[data filePathForCommandCluster:commandCluster]];
         
         //mouseEvent = nil;
    }
    else if(keyboardEvent.keyCode != 40)
    {
        [super keyDown:keyboardEvent];
    }*/
}

- (void)keyUp:(NSEvent *)keyboardEvent
{
    NSLog(@"keyUp");
    // Check for new command clicks
    /*if(keyboardEvent.keyCode == 40 && ![keyboardEvent isARepeat])
    {
        //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(){
        NSMutableDictionary *commandCluster = [data commandClusterForCurrentSequenceAtIndex:data.mostRecentlySelectedCommandClusterIndex];
        float time = [data currentTime];
        int newCommandIndex = [data commandsCountForCommandCluster:commandCluster] - 1;
        [data setEndTime:time forCommandAtIndex:newCommandIndex whichIsPartOfCommandCluster:commandCluster];
        //});
 
         //mouseDraggingEvent = MNCommandMouseDragEndTime;
         //mouseClickDownPoint.x = mouseClickDownPoint.x - [data timeToX:[data endTimeForCommand:[data commandAtIndex:newCommandIndex fromCommandCluster:commandCluster]]];
         
         //selectedCommandIndex = newCommandIndex;
         //commandClusterIndexForSelectedCommand = (int)[[data commandClusterFilePathsForSequence:[data currentSequence]] indexOfObject:[data filePathForCommandCluster:commandCluster]];
         
         //mouseEvent = nil;
    }*/
}

@end
