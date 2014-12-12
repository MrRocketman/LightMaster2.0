//
//  Channel.m
//  LightMaster
//
//  Created by James Adams on 12/9/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import "Channel.h"
#import "ChannelPattern.h"
#import "Command.h"
#import "ControlBox.h"
#import <AppKit/AppKit.h>


@implementation Channel

@dynamic color;
@dynamic idNumber;
@dynamic title;
@dynamic uuid;
@dynamic watts;
@dynamic volts;
@dynamic numberOfLights;
@dynamic channelPatterns;
@dynamic commands;
@dynamic controlBox;

@end

@implementation ColorToDataTransformer

+ (BOOL)allowsReverseTransformation
{
    return YES;
}

+ (Class)transformedValueClass
{
    return [NSData class];
}


- (id)transformedValue:(id)value
{
    NSColor *color = (NSColor *)value;
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:color];
    return data;
}

- (id)reverseTransformedValue:(id)value
{
    NSData *data = (NSData *)value;
    NSColor *color = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    return color;
}

@end
