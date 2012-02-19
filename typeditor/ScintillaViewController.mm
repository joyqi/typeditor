//
//  ScintillaViewController.m
//  typeditor
//
//  Created by  on 12-2-16.
//  Copyright (c) 2012年 MagnetJoy. All rights reserved.
//

#import "ScintillaViewController.h"

@interface ScintillaViewController (Private)
- (NSRect)getWindowFrame;
- (NSRect)getWindowResizeFrame:(NSWindow *)sender toSize:(NSSize)frameSize;
@end

@implementation ScintillaViewController

- (id)initWithWindow:(NSWindow *)parent
{
    self = [super initWithNibName:@"ScintillaViewController" bundle:nil];
    if (self) {
        window = parent;
        
        ScintillaView *scintillaView = [[ScintillaView alloc] initWithFrame:[[window contentView] frame]];
        [scintillaView setAutoresizesSubviews: YES];
        [scintillaView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
        
        InfoBar *infoBar = [[InfoBar alloc] initWithFrame:NSMakeRect(0, 0, 400, 0)];
        [infoBar setDisplay: IBShowAll];
        [scintillaView setInfoBar: infoBar top: YES];
        [scintillaView setStatusText: @"Operation complete"];
        
        [self setView:scintillaView];
        [[window contentView] addSubview:[self view]];
        
        // init v8
        v8 = [[V8Cocoa alloc] init];
        [v8 embedScintilla:scintillaView];
        
        scintillaView = nil;
    }
    
    return self;
}

@end
