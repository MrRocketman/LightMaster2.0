//
//  GameScene.h
//  LightMaster2014
//

//  Copyright (c) 2014 James Adams. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface GameScene : SKScene

- (void)scrollWheel:(NSEvent *)event;
- (void)magnifyWithEvent:(NSMagnificationGestureRecognizer *)event;

@end
