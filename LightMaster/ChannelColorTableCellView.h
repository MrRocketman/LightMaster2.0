//
//  ChannelColorTableCellView.h
//  LightMaster
//
//  Created by James Adams on 11/25/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ChannelColorTableCellView : NSTableCellView

@property (strong, nonatomic) IBOutlet NSColorWell *colorWell;
@property (assign, nonatomic) int tableRow;

@end
