//
//  EditorTextView.h
//  typeditor
//
//  Created by  on 12-2-21.
//  Copyright (c) 2012年 MagnetJoy. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface EditorTextView : NSTextView {
    
    // custorm cursor
    CGFloat insertionPointWidth;
}

@property (assign) CGFloat insertionPointWidth;

@end
