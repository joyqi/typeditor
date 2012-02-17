//
//  SFAppDelegate.m
//  typeditor
//
//  Created by  on 12-2-16.
//  Copyright (c) 2012年 MagnetJoy. All rights reserved.
//

#import "SFAppDelegate.h"

@implementation SFAppDelegate

static SFAppDelegate *sharedApp = NULL;

@synthesize window = _window;

- (id)init
{
    if (!sharedApp) {
        sharedApp = [super init];
    }
    
    return sharedApp;
}

+ (SFAppDelegate *)sharedApp
{
    if (!sharedApp) {
        sharedApp = [[SFAppDelegate alloc] init];
    }
    
    return sharedApp;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // init scintilla
    scintillaViewController = [[ScintillaViewController alloc] initWithNibName:@"ScintillaViewController" bundle:nil];
}

@end
