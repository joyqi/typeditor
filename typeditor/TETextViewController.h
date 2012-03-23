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

@interface TETextViewController : NSViewController <NSTextViewDelegate> {
    
    // parent window
    INAppStoreWindow *window;
    
    // containter box
    NSView *containter;
    
    TETextView *textView;
    
    NSString *lastTab;
    
    // scroll
    NSScrollView *scrollView;
    
    NSMutableDictionary *tabStorages;
    
    // changed
    BOOL textViewChanged;
    
    // queue
    dispatch_queue_t queue;
    
    // v8 embed
    TEV8 *v8;
}

@property (strong, nonatomic) INAppStoreWindow *window;
@property (strong, nonatomic) TETextView *textView;
@property (strong, nonatomic) NSScrollView *scrollView;
@property (strong, nonatomic) TEV8 *v8;
@property (strong, nonatomic) NSMutableDictionary *tabStorages;
@property (readonly, nonatomic) NSView *containter;

- (id)initWithWindow:(INAppStoreWindow *)parent;
- (void)boundsDidChange:(NSNotification *)aNotification;
- (void)frameDidChange:(NSNotification *)aNotification;
- (void)createTabNamed:(NSString *)name withText:(NSString *)text;
- (void)selectTabNamed:(NSString *)name;
- (void)changeTabNamed:(NSString *)name;
- (void)closeTabNamed:(NSString *)name;

@end
