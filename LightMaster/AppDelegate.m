//
//  AppDelegate.m
//  LightMaster
//
//  Created by James Adams on 11/22/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import "AppDelegate.h"
#import "CoreDataManager.h"
#import "ENAPIRequest.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
    // Initialize the coreDataManager now! Very important!
    [CoreDataManager sharedManager];
    [ENAPIRequest setApiKey:@"9F52RBALOQTUGKOT5" andConsumerKey:@"470771f3b2787696050f2f4143cb5c33" andSharedSecret:@"QMa4TZ+PRL+Nq0e3SAR/RQ"];
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
