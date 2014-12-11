//
//  AudioLyric.h
//  LightMaster
//
//  Created by James Adams on 12/11/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Audio;

@interface AudioLyric : NSManagedObject

@property (nonatomic, retain) NSNumber * time;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) Audio *audio;

@end
