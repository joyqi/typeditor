//
//  TETextView.h
//  typeditor
//
//  Created by 宁 祁 on 12-2-25.
//  Copyright (c) 2012年 MagnetJoy. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "TE.h"
#import <JavaScriptCore/JavaScriptCore.h>

#define TETextViewSetTypingAttribute(value, key) \
    NSMutableDictionary *attributes = [[self typingAttributes] mutableCopy]; \
    [attributes setValue:value forKey:key]; \
    [self setTypingAttributes:attributes];

#define TETextViewSetSelectedAttribute(value, key) \
    NSMutableDictionary *attributes = [[self selectedTextAttributes] mutableCopy]; \
    [attributes setValue:value forKey:key]; \
    [self setSelectedTextAttributes:attributes];

#define TETextViewSetParagraphStyle(key1, val1, key2, val2) \
    NSDictionary *attributes = [[self typingAttributes] mutableCopy]; \
    NSMutableParagraphStyle *paragraphStyle; \
    if ([self defaultParagraphStyle]) { \
        paragraphStyle = [[self defaultParagraphStyle] mutableCopy]; \
    } else { \
        paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy]; \
    } \
    [paragraphStyle key1:val1]; \
    [paragraphStyle key2:val2]; \
    [attributes setValue:paragraphStyle forKey:NSParagraphStyleAttributeName]; \
    [self setTypingAttributes:attributes]; \
    [self setDefaultParagraphStyle:paragraphStyle];

@interface TETextView : NSTextView {
    
    // 预定义的glyph style 数组
    NSMutableArray *definedGlyphStyles;
    
    // glyph的预定义缓冲区
    TEGlyphRange *glyphRanges;
    NSUInteger glyphRangesNum;
    
    NSLayoutManager *layoutManager;
    
    NSColor *color;
    
    CGFloat lineHeight;
    
    NSUInteger tabStop;
    
    NSColor *selectedColor;
    
    NSColor *selectedBackgroundColor;
    
    NSTimeInterval lastScrollTime;
    
    // draw mode
    BOOL shouldDrawText;
    BOOL shouldDrawTextThroughScroll;
}

@property (assign) NSUInteger glyphRangesNum;
@property (strong, nonatomic) NSColor *color;
@property (assign, nonatomic) CGFloat lineHeight;
@property (assign, nonatomic) NSUInteger tabStop;
@property (strong, nonatomic) NSColor *selectedColor;
@property (strong, nonatomic) NSColor *selectedBackgroundColor;

- (void) defineGlyphStyle:(TEGlyphStyle *)style withType:(NSUInteger)type;
- (void) setGlyphRange:(TEGlyphRange)glyphRange withIndex:(NSUInteger)index;
- (NSRange) rectToGlyphRange:(NSRect)rect effectiveRange:(NSRange *)range;
- (void) setPaddingX:(CGFloat)padingX;
- (void) setPaddingY:(CGFloat)padingY;
- (void) didScroll:(NSRect)rect;

@end
