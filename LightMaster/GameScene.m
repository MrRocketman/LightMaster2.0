//
//  GameScene.m
//  LightMaster2014
//
//  Created by James Adams on 11/28/14.
//  Copyright (c) 2014 James Adams. All rights reserved.
//

#import "GameScene.h"

static NSString * const kAnimalNodeName = @"movable";

@interface GameScene()

@property (nonatomic, strong) SKSpriteNode *background;
@property (nonatomic, strong) SKSpriteNode *selectedNode;
@property (nonatomic, assign) float previousLocationX;
@property (nonatomic, assign) float previousLocationY;

@end

@implementation GameScene

-(void)didMoveToView:(SKView *)view
{
    // 1) Loading the background
    self.background = [SKSpriteNode spriteNodeWithImageNamed:@"Background"];
    self.background.name = @"Background";
    self.background.size = self.frame.size;
    self.background.anchorPoint = CGPointZero;
    self.background.position = CGPointZero;
    [self addChild:_background];
    
    // 2) Loading the images
    NSArray *imageNames = @[@"bird", @"cat", @"dog", @"turtle"];
    for(int i = 0; i < [imageNames count]; ++i)
    {
        NSString *imageName = [imageNames objectAtIndex:i];
        SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:imageName];
        [sprite setName:kAnimalNodeName];
        
        float offsetFraction = ((float)(i + 1)) / ([imageNames count] + 1);
        [sprite setPosition:CGPointMake(self.frame.size.width / 2 * offsetFraction, self.frame.size.height / 4)];
        [_background addChild:sprite];
    }
}

-(void)mouseDown:(NSEvent *)theEvent
{
    CGPoint location = [theEvent locationInNode:self];
    [self selectNodeForTouch:location];
    self.previousLocationX = location.x;
    self.previousLocationY = location.y;
}

-(void)mouseDragged:(NSEvent *)theEvent
{
    CGPoint location = [theEvent locationInNode:self];
    CGPoint translation = CGPointMake(location.x - self.previousLocationX, location.y - self.previousLocationY);
    [self panForTranslation:translation];
    
    self.previousLocationX = location.x;
    self.previousLocationY = location.y;
}

- (void)scrollWheel:(NSEvent *)event
{
    CGPoint position = self.background.position;
    CGPoint newPos = CGPointMake(position.x + event.deltaX, position.y - event.deltaY);
    [_background setPosition:newPos];
}

- (void)magnifyWithEvent:(NSMagnificationGestureRecognizer *)event
{
    NSLog(@"Zoon:%@", event);
}

- (void)selectNodeForTouch:(CGPoint)touchLocation
{
    //1
    SKSpriteNode *touchedNode = (SKSpriteNode *)[self nodeAtPoint:touchLocation];
    
    //2
    if(![_selectedNode isEqual:touchedNode])
    {
        [_selectedNode removeAllActions];
        [_selectedNode runAction:[SKAction rotateToAngle:0.0f duration:0.1]];
        
        _selectedNode = touchedNode;
        //3
        if([[touchedNode name] isEqualToString:kAnimalNodeName])
        {
            SKAction *sequence = [SKAction sequence:@[[SKAction rotateByAngle:degToRad(-4.0f) duration:0.1], [SKAction rotateByAngle:0.0 duration:0.1], [SKAction rotateByAngle:degToRad(4.0f) duration:0.1]]];
            [_selectedNode runAction:[SKAction repeatActionForever:sequence]];
        }
    }
}

float degToRad(float degree)
{
    return degree / 180.0f * M_PI;
}

- (CGPoint)boundLayerPos:(CGPoint)newPos
{
    CGSize winSize = self.size;
    CGPoint retval = newPos;
    retval.x = MIN(retval.x, 0);
    retval.x = MAX(retval.x, -[_background size].width+ winSize.width);
    retval.y = [self position].y;
    return retval;
}

- (void)panForTranslation:(CGPoint)translation
{
    CGPoint position = [_selectedNode position];
    if([[_selectedNode name] isEqualToString:kAnimalNodeName])
    {
        //[_selectedNode setPosition:CGPointMake(position.x + translation.x, position.y + translation.y)];
        self.selectedNode.size = CGSizeMake(self.selectedNode.size.width + translation.x, self.selectedNode.size.height + translation.y);
    }
    else
    {
        CGPoint newPos = CGPointMake(position.x + translation.x, position.y + translation.y);
        [_background setPosition:newPos];
    }
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
}

@end
