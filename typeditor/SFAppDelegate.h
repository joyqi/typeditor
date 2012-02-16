//
//  SFAppDelegate.h
//  typeditor
//
//  Created by  on 12-2-16.
//  Copyright (c) 2012年 MagnetJoy. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ScintillaViewController.h"

@interface SFAppDelegate : NSObject <NSApplicationDelegate> {
    ScintillaViewController *scintillaViewController;
}

@property (assign) IBOutlet NSWindow *window;

@end
