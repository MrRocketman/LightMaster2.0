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

@implementation SKScene (Unarchive)

+ (instancetype)unarchiveFromFile:(NSString *)file {
    /* Retrieve scene file path from the application bundle */
    NSString *nodePath = [[NSBundle mainBundle] pathForResource:file ofType:@"sks"];
    /* Unarchive the file to an SKScene object */
    NSData *data = [NSData dataWithContentsOfFile:nodePath
                                          options:NSDataReadingMappedIfSafe
                                            error:nil];
    NSKeyedUnarchiver *arch = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    [arch setClass:self forClassName:@"SKScene"];
    SKScene *scene = [arch decodeObjectForKey:NSKeyedArchiveRootObjectKey];
    [arch finishDecoding];
    
    return scene;
}

@end

@implementation GameView

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if(self = [super initWithCoder:aDecoder])
    {
        GameScene *scene = [GameScene unarchiveFromFile:@"GameScene"];
        
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

- (IBAction)panGesutre:(id)sender
{
    [(GameScene *)self.scene panWithEvent:sender];
}

- (IBAction)rotateGesutre:(id)sender
{
    [(GameScene *)self.scene rotateWithEvent:sender];
}

- (IBAction)magnifyGesutre:(id)sender
{
    [(GameScene *)self.scene magnifyWithEvent:sender];
}

- (void)scrollWheel:(NSEvent *)event {
    [self.scene scrollWheel:event];
}

@end
