//
//  GameScene.m
//  LightMaster2014
//
//  Created by James Adams on 11/28/14.
//  Copyright (c) 2014 James Adams. All rights reserved.
//

#import "GameScene.h"
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
#import "EchoNestAudioAnalysis.h"
#import "EchoNestMeta.h"

#define CLUSTER_CORNER_RADIUS 5.0
#define COMMAND_CORNER_RADIUS 3.0
#define AUTO_SCROLL_REFRESH_RATE 0.03
#define TIME_ADJUST_PIXEL_BUFFER 8.0
#define PIXEL_TO_ZOOM_RATIO 25
#define CHANNEL_HEIGHT 20.0
#define TIMELINE_BAR_HEIGHT 20.0
#define HEADER_WIDTH 100.0
#define HEADER_DETAIL_WIDTH 100.0
#define HEADER_TOTAL_WIDTH HEADER_WIDTH + HEADER_DETAIL_WIDTH


@interface GameScene()

@property (strong, nonatomic) SKSpriteNode *channelContainerNode;

@property (strong, nonatomic) SKShapeNode *timelineBarNode;
@property (strong, nonatomic) SKShapeNode *timelineTriangleNode;
@property (strong, nonatomic) SKShapeNode *timelineRedLineNode;
@property (strong, nonatomic) NSMutableArray *timelineTextNodes;

@property (nonatomic, strong) SKSpriteNode *background;

@property (nonatomic, strong) SKNode *selectedNode;
@property (nonatomic, assign) float previousLocationX;
@property (nonatomic, assign) float previousLocationY;

@end

@implementation GameScene

#pragma mark - Init

-(void)didMoveToView:(SKView *)view
{
    self.zoomLevel = 3.0;
    
    // Init arrays
    self.timelineTextNodes = [NSMutableArray new];
    
    [self addBackground];
    //[self addChannelHeaders];
    [self updateTimelineBar];
}

#pragma mark - Math Methods

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

#pragma mark - Helper Drawing Methods

- (void)addShapeNodeRectForChannelAtX:(float)x y:(float)y width:(float)width height:(float)height color:(NSColor *)color parent:(SKNode *)parent
{
    [self addShapeWithRect:NSMakeRect(x, self.frame.size.height - TIMELINE_BAR_HEIGHT - (y * CHANNEL_HEIGHT) - 1, width, height * CHANNEL_HEIGHT - 2) cornerRadius:COMMAND_CORNER_RADIUS fillColor:color stroke:YES parentNode:parent];
}

- (SKShapeNode *)addShapeWithRect:(NSRect)rect cornerRadius:(float)radius fillColor:(NSColor *)color stroke:(BOOL)stroke parentNode:(SKNode *)parent
{
    CGMutablePathRef myPath = CGPathCreateMutable();
    CGPathAddRoundedRect(myPath, NULL, rect, radius, radius);
    
    return [self addShapeWithPathRef:myPath cornerRadius:radius fillColor:color stroke:stroke parentNode:parent];
}

- (SKShapeNode *)addShapeWithPathRef:(CGMutablePathRef)path cornerRadius:(float)radius fillColor:(NSColor *)color stroke:(BOOL)stroke parentNode:(SKNode *)parent
{
    SKShapeNode *shape = [[SKShapeNode alloc] init];
    shape.path = path;
    shape.lineWidth = 1.0;
    shape.fillColor = [SKColor colorWithCalibratedRed:color.redComponent green:color.greenComponent blue:color.blueComponent alpha:color.alphaComponent];
    if(stroke)
    {
        shape.strokeColor = [SKColor whiteColor];
    }
    shape.glowWidth = 0.5;
    [parent addChild:shape];
    
    return shape;
}

#pragma mark - Main Drawing Methods

