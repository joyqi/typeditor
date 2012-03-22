//
//  WindowController.h
//  typeditor
//
//  Created by 宁 祁 on 12-2-19.
//  Copyright (c) 2012年 MagnetJoy. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "INAppStoreWindow.h"

@class PSMTabBarControl;
@class TETextViewController;

@interface WindowController : NSWindowController <NSWindowDelegate> {
    INAppStoreWindow *mainWindow;
    
    TETextViewController *textViewController;
    
    NSUInteger autoIncrementId;
    
    NSTextField *titleTextField;
    
    NSTabView *tabView;
    PSMTabBarControl *tabBar;
}

- (id)initWithApp:(NSObject *)app;
- (void)setTitle:(NSString *)title;
@end
