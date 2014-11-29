//
//  GameView.m
//  LightMaster2014
//
//  Created by James Adams on 11/28/14.
//  Copyright (c) 2014 James Adams. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GameView.h"
#import "GameScene.h"

@implementation GameView

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if(self = [super initWithCoder:aDecoder])
    {
        GameScene *scene = [[GameScene alloc] initWithSize:self.frame.size];
        
        /* Set the scale mode to scale to fit the window */
        //scene.scaleMode = SKSceneScaleModeFill;
        scene.scaleMode = SKSceneScaleModeAspectFit;
        
        [self presentScene:scene];
        
        /* Sprite Kit applies additional optimizations to improve rendering performance */
        self.ignoresSiblingOrder = YES;
        
        self.showsFPS = YES;
        self.showsNodeCount = YES;
    }
    
    return self;
}

- (IBAction)magnifyGesutre:(id)sender
{
    [(GameScene *)self.scene magnifyWithEvent:sender];
}

- (void)scrollWheel:(NSEvent *)event {
    [self.scene scrollWheel:event];
}

@end
