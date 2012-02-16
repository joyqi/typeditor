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

- (void)appendScintillaViewTo:(NSView *)parentView
{
    [scintillaView setFrame:[parentView frame]];
    [parentView addSubview:scintillaView];
}

@end
