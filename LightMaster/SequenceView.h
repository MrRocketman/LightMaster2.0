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
#define PIXEL_TO_ZOOM_RATIO 25
#define CHANNEL_HEIGHT 20.0
#define TOP_BAR_HEIGHT 20.0
#define HEADER_WIDTH 100.0
#define HEADER_DETAIL_WIDTH 100.0
#define HEADER_TOTAL_WIDTH HEADER_WIDTH + HEADER_DETAIL_WIDTH


enum
{
    MNMouseDown,
    MNMouseDragged,
    MNMouseUp
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

@interface SequenceView : NSView
{
    NSRect visibleFrame;
    
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

@property (assign, nonatomic) float zoomLevel; // 1.0 = no zoom, 10 = 10x zoom
@property (assign, nonatomic) float timeAtLeftEdgeOfView;
@property (assign, nonatomic) float currentTime;

@end
