//
//  WindowController.h
//  typeditor
//
//  Created by 宁 祁 on 12-2-19.
//  Copyright (c) 2012年 MagnetJoy. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "INAppStoreWindow.h"

#define TE_WINDOW_TITLE_COLOR [NSColor colorWithSRGBRed:0.24f green:0.24f blue:0.24f alpha:1.0f]

@class PSMTabBarControl;
@class TETextViewController;

@interface WindowController : NSWindowController <NSWindowDelegate> {
    INAppStoreWindow *mainWindow;
    
    TETextViewController *textViewController;
    
    NSUInteger autoIncrementId;
    
    NSTextField *title;
    
    NSMutableDictionary *titleAttributes;
    
    NSTabView *tabView;
    PSMTabBarControl *tabBar;
}

- (id)initWithApp:(NSObject *)app;
- (void)setTitle:(NSString *)aTitle;
@end