- (void)updateTimelineBar
{
    // Draw the Top Bar
    NSRect topBarFrame = NSMakeRect(HEADER_TOTAL_WIDTH, self.frame.size.height - TIMELINE_BAR_HEIGHT, 20000, TIMELINE_BAR_HEIGHT);
    if(!self.timelineBarNode)
    {
        self.timelineBarNode = [self addShapeWithRect:topBarFrame cornerRadius:0 fillColor:[NSColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0] stroke:NO parentNode:self.background];
        
        // Determine the grid spacing
        float timeSpan = [self xToTime:[self timeToX:self.timeAtLeftEdgeOfView] + 20000 - HEADER_TOTAL_WIDTH] - self.timeAtLeftEdgeOfView;
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
            
            SKLabelNode *label = [SKLabelNode labelNodeWithFontNamed:@"Helvetica"];
            label.text = time;
            label.fontSize = 10;
            label.fontColor = [SKColor blackColor];
            label.position = CGPointMake([self timeToX:timeMarker], topBarFrame.origin.y + 5);
            [self.timelineBarNode addChild:label];
            
            // Draw grid lines
            //if(data.shouldDrawTime)
            //{
            [self addShapeWithRect:NSMakeRect(textFrame.origin.x, 0, 1, self.frame.size.height - TIMELINE_BAR_HEIGHT) cornerRadius:0 fillColor:[NSColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0] stroke:NO parentNode:self.background];
            //}
        }
    }
    
    // Draw the currentTime marker
    CGPoint point = NSMakePoint((float)[self timeToX:self.currentTime], self.frame.size.height - TIMELINE_BAR_HEIGHT);
    if(self.timelineTriangleNode)
    {
        self.timelineTriangleNode.position = point;
    }
    else
    {
        CGMutablePathRef myPath = CGPathCreateMutable();
        CGFloat x1 = point.x;
        CGFloat y1 = point.y;
        CGFloat x2 = point.x + TIMELINE_BAR_HEIGHT / 2;
        CGFloat y2 = point.y + TIMELINE_BAR_HEIGHT;
        CGFloat x3 = point.x - TIMELINE_BAR_HEIGHT / 2;
        CGFloat y3 = point.y + TIMELINE_BAR_HEIGHT;
        CGPoint p[6] = { {x1, y1}, {x2, y2}, {x2, y2}, {x3, y3}, {x3, y3}, {x1, y1} };
        CGPathAddLines(myPath, NULL, p, 6);
        self.timelineTriangleNode = [self addShapeWithPathRef:myPath cornerRadius:0.0 fillColor:(self.selectedNode == self.timelineTriangleNode ? [NSColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0] : [NSColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0]) stroke:YES parentNode:self.timelineBarNode];
    }
    
    if(self.timelineRedLineNode)
    {
        self.timelineRedLineNode.position = point;
    }
    else
    {
        self.timelineRedLineNode = [self addShapeWithRect:NSMakeRect(point.x, 0, 1, self.frame.size.height - TIMELINE_BAR_HEIGHT) cornerRadius:0.0 fillColor:[NSColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0] stroke:NO parentNode:self.background];
    }
}

- (void)addBackground
{
    // Loading the background
    self.background = [SKSpriteNode spriteNodeWithImageNamed:@"Background"];
    self.background.name = @"Background";
    self.background.size = CGSizeMake(20000, self.frame.size.height);
    self.background.anchorPoint = CGPointZero;
    self.background.position = CGPointMake(HEADER_TOTAL_WIDTH, 0);
    [self addChild:self.background];
}

