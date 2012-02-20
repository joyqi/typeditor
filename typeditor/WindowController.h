//
//  WindowController.h
//  typeditor
//
//  Created by 宁 祁 on 12-2-19.
//  Copyright (c) 2012年 MagnetJoy. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EditorViewController.h"
#import "INAppStoreWindow.h"

@interface WindowController : NSWindowController <NSWindowDelegate> {
    EditorViewController *editor;
    INAppStoreWindow *mainWindow;
}

- (id)initWithApp:(NSObject *)app;
@end
