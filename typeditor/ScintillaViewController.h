//
//  ScintillaViewController.h
//  typeditor
//
//  Created by  on 12-2-16.
//  Copyright (c) 2012年 MagnetJoy. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ScintillaView.h"

@interface ScintillaViewController : NSViewController {
    ScintillaView *scintillaView;
}

- (void)appendScintillaViewTo:(NSView *)parentView;
@end
