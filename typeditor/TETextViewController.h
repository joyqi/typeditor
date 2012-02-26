//
//  TETextViewController.h
//  typeditor
//
//  Created by 宁 祁 on 12-2-26.
//  Copyright (c) 2012年 MagnetJoy. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TETextView.h"
#import "EditorLineNumberView.h"

@class TEV8;

@interface TETextViewController : NSViewController <NSTextStorageDelegate, NSTextViewDelegate> {
    
    // parent window
    NSWindow *window;
    
    // line number
    EditorLineNumberView *lineNumber;
    
    TETextView *textView;
    
    // scroll
    NSScrollView *scroll;
    
    // v8 embed
    TEV8 *v8;
}

@property (strong, nonatomic) NSWindow *window;
@property (strong, nonatomic) EditorLineNumberView *lineNumber;
@property (strong, nonatomic) TETextView *textView;
@property (strong, nonatomic) NSScrollView *scroll;
@property (strong, nonatomic) TEV8 *v8;

- (id)initWithWindow:(NSWindow *)parent;

@end