- (void)addChannelHeaders
{
    // Add the background/container
    self.channelContainerNode = [SKSpriteNode spriteNodeWithImageNamed:@"Background"];
    self.channelContainerNode.name = @"ChannelContainter";
    self.channelContainerNode.size = self.frame.size;
    self.channelContainerNode.anchorPoint = CGPointZero;
    self.channelContainerNode.position = CGPointZero;
    [self addChild:self.channelContainerNode];
    
    ///////////////////////////// Headers /////////////////////////////////////
    
    int headerChannelCount = 0;
    // Draw audio header
    [self addShapeNodeRectForChannelAtX:0 y:headerChannelCount width:HEADER_TOTAL_WIDTH height:1 color:[NSColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0] parent:self.channelContainerNode];
    headerChannelCount ++;
    // If there is audio
    if([CoreDataManager sharedManager].currentSequence.audio)
    {
        // Draw the audio track headers
        for(UserAudioAnalysisTrack *userAudioAnalysisTrack in [CoreDataManager sharedManager].currentSequence.audio.userAudioAnalysis.tracks)
        {
            [self addShapeNodeRectForChannelAtX:0 y:headerChannelCount width:HEADER_WIDTH height:1 color:[NSColor colorWithRed:0.8 green:0.0 blue:0.0 alpha:1.0] parent:self.channelContainerNode];
            headerChannelCount += userAudioAnalysisTrack.channels.count + 1;
        }
        
        // Draw the add audio track header
        [self addShapeNodeRectForChannelAtX:0 y:headerChannelCount width:HEADER_TOTAL_WIDTH height:1 color:[NSColor colorWithRed:0.5 green:0.0 blue:0.0 alpha:1.0] parent:self.channelContainerNode];
        headerChannelCount ++;
    }
    // Draw control box headers
    for(ControlBox *controlBox in [CoreDataManager sharedManager].currentSequence.controlBoxes)
    {
        [self addShapeNodeRectForChannelAtX:0 y:headerChannelCount width:HEADER_WIDTH height:1 color:[NSColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0] parent:self.channelContainerNode];
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
            NSArray *channelsArray = [[[[[CoreDataManager sharedManager].managedObjectContext ofType:@"UserAudioAnalysisTrackChannel"] where:@"track == %@", userAudioAnalysisTrack] orderBy:@"idNumber"] toArray];
            for(int i = 0; i < channelsArray.count; i ++)
            {
                [self addShapeNodeRectForChannelAtX:HEADER_DETAIL_WIDTH y:headerChannelCount width:HEADER_WIDTH height:1 color:[NSColor colorWithRed:0.8 green:0.0 blue:0.0 alpha:1.0] parent:self.channelContainerNode];
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
    // Draw channel headers
    for(ControlBox *controlBox in [CoreDataManager sharedManager].currentSequence.controlBoxes)
    {
        NSArray *channelsArray = [[[[[CoreDataManager sharedManager].managedObjectContext ofType:@"Channel"] where:@"controlBox == %@", controlBox] orderBy:@"idNumber"] toArray];
        for(int i = 0; i < channelsArray.count; i ++)
        {
            [self addShapeNodeRectForChannelAtX:HEADER_DETAIL_WIDTH y:headerChannelCount width:HEADER_WIDTH height:1 color:[NSColor colorWithRed:0.0 green:0.8 blue:0.0 alpha:1.0] parent:self.channelContainerNode];
            headerDetailChannelCount ++;
        }
    }
}

- (void)addUserAudioAnalysisTatums
{
    NSArray *visibleTatums = [[[[[CoreDataManager sharedManager].managedObjectContext ofType:@"SequenceTatum"] where:@"sequence == %@", [CoreDataManager sharedManager].currentSequence] orderBy:@"startTime"] toArray];
    
    for(int i = 0; i <= visibleTatums.count; i ++)
    {
        NSRect line = NSMakeRect([self timeToX:[((SequenceTatum *)visibleTatums[i]).startTime floatValue]], 0, 1, self.frame.size.height - TIMELINE_BAR_HEIGHT);
        SKShapeNode *shape = [self addShapeWithRect:line cornerRadius:0 fillColor:[NSColor whiteColor] stroke:NO parentNode:self.background];
        shape.name = @"UserAudioAnalysisTatum";
    }
}

- (void)addChannelGuidlines:(int)channelsCount;
{
    for(int i = 0; i <= channelsCount; i ++)
    {
        NSRect bottomOfChannelLine = NSMakeRect(HEADER_WIDTH + HEADER_DETAIL_WIDTH, i * CHANNEL_HEIGHT + TIMELINE_BAR_HEIGHT, self.frame.size.width, 1);
        [self addShapeWithRect:bottomOfChannelLine cornerRadius:0 fillColor:[NSColor whiteColor] stroke:NO parentNode:self.background];
    }
}

- (void)addCommands
{
    // Draw the audio
    int channelCount = 0;
    // Draw audio
    if([CoreDataManager sharedManager].currentSequence.audio)
    {
        [self addShapeNodeRectForChannelAtX:[self timeToX:[[CoreDataManager sharedManager].currentSequence.audio.startOffset floatValue]]  y:channelCount width:[self timeToX:[[CoreDataManager sharedManager].currentSequence.audio.echoNestAudioAnalysis.meta.seconds floatValue]] height:1 color:[NSColor colorWithDeviceRed:0.9 green:0.9 blue:0.9 alpha:0.7] parent:self.background];
        channelCount ++;
    }
    // Draw the userAudioAnalysis Commands
    /*for(UserAudioAnalysisTrack *userAudioAnalysisTrack in [CoreDataManager sharedManager].currentSequence.audio.userAudioAnalysis.tracks)
    {
        NSArray *channelsArray = [[[[[CoreDataManager sharedManager].managedObjectContext ofType:@"UserAudioAnalysisTrackChannel"] where:@"track == %@", userAudioAnalysisTrack] orderBy:@"idNumber"] toArray];
        for(int i = 0; i < channelsArray.count; i ++)
        {
            
            [self addShapeNodeRectForChannelAtX:0 y:channelCount width:[self timeToX:[[CoreDataManager sharedManager].currentSequence.audio.echoNestAudioAnalysis.meta.seconds floatValue]] height:1 color:[NSColor colorWithDeviceRed:0.9 green:0.9 blue:0.9 alpha:0.7] parent:self.background];
            
            
            
            //[self addShapeWithRect:NSMakeRect(HEADER_WIDTH, TIMELINE_BAR_HEIGHT + channelCount * CHANNEL_HEIGHT, HEADER_DETAIL_WIDTH, CHANNEL_HEIGHT) cornerRadius:COMMAND_CORNER_RADIUS fillColor:[NSColor colorWithDeviceRed:0.8 green:0.8 blue:0.8 alpha:0.7] stroke:YES parentNode:self.background];
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
            //[self drawRect:NSMakeRect(HEADER_WIDTH, TIMELINE_BAR_HEIGHT + channelCount * CHANNEL_HEIGHT, HEADER_DETAIL_WIDTH, CHANNEL_HEIGHT) withCornerRadius:COMMAND_CORNER_RADIUS fillColor:[NSColor colorWithDeviceRed:0.6 green:0.6 blue:0.6 alpha:0.7] andStroke:YES];
            //[self drawCommandClustersAtTrackIndex:trackIndex tracksTall:tracksTall parentIndex:i parentIsControlBox:YES];
            channelCount ++;
        }
    }*/
}

#pragma mark - Mouse Methods

-(void)mouseDown:(NSEvent *)theEvent
{
    CGPoint location = [theEvent locationInNode:self];
    self.selectedNode = [self nodeAtPoint:location];
    
    // Timeline bar
    if(self.selectedNode == self.timelineBarNode)
    {
        self.currentTime = [self xToTime:location.x];
        [self updateTimelineBar];
    }
    
    self.previousLocationX = location.x;
    self.previousLocationY = location.y;
}

-(void)mouseDragged:(NSEvent *)theEvent
{
    CGPoint location = [theEvent locationInNode:self];
    CGPoint translation = CGPointMake(location.x - self.previousLocationX, location.y - self.previousLocationY);
    
    // Hanle the dragging
    CGPoint position = self.selectedNode.position;
    // Tatum Drag
    if([self.selectedNode.name isEqualToString:@"UserAudioAnalysisTatum"])
    {
        self.selectedNode.position = CGPointMake(position.x + translation.x, position.y + translation.y);
    }
    // Timeline bar
    else if(self.selectedNode == self.timelineBarNode)
    {
        self.currentTime = [self xToTime:location.x];
        [self updateTimelineBar];
    }
    // Timeline triangle
    else if(self.selectedNode == self.timelineTriangleNode)
    {
        float newCurrentTime = [self xToTime:location.x];
        
        // Bind the minimum time to 0
        if(newCurrentTime < 0.0)
        {
            newCurrentTime = 0.0;
        }
        
        // Move the cursor to the new position
        self.currentTime = newCurrentTime;
        [self updateTimelineBar];
    }
    
    self.previousLocationX = location.x;
    self.previousLocationY = location.y;
}

- (void)scrollWheel:(NSEvent *)event
{
    // Scroll the background
    [self.background setPosition:CGPointMake(self.background.position.x + event.deltaX, self.background.position.y - event.deltaY)];
    // Scroll the channel header only in the Y
    [self.channelContainerNode setPosition:CGPointMake(self.channelContainerNode.position.x, self.channelContainerNode.position.y - event.deltaY)];
}

- (void)magnifyWithEvent:(NSMagnificationGestureRecognizer *)event
{
    NSLog(@"Zoon:%@", event);
}

/*- (CGPoint)boundLayerPos:(CGPoint)newPos
 {
 CGSize winSize = self.size;
 CGPoint retval = newPos;
 retval.x = MIN(retval.x, 0);
 retval.x = MAX(retval.x, -[_background size].width+ winSize.width);
 retval.y = [self position].y;
 return retval;
 }*/

/*- (void)updateTimeAtLeftEdgeOfTimelineView:(NSTimer *)theTimer;
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
}*/

#pragma mark - Drawing Timer

-(void)update:(CFTimeInterval)currentTime
{
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
     }*/
}

@end
