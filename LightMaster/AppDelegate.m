//
//  AppDelegate.m
//  LightMaster
//
//  Created by James Adams on 11/22/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import "AppDelegate.h"
#import "CoreDataManager.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
    // Initialize the coreDataManager now! Very important!
    [CoreDataManager sharedManager];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    // Insert code here to tear down your application
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    // Save changes in the application's managed object context before the application terminates.
    [CoreDataManager.sharedManager saveContext];

    return NSTerminateNow;
}

@end
