//
//  EditorTextView.h
//  typeditor
//
//  Created by  on 12-2-21.
//  Copyright (c) 2012年 MagnetJoy. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "EditorTextViewDelegate.h"
#import "V8Cocoa.h"
#import "EditorLineNumberView.h"

@interface EditorTextView : NSTextView {
    
    // default font
    NSFont *defaultFont;
    
    // default color
    NSColor *defaultColor;
    
    // custorm cursor
    CGFloat insertionPointWidth;
    
    // soft tab with space
    BOOL softTab;
    
    // tab stop
    NSUInteger tabStop;
    CGFloat tabInterval;
    
    // text storage
    NSTextStorage *_textStorage;
    
    // line ending
    NSString *lineEndings;
    
    // v8 embed
    id editorViewController;
}

@property (assign) CGFloat insertionPointWidth;
@property (assign) BOOL softTab;
@property (assign) CGFloat tabInterval;
@property (assign) NSUInteger tabStop;
@property (strong, nonatomic) NSFont *defaultFont;
@property (strong, nonatomic) NSColor *defaultColor;
@property (strong, nonatomic) id editorViewController;

- (void)setTextStyle:(int)location withLength:(int)length forType:(NSString *)type withValue:(v8::Local<v8::Value>)value;
- (void)setEditorStyle:(NSString *)type withValue:(v8::Local<v8::Value>)value;
- (NSFont *)fontAt:(NSUInteger)location;
- (NSString *)stringAt:(NSUInteger)location;
- (NSString *)stringAt:(NSUInteger)location withLength:(NSUInteger)length;
- (CGFloat)spaceWidth;
- (CGFloat)spaceWidth:(NSUInteger)location;
- (NSUInteger)lineAt:(NSUInteger)location;
- (NSUInteger)lineCurrent;
- (NSRange)lineRange:(NSUInteger)line;
- (NSUInteger)countWidth:(NSRange)range;
- (void)appendTab:(NSUInteger)location withWidth:(NSUInteger)width;
- (void)replaceTab:(NSRange)range withWidth:(NSUInteger)width;
@end
