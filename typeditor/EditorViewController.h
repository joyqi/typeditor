//
//  EditorViewController.h
//  typeditor
//
//  Created by  on 12-2-20.
//  Copyright (c) 2012年 MagnetJoy. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EditorTextView.h"
#import "EditorLineNumberView.h"
#import "V8Cocoa.h"

@interface EditorViewController : NSViewController <EditorTextViewDelegate, NSTextStorageDelegate> {
    
    // parent window
    NSWindow *window;
    
    // editor view
    EditorTextView *editor;
    
    // line number
    EditorLineNumberView *lineNumber;
    
    // scroll
    NSScrollView *scroll;
    
    // text storage
    NSTextStorage *textStorage;
    
    // hold replacement
    NSMutableArray *holdReplacement;
    
    // v8 embed
    V8Cocoa *v8;
    
    // editing
    BOOL editing;
}

@property (assign, atomic) BOOL editing;
@property (strong, nonatomic) NSWindow *window;
@property (strong, nonatomic) NSTextView *editor;
@property (strong, nonatomic) NSScrollView *scroll;
@property (strong, nonatomic) NSMutableArray *holdReplacement;
@property (strong, nonatomic) EditorLineNumberView *lineNumber;
@property (strong, nonatomic) V8Cocoa *v8;

- (id)initWithWindow:(NSWindow *)parent;
- (void)setText:(int)location withLength:(int)length replacementString:(NSString *)string;

@end
