//
//  ScintillaViewController.h
//  typeditor
//
//  Created by  on 12-2-16.
//  Copyright (c) 2012年 MagnetJoy. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ScintillaView.h"
#import "InfoBar.h"
#import "V8Cocoa.h"

@interface ScintillaViewController : NSViewController {
    NSWindow *window;
    V8Cocoa *v8;
}

@end
