//
//  GameScene.h
//  LightMaster2014
//

//  Copyright (c) 2014 James Adams. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface GameScene : SKScene
{
    NSTimer *autoScrollTimer;
    BOOL autoscrollTimerIsRunning;
}

@property (assign, nonatomic) float zoomLevel; // 1.0 = no zoom, 10 = 10x zoom
@property (assign, nonatomic) float timeAtLeftEdgeOfView;
@property (assign, nonatomic) float currentTime;

- (void)scrollWheel:(NSEvent *)event;
- (void)magnifyWithEvent:(NSMagnificationGestureRecognizer *)event;

@end
