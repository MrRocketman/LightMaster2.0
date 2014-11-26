//
//  SequenceView.h
//  LightMaster
//
//  Created by James Adams on 11/25/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define CLUSTER_CORNER_RADIUS 5.0
#define COMMAND_CORNER_RADIUS 3.0
#define AUTO_SCROLL_REFRESH_RATE 0.03
#define TIME_ADJUST_PIXEL_BUFFER 8.0

enum
{
    MNControlBox,
    MNChannelGroup
};

enum
{
    MNMouseDragNotInUse,
    MNAudioClipMouseDrag,
    MNControlBoxCommandClusterMouseDrag,
    MNChannelGroupCommandClusterMouseDrag,
    MNCommandMouseDrag,
    MNCommandMouseDragEndTime,
    MNCommandMouseDragStartTime,
    MNCommandMouseDragBetweenChannels,
    MNTimeMarkerMouseDrag,
    MNNewClusterMouseDrag,
    MNControlBoxCommandClusterMouseDragStartTime,
    MNControlBoxCommandClusterMouseDragEndTime,
    MNControlBoxCommandClusterMouseDragBetweenChannels,
};

@interface SequenceView : NSScrollView
{
    NSPoint scrollViewOrigin;
    NSSize scrollViewVisibleSize;
    
    NSPoint mouseClickDownPoint;
    NSPoint currentMousePoint;
    int mouseAction;
    NSEvent *mouseEvent;
    NSTimer *autoScrollTimer;
    int mouseDraggingEvent;
    int mouseDraggingEventObjectIndex;
    BOOL autoscrollTimerIsRunning;
    BOOL currentTimeMarkerIsSelected;

    int selectedCommandIndex;
    
    int controlBoxTrackIndexes[256];
}

@end
