//
//  SFAppDelegate.m
//  typeditor
//
//  Created by  on 12-2-16.
//  Copyright (c) 2012年 MagnetJoy. All rights reserved.
//

#import "SFAppDelegate.h"

@implementation SFAppDelegate

@synthesize window = _window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    scintillaViewController = [[ScintillaViewController alloc] initWithNibName:@"ScintillaViewController" bundle:nil];
    [scintillaViewController appendScintillaViewTo:[_window contentView]];
}

@end
