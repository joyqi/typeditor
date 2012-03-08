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

@interface WindowController : NSWindowController <NSWindowDelegate> {
    INAppStoreWindow *mainWindow;
    
    // editor的tab
    NSMutableDictionary *tabEditors;
    
    NSString *focusedTabIdentifier;
    
    NSTabView *tabView;
    PSMTabBarControl *tabBar;
}

@property (readonly, nonatomic) NSMutableDictionary *tabEditors;

- (id)initWithApp:(NSObject *)app;
@end
