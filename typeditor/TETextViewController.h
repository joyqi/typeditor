//
//  TETextViewController.h
//  typeditor
//
//  Created by 宁 祁 on 12-2-26.
//  Copyright (c) 2012年 MagnetJoy. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TETextView.h"
#import "TELineNumberView.h"

@class TEV8;
@class INAppStoreWindow;

@interface TETextViewController : NSViewController <NSTextStorageDelegate, NSTextViewDelegate> {
    
    // parent window
    INAppStoreWindow *window;
    
    // containter box
    NSView *containter;
    
    // tabview belongs to
    NSTabViewItem *tabViewItem;
    
    // line number
    TELineNumberView *lineNumberView;
    
    TETextView *textView;
    
    // scroll
    NSScrollView *scrollView;
    
    // changed
    BOOL textViewChanged;
    BOOL focused;
    
    // v8 embed
    TEV8 *v8;
}

@property (strong, nonatomic) INAppStoreWindow *window;
@property (strong, nonatomic) TELineNumberView *lineNumberView;
@property (strong, nonatomic) TETextView *textView;
@property (strong, nonatomic) NSScrollView *scrollView;
@property (strong, nonatomic) TEV8 *v8;
@property (strong, nonatomic) NSTabViewItem *tabViewItem;
@property (readonly, nonatomic) NSView *containter;

- (id)initWithWindow:(INAppStoreWindow *)parent;
- (void)boundsDidChange:(NSNotification *)aNotification;
- (void)frameDidChange:(NSNotification *)aNotification;
- (void)focus;
- (void)blur;

@end
