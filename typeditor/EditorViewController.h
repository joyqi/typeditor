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

#define font(f) \
NSRange rp; \
NSFont *f = (NSFont *)[textStorage attribute:NSFontAttributeName atIndex:location effectiveRange:&rp]; \
if (!f) { \
    f = font; \
}

#define FONT_SPACE_WIDTH \
[[font screenFontWithRenderingMode:NSFontDefaultRenderingMode] advancementForGlyph:(NSGlyph) ' '].width

#define beginParagraphStyle(paragraphStyle) \
NSDictionary *attributes = [[editor typingAttributes] mutableCopy]; \
NSMutableParagraphStyle *paragraphStyle; \
if ([editor defaultParagraphStyle]) { \
    paragraphStyle = [[editor defaultParagraphStyle] mutableCopy]; \
} else { \
    paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy]; \
}

#define endParagraphStyle(paragraphStyle) \
[attributes setValue:paragraphStyle forKey:NSParagraphStyleAttributeName]; \
[editor setTypingAttributes:attributes]; \
[editor setDefaultParagraphStyle:paragraphStyle]; \
attributes = nil; \
paragraphStyle = nil; \

#define beginEditorFont(type) \
v8::String::Utf8Value type(value); \
NSFontManager *fontManager = [NSFontManager sharedFontManager];

#define  endEditorFont(newFont) \
if (newFont) {\
font = newFont;\
[editor setFont:font];\
[textStorage addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, [[textStorage string] length])];\
}

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
    
    // master font
    NSFont *font;
    
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
@property (strong, nonatomic) NSFont *font;
@property (strong, nonatomic) V8Cocoa *v8;

- (id)initWithWindow:(NSWindow *)parent;
- (void)setTextStyle:(int)location withLength:(int)length forType:(NSString *)type withValue:(v8::Local<v8::Value>)value;
- (void)setText:(int)location withLength:(int)length replacementString:(NSString *)string;
- (void)setEditorStyle:(NSString *)type withValue:(v8::Local<v8::Value>)value;

@end
