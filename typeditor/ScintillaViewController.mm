//
//  ScintillaViewController.m
//  typeditor
//
//  Created by  on 12-2-16.
//  Copyright (c) 2012年 MagnetJoy. All rights reserved.
//

#import "ScintillaViewController.h"

@implementation ScintillaViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
        scintillaView = [[ScintillaView alloc] init];
    }
    
    return self;
}

- (void)appendScintillaToWindow:(NSWindow *)window
{
    NSView *contentView = [window contentView];
    CGRect frame = [contentView frame];
    
    [scintillaView setFrame:frame];
    [contentView addSubview:scintillaView];
    [window setDelegate:self];
}

- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize
{
    [scintillaView setFrame:CGRectMake(0, 0, frameSize.width, frameSize.height)];
    return frameSize;
}

@end
