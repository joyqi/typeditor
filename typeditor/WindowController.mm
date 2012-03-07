//
//  WindowController.m
//  typeditor
//
//  Created by 宁 祁 on 12-2-19.
//  Copyright (c) 2012年 MagnetJoy. All rights reserved.
//

#import "WindowController.h"

@implementation WindowController

- (id)initWithApp:(NSObject *)app
{
    self = [super initWithWindowNibName:@"WindowController"];
    if (self) {
        mainWindow = (INAppStoreWindow *)[self window];
        
        // editor = [[EditorViewController alloc] initWithWindow:mainWindow];
        editor = [[TETextViewController alloc] initWithWindow:mainWindow];
        
        // Initialization code here.
        [mainWindow setTrafficLightButtonsLeftMargin:7.0f];
        [mainWindow setCenterTrafficLightButtons:NO];
        [mainWindow setHideTitleBarInFullScreen:NO];
        [mainWindow setCenterFullScreenButton:YES];
        [mainWindow setTitleBarHeight:43.0f];
        [mainWindow setShowsBaselineSeparator:NO];
        [mainWindow setDelegate:self];
        
        NSPoint pos = [mainWindow frame].origin;
        pos.x += 1.0f;
        pos.y += 21.0f;
        
        [mainWindow setMinSize:NSMakeSize(100.0f, 100.0f)];
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
}

@end
