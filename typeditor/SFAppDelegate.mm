//
//  SFAppDelegate.m
//  typeditor
//
//  Created by  on 12-2-16.
//  Copyright (c) 2012年 MagnetJoy. All rights reserved.
//

#import "SFAppDelegate.h"
#import "WindowController.h"

@implementation SFAppDelegate

static SFAppDelegate *sharedApp = NULL;

- (id)init
{
    if (!sharedApp) {
        sharedApp = [super init];
        windowControllers = [NSMutableArray array];
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
    // NSLog(@"%@", [self methodForSelector:@selector(applicationDidFinishLaunching:)]);
    WindowController *windowController = [[WindowController alloc] initWithApp:self];
    [windowController showWindow:[windowController window]];
    [windowControllers addObject:windowController];
    // windowController = nil;
}

@end
