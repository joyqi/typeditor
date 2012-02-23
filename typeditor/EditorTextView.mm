//
//  EditorTextView.m
//  typeditor
//
//  Created by  on 12-2-21.
//  Copyright (c) 2012年 MagnetJoy. All rights reserved.
//

#import "EditorTextView.h"
#import "EditorViewController.h"
#import "EditorStyle.h"

#define beginParagraphStyle(paragraphStyle) \
    NSDictionary *attributes = [[self typingAttributes] mutableCopy]; \
    NSMutableParagraphStyle *paragraphStyle; \
    if ([self defaultParagraphStyle]) { \
        paragraphStyle = [[self defaultParagraphStyle] mutableCopy]; \
    } else { \
        paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy]; \
    }

#define endParagraphStyle(paragraphStyle) \
    [attributes setValue:paragraphStyle forKey:NSParagraphStyleAttributeName]; \
    [self setTypingAttributes:attributes]; \
    [self setDefaultParagraphStyle:paragraphStyle]; \
    attributes = nil; \
    paragraphStyle = nil; \

#define beginEditorFont(type) \
    NSDictionary *attributes = [[self typingAttributes] mutableCopy]; \
    v8::String::Utf8Value type(value); \
    NSFontManager *fontManager = [NSFontManager sharedFontManager];

#define endEditorFont(newFont) \
    if (newFont) {\
        [self setDefaultFont:newFont];\
        [attributes setValue:newFont forKey:NSFontAttributeName]; \
        [self setTypingAttributes:attributes]; \
        [[self textStorage] addAttribute:NSFontAttributeName value:newFont range:NSMakeRange(0, [[[self textStorage] string] length])];\
    }\
    attributes = nil;

#define beginLineNumberFont(font) \
    NSFont *font = [[(EditorViewController *)[self editorViewController] lineNumber] font]; \
    NSFontManager *fontManager = [NSFontManager sharedFontManager];

#define endLineNumberFont(newFont) \
    [[(EditorViewController *)[self editorViewController] lineNumber] setFont:newFont]; \
    fontManager = nil; \
    newFont = nil;

@interface EditorTextView (Private)
- (NSColor *)colorWithString:(NSString *)stringColor;
- (NSUInteger)findCloseByLineIndent:(NSInteger)location;
@end

@implementation EditorTextView

@synthesize insertionPointWidth, softTab, tabInterval, tabStop, defaultFont, defaultColor, styles, editorViewController;

- (id) initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    
    if (self) {
        insertionPointWidth = 2.0f;
        lineEndings = @"\n";
        _textStorage = [self textStorage];
        styles = [NSMutableDictionary dictionary];
        
        if ([self font]) {
            [self setDefaultFont:[self font]];
        } else {
            [self setDefaultFont:[NSFont fontWithName:@"Helvetica" size:12.0f]];
        }
        
        if ([self textColor]) {
            [self setDefaultColor:[self textColor]];
        } else {
            [self setDefaultColor:[NSColor textColor]];
        }
    }
    
    return self;
}

- (void)setDefaultFont:(NSFont *)_defaultFont
{
    NSParagraphStyle *ps = [self defaultParagraphStyle];
    if (!ps) {
        ps = [NSParagraphStyle defaultParagraphStyle];
    }
    
    tabInterval = [ps defaultTabInterval];
    CGFloat width = [[_defaultFont screenFontWithRenderingMode:[_defaultFont renderingMode]] advancementForGlyph:(NSGlyph) ' '].width;
    tabStop = floor(tabInterval / width);
    
    defaultFont = _defaultFont;
}

- (void)drawInsertionPointInRect:(NSRect)rect color:(NSColor *)color turnedOn:(BOOL)flag
{
    rect.size.width = insertionPointWidth;
    
    if (flag) {
        [color set];
        [NSBezierPath fillRect:rect];
    } else {
        [self setNeedsDisplayInRect:[self visibleRect] avoidAdditionalLayout:NO];
    }
}

- (void)_drawInsertionPointInRect:(NSRect)rect color:(NSColor *)color
{
    [color set];
    rect.size.width = insertionPointWidth;
    [NSBezierPath fillRect:rect];
}

- (void)insertTab:(id)sender {
    v8::HandleScope handle_scope;
    v8::Persistent<v8::Context> context = [(EditorViewController *)editorViewController v8]->context;
    v8::Context::Scope context_scope(context);
    
    v8::Local<v8::Value> callback = context->Global()->GetHiddenValue(v8::String::New("tabHandler"));
    
    if (*callback && !callback->IsNull() && callback->IsFunction()) {        
        v8::Local<v8::Function> func = v8::Local<v8::Function>::Cast(callback);
        v8::Local<v8::Value> argv[2];
        argv[0] = v8::Integer::New([self selectedRange].location);
        argv[1] = v8::Integer::New([self lineCurrent]);
        
        func->Call(context->Global(), 2, argv);
        return;
    }
    
    [super insertTab:sender];
}

- (void)insertNewline:(id)sender {
    v8::HandleScope handle_scope;
    v8::Persistent<v8::Context> context = [(EditorViewController *)editorViewController v8]->context;
    v8::Context::Scope context_scope(context);
    NSUInteger location = [self selectedRange].location;
    
    v8::Local<v8::Value> callback = context->Global()->GetHiddenValue(v8::String::New("newLineHandler"));
    
    if (*callback && !callback->IsNull() && callback->IsFunction()) {        
        v8::Local<v8::Function> func = v8::Local<v8::Function>::Cast(callback);
        v8::Local<v8::Value> argv[3];
        argv[0] = v8::String::New([lineEndings cStringUsingEncoding:NSUTF8StringEncoding]);
        argv[1] = v8::Integer::New(location);
        argv[2] = v8::Integer::New([self lineCurrent]);
        
        func->Call(context->Global(), 3, argv);
        return;
    } else {
        [self replaceCharactersInRange:NSMakeRange(location, 0) withString:lineEndings];
    }
}

- (void)insertText:(id)insertString
{
    [super insertText:insertString];
    
    if (softTab && [insertString isEqualToString:@"\t"]) {
        NSRange range = [self selectedRange], replace = NSMakeRange(range.location - 1, 1);
        NSInteger count = [self countWidth:replace];
        [self replaceTab:replace withWidth:count];
    }
    
    if (nil != [self delegate]) {
        [(id<EditorTextViewDelegate>)[self delegate] insertText:insertString];
    }
}

- (NSFont *)fontAt:(NSUInteger)location
{
    NSRange rp;
    NSFont *currentFont;
    
    @try {
        currentFont = (NSFont *)[[self textStorage] attribute:NSFontAttributeName atIndex:location effectiveRange:&rp];
    }
    @finally {
        return defaultFont;
    }

    if (!currentFont) {
        return defaultFont;
    }
    
    return currentFont;
}

- (NSString *)stringAt:(NSUInteger)location withLength:(NSUInteger)length
{
    return [[self string] substringWithRange:NSMakeRange(location, length)];
}

- (NSString *)stringAt:(NSUInteger)location
{
    return [[self string] substringWithRange:NSMakeRange(location, 1)];
}

- (NSUInteger)lineAt:(NSUInteger)location
{
    NSLayoutManager *layoutManager = [self layoutManager];
    NSUInteger numberOfLines, index, numberOfGlyphs = [layoutManager numberOfGlyphs];
    NSRange lineRange;

    for (numberOfLines = 0, index = 0; index < numberOfGlyphs; numberOfLines++){
        (void) [layoutManager lineFragmentRectForGlyphAtIndex:index
                                               effectiveRange:&lineRange];
        
        if (location >= lineRange.location && location <= (lineRange.location + lineRange.length)) {
            break;
        }
        
        index = NSMaxRange(lineRange);
    }
    
    return numberOfLines + 1;
}

- (NSUInteger)lineCurrent
{
    NSRange range = [self selectedRange];
    NSUInteger location = &range ? range.location : 0;
    
    return [self lineAt:location];
}

- (NSRange)lineRange:(NSUInteger)line
{
    NSLayoutManager *layoutManager = [self layoutManager];
    NSUInteger numberOfLines, index, numberOfGlyphs = [layoutManager numberOfGlyphs];
    NSRange lineRange;
    
    for (numberOfLines = 0, index = 0; index < numberOfGlyphs; numberOfLines++){
        (void) [layoutManager lineFragmentRectForGlyphAtIndex:index
                                               effectiveRange:&lineRange];
        
        if (numberOfLines == line - 1) {
            return lineRange;
        }
        
        index = NSMaxRange(lineRange);
    }
    
    return lineRange;
}

- (CGFloat)spaceWidth:(NSUInteger)location
{
    NSFont *font = [self fontAt:location];
    return [[font screenFontWithRenderingMode:[font renderingMode]] advancementForGlyph:(NSGlyph) ' '].width;
}

- (CGFloat)spaceWidth
{
    NSRange range = [self selectedRange];
    NSUInteger location = &range ? range.location : 0;
    
    return [self spaceWidth:location];
}

- (NSUInteger)countWidth:(NSRange)range
{
    NSUInteger startGlyphIndex = [[self layoutManager] glyphIndexForCharacterAtIndex:range.location];
    /*
    NSRange effectiveRange;
    
    // tansfer tab width with space
    NSRect startRect = [[self layoutManager] lineFragmentUsedRectForGlyphAtIndex:startGlyphIndex effectiveRange:&effectiveRange];
    NSUInteger stopPos = (effectiveRange.length >= range.length ? range.length : effectiveRange.length) + range.location;
    NSUInteger stopGlyphIndex = [[self layoutManager] glyphIndexForCharacterAtIndex:stopPos];
    NSRect stopRect = [[self layoutManager] lineFragmentUsedRectForGlyphAtIndex:stopGlyphIndex effectiveRange:&effectiveRange];
     */
    
    NSRect rect = [[self layoutManager] boundingRectForGlyphRange:NSMakeRange(startGlyphIndex, range.length) inTextContainer:[self textContainer]];
    
    return round(rect.size.width / [self spaceWidth:range.location - 1]);
}

- (void)appendTab:(NSUInteger)location withWidth:(NSUInteger)width
{
    if (width <= 0) {
        return;
    }

    if (softTab) {
        [self replaceCharactersInRange:NSMakeRange(location, 0) 
            withString:[@"" stringByPaddingToLength:width withString:@" " startingAtIndex:0]];
    } else {
        NSUInteger repeat = ceil(width / tabStop);
        [self replaceCharactersInRange:NSMakeRange(location, 0) 
            withString:[@"" stringByPaddingToLength:repeat withString:@"\t" startingAtIndex:0]];
    }
}

- (void)replaceTab:(NSRange)range withWidth:(NSUInteger)width
{
    if (width <= 0) {
        return;
    }
    
    if (softTab) {
        [self replaceCharactersInRange:range withString:[@"" stringByPaddingToLength:width withString:@" " startingAtIndex:0]];
    } else {
        NSUInteger repeat = ceil(width / tabStop);
        [self replaceCharactersInRange:range withString:[@"" stringByPaddingToLength:repeat withString:@"\t" startingAtIndex:0]];
    }
}

- (void)setUpStyles:(const v8::Local<v8::Value> &)globalStyles
{
    if (globalStyles->IsObject() && !globalStyles->IsNull()) {
        v8::Local<v8::Object> stylesObject = v8::Local<v8::Object>::Cast(globalStyles);
        v8::Local<v8::Array> styleNames = stylesObject->GetPropertyNames();
        NSUInteger index, count = styleNames->Length();
        NSFont *styleFont;
        NSColor *styleColor, *styleBackgroundColor;
        NSFontManager *fontManager = [NSFontManager sharedFontManager];
        
        NSFontTraitMask styleFontMask;
        NSString *styleFontFamily;
        CGFloat styleFontSize;
        
        v8::Local<v8::String> propertyFontFamily = v8::String::New("font-family");
        v8::Local<v8::String> propertyFontSize = v8::String::New("font-size");
        v8::Local<v8::String> propertyFontWeight = v8::String::New("font-weight");
        v8::Local<v8::String> propertyFontStyle = v8::String::New("font-style");
        v8::Local<v8::String> propertyColor = v8::String::New("color");
        v8::Local<v8::String> propertyBackgroundColor = v8::String::New("background-color");
        
        for (index = 0; index < count; index ++) {
            v8::Local<v8::String> styleName = v8::Local<v8::String>::Cast(styleNames->Get(index));
            v8::Local<v8::Value> style = stylesObject->Get(styleNames->Get(index));
            
            v8::String::Utf8Value styleNameChar(styleName);
            NSString *styleNameString = cstring(*styleNameChar);
            
            if (style->IsObject() && !style->IsNull()) {
                v8::Local<v8::Object> styleObject = v8::Local<v8::Object>::Cast(style);
                
                styleFontMask = [[defaultFont fontDescriptor] symbolicTraits];
                
                // set up foreground color
                if (!styleObject->Get(propertyColor)->IsNull()) {
                    v8::String::Utf8Value color(styleObject->Get(propertyColor));
                    styleColor = [self colorWithString:cstring(*color)];
                } else {
                    styleColor = defaultColor;
                }
                
                // set up background color
                if (!styleObject->Get(propertyBackgroundColor)->IsNull()) {
                    v8::String::Utf8Value backgroundColor(styleObject->Get(propertyBackgroundColor));
                    styleBackgroundColor = [self colorWithString:cstring(*backgroundColor)];
                } else {
                    styleBackgroundColor = defaultColor;
                }
                
                // set up font styles
                if (!styleObject->Get(propertyFontFamily)->IsNull()) {
                    v8::String::Utf8Value fontFamily(styleObject->Get(propertyFontFamily));
                    styleFontFamily = cstring(*fontFamily);
                } else {
                    styleFontFamily = [defaultFont familyName];
                }
                
                if (!styleObject->Get(propertyFontSize)->IsNull()) {
                    styleFontSize = styleObject->Get(propertyFontFamily)->NumberValue();
                } else {
                    styleFontSize = [defaultFont pointSize];
                }
                
                if (!styleObject->Get(propertyFontWeight)->IsNull()) {
                    v8::String::Utf8Value fontWeight(styleObject->Get(propertyFontWeight));
                    styleFontMask |= [cstring(*fontWeight) isEqualToString:@"bold"] ? NSBoldFontMask : NSUnboldFontMask;
                }
                
                if (!styleObject->Get(propertyFontStyle)->IsNull()) {
                    v8::String::Utf8Value fontStyle(styleObject->Get(propertyFontStyle));
                    styleFontMask |= [cstring(*fontStyle) isEqualToString:@"italic"] ? NSItalicFontMask : NSUnitalicFontMask;
                }
                
                styleFont = [fontManager fontWithFamily:styleFontFamily
                                                 traits:styleFontMask
                                                 weight:0
                                                   size:styleFontSize];

                [styles setObject:[[EditorStyle alloc] init:styleFont 
                                                  withColor:styleColor 
                                        withBackgroundColor:styleBackgroundColor] 
                           forKey:styleNameString];
            }
        }
    }
}

- (void)setUpEditorStyle:(const v8::Local<v8::Value> &)editorStyle
{
    if (editorStyle->IsObject() && !editorStyle->IsNull()) {
        v8::Local<v8::Object> styleObject = v8::Local<v8::Object>::Cast(editorStyle);
        NSFontManager *fontManager = [NSFontManager sharedFontManager];
        
        NSFontTraitMask styleFontMask;
        NSString *styleFontFamily;
        CGFloat styleFontSize;
        
        v8::Local<v8::String> propertyFontFamily = v8::String::New("font-family");
        v8::Local<v8::String> propertyFontSize = v8::String::New("font-size");
        v8::Local<v8::String> propertyFontWeight = v8::String::New("font-weight");
        v8::Local<v8::String> propertyFontStyle = v8::String::New("font-style");
        v8::Local<v8::String> propertyColor = v8::String::New("color");
        v8::Local<v8::String> propertyBackgroundColor = v8::String::New("background-color");
        v8::Local<v8::String> propertySelectionColor = v8::String::New("selection-color");
        v8::Local<v8::String> propertySelectionBackgroundColor = v8::String::New("selection-background-color");
        v8::Local<v8::String> propertyPaddingHorizontal = v8::String::New("padding-horizontal");
        v8::Local<v8::String> propertyPaddingVertical = v8::String::New("padding-vertical");
        v8::Local<v8::String> propertyCursorWidth = v8::String::New("cursor-width");
        v8::Local<v8::String> propertyCursorColor = v8::String::New("cursor-color");
        v8::Local<v8::String> propertyIsSoftTab = v8::String::New("soft-tab");
        v8::Local<v8::String> propertyEndingType = v8::String::New("line-endings");
        v8::Local<v8::String> propertyLineHeight = v8::String::New("line-height");
        v8::Local<v8::String> propertyTabStop = v8::String::New("tab-stop");
        v8::Local<v8::String> propertyLineNumber = v8::String::New("line-number");
        v8::Local<v8::String> propertyLineNumberColor = v8::String::New("line-number-color");
        v8::Local<v8::String> propertyLineNumberBackgroundColor = v8::String::New("line-number-background-color");
        v8::Local<v8::String> propertyLineNumberFontFamily = v8::String::New("line-number-font-family");
        v8::Local<v8::String> propertyLineNumberFontSize = v8::String::New("line-number-font-size");
        
        styleFontMask = [[defaultFont fontDescriptor] symbolicTraits];
        
        // set up foreground color
        if (!styleObject->Get(propertyColor)->IsNull()) {
            v8::String::Utf8Value color(styleObject->Get(propertyColor));
            [self setDefaultColor:[self colorWithString:cstring(*color)]];
        }
        
        // set up background color
        if (!styleObject->Get(propertyBackgroundColor)->IsNull()) {
            v8::String::Utf8Value backgroundColor(styleObject->Get(propertyBackgroundColor));
            [self setBackgroundColor:[self colorWithString:cstring(*backgroundColor)]];
        }
        
        // set up font styles
        if (!styleObject->Get(propertyFontFamily)->IsNull()) {
            v8::String::Utf8Value fontFamily(styleObject->Get(propertyFontFamily));
            styleFontFamily = cstring(*fontFamily);
        } else {
            styleFontFamily = [defaultFont familyName];
        }
        
        if (!styleObject->Get(propertyFontSize)->IsNull()) {
            styleFontSize = styleObject->Get(propertyFontFamily)->NumberValue();
        } else {
            styleFontSize = [defaultFont pointSize];
        }
        
        if (!styleObject->Get(propertyFontWeight)->IsNull()) {
            v8::String::Utf8Value fontWeight(styleObject->Get(propertyFontWeight));
            styleFontMask |= [cstring(*fontWeight) isEqualToString:@"bold"] ? NSBoldFontMask : NSUnboldFontMask;
        }
        
        if (!styleObject->Get(propertyFontStyle)->IsNull()) {
            v8::String::Utf8Value fontStyle(styleObject->Get(propertyFontStyle));
            styleFontMask |= [cstring(*fontStyle) isEqualToString:@"italic"] ? NSItalicFontMask : NSUnitalicFontMask;
        }
        
        [self setDefaultFont:[fontManager fontWithFamily:styleFontFamily
                                                  traits:styleFontMask
                                                  weight:0
                                                    size:styleFontSize]];
        
        // selected styles
        NSMutableDictionary *selectedTextAttributes = [[self selectedTextAttributes] mutableCopy];
        if (!styleObject->Get(propertySelectionColor)->IsNull()) {
            v8::String::Utf8Value selectionColor(styleObject->Get(propertySelectionColor));
            [selectedTextAttributes setValue:[self colorWithString:cstring(*selectionColor)] forKey:NSForegroundColorAttributeName];
        }
        
        if (!styleObject->Get(propertySelectionBackgroundColor)->IsNull()) {
            v8::String::Utf8Value selectionBackgroundColor(styleObject->Get(propertySelectionBackgroundColor));
            [selectedTextAttributes setValue:[self colorWithString:cstring(*selectionBackgroundColor)] forKey:NSBackgroundColorAttributeName];
        }
        
        [self setSelectedTextAttributes:selectedTextAttributes];
        selectedTextAttributes = nil;
        
        // padding style
        NSSize paddingSize = [self textContainerInset];
        if (!styleObject->Get(propertyPaddingHorizontal)->IsNull()) {
            paddingSize.width = styleObject->Get(propertyPaddingHorizontal)->IntegerValue();
        }
        
        if (!styleObject->Get(propertyPaddingVertical)->IsNull()) {
            paddingSize.height = styleObject->Get(propertyPaddingVertical)->IntegerValue();
        }
        
        [self setTextContainerInset:paddingSize];
        
        // global set
        if (!styleObject->Get(propertyCursorColor)->IsNull()) {
            v8::String::Utf8Value cursorColor(styleObject->Get(propertyCursorColor));
            [self setInsertionPointColor:[self colorWithString:cstring(*cursorColor)]];
        }
        
        if (!styleObject->Get(propertyCursorWidth)->IsNull()) {
            [self setInsertionPointWidth:styleObject->Get(propertyCursorWidth)->NumberValue()];
        }
        
        if (!styleObject->Get(propertyIsSoftTab)->IsNull()) {
            softTab = styleObject->Get(propertyIsSoftTab)->BooleanValue();
        }
        
        if (!styleObject->Get(propertyEndingType)->IsNull()) {
            v8::String::Utf8Value endingTypeValue(styleObject->Get(propertyEndingType));
            NSString *endingType = [cstring(*endingTypeValue) uppercaseString];
            
            if ([endingType isEqualToString:@"CR"]) {
                lineEndings = @"\r";
            } else if ([endingType isEqualToString:@"CRLF"]) {
                lineEndings = @"\r\n";
            } else {
                lineEndings = @"\n";
            }
        }
        
        // pragraph
        NSDictionary *attributes = [[self typingAttributes] mutableCopy];
        NSMutableParagraphStyle *paragraphStyle;
        if ([self defaultParagraphStyle]) {
            paragraphStyle = [[self defaultParagraphStyle] mutableCopy];
        } else {
            paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
        }
        
        if (!styleObject->Get(propertyTabStop)->IsNull()) {
            float spaceWidth = [self spaceWidth:0];
            NSUInteger tabStopProperty = styleObject->Get(propertyTabStop)->IntegerValue();
            
            [paragraphStyle setTabStops:[NSArray array]];
            [paragraphStyle setDefaultTabInterval: tabStopProperty * spaceWidth];
            tabInterval = tabStopProperty * spaceWidth;
            tabStop = tabStopProperty;
        }
        
        if (!styleObject->Get(propertyLineHeight)->IsNull()) {
            NSUInteger lineHeight = styleObject->Get(propertyLineHeight)->IntegerValue();
            
            [paragraphStyle setMaximumLineHeight:lineHeight];
            [paragraphStyle setMinimumLineHeight:lineHeight];
        }
        
        [attributes setValue:paragraphStyle forKey:NSParagraphStyleAttributeName];
        [self setTypingAttributes:attributes];
        [self setDefaultParagraphStyle:paragraphStyle];
        attributes = nil;
        paragraphStyle = nil;
        
        // line number
        if (!styleObject->Get(propertyLineNumber)->IsNull()) {
            [[(EditorViewController *)[self editorViewController] scroll] 
             setRulersVisible:styleObject->Get(propertyLineNumber)->BooleanValue()];
        }
        
        if (!styleObject->Get(propertyLineNumberColor)->IsNull()) {
            v8::String::Utf8Value lineNumberColor(styleObject->Get(propertyLineNumberColor));
            [[(EditorViewController *)[self editorViewController] lineNumber] 
             setTextColor:[self colorWithString:cstring(*lineNumberColor)]];
        }
        
        if (!styleObject->Get(propertyLineNumberBackgroundColor)->IsNull()) {
            v8::String::Utf8Value lineNumberBackgroundColor(styleObject->Get(propertyLineNumberBackgroundColor));
            [[(EditorViewController *)[self editorViewController] lineNumber] 
             setBackgroundColor:[self colorWithString:cstring(*lineNumberBackgroundColor)]];
        }
        
        // line number font
        if (!styleObject->Get(propertyLineNumberFontFamily)->IsNull()) {
            v8::String::Utf8Value lineNumberFontFamily(styleObject->Get(propertyLineNumberFontFamily));
            styleFontFamily = cstring(*lineNumberFontFamily);
        } else {
            styleFontFamily = [[[(EditorViewController *)[self editorViewController] lineNumber] font] familyName];
        }
        
        if (!styleObject->Get(propertyLineNumberFontSize)->IsNull()) {
            styleFontSize = styleObject->Get(propertyLineNumberFontSize)->NumberValue();
        } else {
            styleFontSize = [[[(EditorViewController *)[self editorViewController] lineNumber] font] pointSize];
        }
        
        [[(EditorViewController *)[self editorViewController] lineNumber] setFont:
         [fontManager fontWithFamily:styleFontFamily
                              traits:[[[[(EditorViewController *)[self editorViewController] lineNumber] font] 
                                       fontDescriptor] symbolicTraits]
                              weight:0
                                size:styleFontSize]];
        
        fontManager = nil;
    }
}

- (void)setTextStyle:(int)location withLength:(int)length forType:(NSString *)type withValue:(v8::Local<v8::Value>)value
{
    NSRange found = NSMakeRange(location, length);
    
    if ([type isEqualToString:@"color"]) {
        v8::String::Utf8Value color(value);
        [_textStorage addAttribute:NSForegroundColorAttributeName value:[self colorWithString:cstring(*color)] range:found];
    } else if ([type isEqualToString:@"background-color"]) {
        v8::String::Utf8Value bg(value);
        [_textStorage addAttribute:NSBackgroundColorAttributeName value:[self colorWithString:cstring(*bg)] range:found];
    } else if ([type isEqualToString:@"underline"]) {
        [_textStorage addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:value->IntegerValue()] range:found];
    } else if ([type isEqualToString:@"underline-color"]) {
        v8::String::Utf8Value underline(value);
        [_textStorage addAttribute:NSUnderlineColorAttributeName value:[self colorWithString:cstring(*underline)] range:found];
    } else if ([type isEqualToString:@"font-family"]) {
        NSFont *currentFont = [self fontAt:location];
        NSFontManager *fontManager = [NSFontManager sharedFontManager];
        v8::String::Utf8Value fontFamily(value);
        
        NSFont *newFont = [fontManager fontWithFamily:cstring(*fontFamily)
                                               traits:[[currentFont fontDescriptor] symbolicTraits]
                                               weight:0
                                                 size:[currentFont pointSize]];
        
        if (newFont) {
            [_textStorage addAttribute:NSFontAttributeName value:newFont range:found];
        }
    } else if ([type isEqualToString:@"font-size"]) {
        NSFont *currentFont = [self fontAt:location];
        NSFontManager *fontManager = [NSFontManager sharedFontManager];
        
        NSFont *newFont = [fontManager fontWithFamily:[currentFont familyName]
                                               traits:[[currentFont fontDescriptor] symbolicTraits]
                                               weight:0
                                                 size:value->NumberValue()];
        
        if (newFont) {
            [_textStorage addAttribute:NSFontAttributeName value:newFont range:found];
        }
    } else if ([type isEqualToString:@"font-weight"]) {
        NSFont *currentFont = [self fontAt:location];
        v8::String::Utf8Value fontWeight(value);
        
        NSFontManager *fontManager = [NSFontManager sharedFontManager];
        NSFont *newFont = [fontManager fontWithFamily:[currentFont familyName]
                                               traits:[[currentFont fontDescriptor] symbolicTraits] | [cstring(*fontWeight) isEqualToString:@"bold"] ? NSBoldFontMask : NSUnboldFontMask
                                               weight:0
                                                 size:[currentFont pointSize]];
        
        if (newFont) {
            [_textStorage addAttribute:NSFontAttributeName value:newFont range:found];
        }
    } else if ([type isEqualToString:@"font-style"]) {
        NSFont *currentFont = [self fontAt:location];
        v8::String::Utf8Value fontStyle(value);
        
        NSFontManager *fontManager = [NSFontManager sharedFontManager];
        NSFont *newFont = [fontManager fontWithFamily:[currentFont familyName]
                                               traits:[[currentFont fontDescriptor] symbolicTraits] | ([cstring(*fontStyle) isEqualToString:@"italic"] ? NSItalicFontMask : NSUnitalicFontMask)
                                               weight:0
                                                 size:[currentFont pointSize]];
        
        if (newFont) {
            [_textStorage addAttribute:NSFontAttributeName value:newFont range:found];
        }
    }
}

- (void)setEditorStyle:(NSString *)type withValue:(v8::Local<v8::Value>)value
{
    if ([type isEqualToString:@"color"]) {
        
        // 编辑器默认颜色
        v8::String::Utf8Value color(value);
        NSDictionary *attributes = [[self typingAttributes] mutableCopy];
        [attributes setValue:[self colorWithString:cstring(*color)] forKey:NSForegroundColorAttributeName];
        [self setDefaultColor:[self colorWithString:cstring(*color)]];
        [self setTypingAttributes:attributes];
        
    } else if ([type isEqualToString:@"background-color"]) {
        
        // 编辑器默认背景
        v8::String::Utf8Value bg(value);
        [self setBackgroundColor:[self colorWithString:cstring(*bg)]];

    } else if ([type isEqualToString:@"selection-color"]) {
        
        // 选择区默认背景
        v8::String::Utf8Value color(value);
        NSMutableDictionary *selectedTextAttributes = [[self selectedTextAttributes] mutableCopy];
        [selectedTextAttributes setValue:[self colorWithString:cstring(*color)] forKey:NSForegroundColorAttributeName];
        [self setSelectedTextAttributes:selectedTextAttributes];
        selectedTextAttributes = nil;
        
    } else if ([type isEqualToString:@"selection-background-color"]) {
        
        // 选择区默认颜色
        v8::String::Utf8Value bg(value);
        NSMutableDictionary *selectedTextAttributes = [[self selectedTextAttributes] mutableCopy];
        [selectedTextAttributes setValue:[self colorWithString:cstring(*bg)] forKey:NSBackgroundColorAttributeName];
        [self setSelectedTextAttributes:selectedTextAttributes];
        selectedTextAttributes = nil;
        
    } else if ([type isEqualToString:@"font-family"]) {
        
        // 默认字体
        beginEditorFont(fontName);
        
        NSFont *newFont = [fontManager fontWithFamily:cstring(*fontName)
                                               traits:[[defaultFont fontDescriptor] symbolicTraits]
                                               weight:0
                                                 size:[defaultFont pointSize]];
        
        endEditorFont(newFont);

    } else if ([type isEqualToString:@"font-size"]) {
        
        // 默认字体大小
        NSFontManager *fontManager = [NSFontManager sharedFontManager];
        NSDictionary *attributes = [[self typingAttributes] mutableCopy]; \
        
        NSFont *newFont = [fontManager fontWithFamily:[defaultFont familyName]
                                               traits:[[defaultFont fontDescriptor] symbolicTraits]
                                               weight:0
                                                 size:value->NumberValue()];
        
        endEditorFont(newFont);
        
    } else if ([type isEqualToString:@"font-weight"]) {
        
        // 默认粗体
        beginEditorFont(fontWeight);
        
        NSFont *newFont = [fontManager fontWithFamily:[defaultFont familyName]
                                               traits:[[defaultFont fontDescriptor] symbolicTraits] | [cstring(*fontWeight) isEqualToString:@"bold"] ? NSBoldFontMask : NSUnboldFontMask
                                               weight:0
                                                 size:[defaultFont pointSize]];
        
        endEditorFont(newFont);

    } else if ([type isEqualToString:@"font-style"]) {
        
        // 默认斜体
        beginEditorFont(fontStyle);
        
        NSFont *newFont = [fontManager fontWithFamily:[defaultFont familyName]
                                               traits:[[defaultFont fontDescriptor] symbolicTraits] | ([cstring(*fontStyle) isEqualToString:@"italic"] ? NSItalicFontMask : NSUnitalicFontMask)
                                               weight:0
                                                 size:[defaultFont pointSize]];
        
        endEditorFont(newFont);

    } else if ([type isEqualToString:@"padding-horizontal"]) {
        
        // 水平位移
        NSSize size = [self textContainerInset];
        size.width = value->IntegerValue();
        [self setTextContainerInset:size];

    } else if ([type isEqualToString:@"padding-vertical"]) {
        
        // 垂直位移
        NSSize size = [self textContainerInset];
        size.height = value->IntegerValue();
        [self setTextContainerInset:size];

    } else if ([type isEqualToString:@"line-height"]) {
        
        // 行高
        beginParagraphStyle(paragraphStyle);
        
        [paragraphStyle setMaximumLineHeight:value->NumberValue()];
        [paragraphStyle setMinimumLineHeight:value->NumberValue()];
        
        endParagraphStyle(paragraphStyle);

    } else if ([type isEqualToString:@"cursor-width"]) {
        
        // 光标宽度
        [self setInsertionPointWidth:value->NumberValue()];

    } else if ([type isEqualToString:@"cursor-color"]) {
        
        // 光标颜色
        v8::String::Utf8Value color(value);
        [self setInsertionPointColor:[self colorWithString:cstring(*color)]];

    } else if ([type isEqualToString:@"tab-stop"]) {
        
        // 缩进
        beginParagraphStyle(paragraphStyle);
        
        float spaceWidth = [self spaceWidth:0];
        [paragraphStyle setTabStops:[NSArray array]];
        [paragraphStyle setDefaultTabInterval:value->NumberValue() * spaceWidth];
        tabInterval = value->NumberValue() * spaceWidth;
        tabStop = value->NumberValue();
        
        endParagraphStyle(paragraphStyle);
    } else if ([type isEqualToString:@"soft-tab"]) {
        softTab = value->BooleanValue();
    } else if ([type isEqualToString:@"line-endings"]) {
        v8::String::Utf8Value endingTypeValue(value);
        NSString *endingType = [cstring(*endingTypeValue) uppercaseString];
        
        if ([endingType isEqualToString:@"CR"]) {
            lineEndings = @"\r";
        } else if ([endingType isEqualToString:@"CRLF"]) {
            lineEndings = @"\r\n";
        } else {
            lineEndings = @"\n";
        }
    } else if ([type isEqualToString:@"line-number"]) {
        [[(EditorViewController *)[self editorViewController] scroll] setRulersVisible:value->BooleanValue()];
    } else if ([type isEqualToString:@"line-number-color"]) {
        v8::String::Utf8Value color(value);
        [[(EditorViewController *)[self editorViewController] lineNumber] setTextColor:[self colorWithString:cstring(*color)]];
    } else if ([type isEqualToString:@"line-number-background-color"]) {
        v8::String::Utf8Value color(value);
        [[(EditorViewController *)[self editorViewController] lineNumber] setBackgroundColor:[self colorWithString:cstring(*color)]];
    } else if ([type isEqualToString:@"line-number-font-family"]) {
        beginLineNumberFont(font)

        v8::String::Utf8Value fontFamily(value);
        NSFont *newFont = [fontManager fontWithFamily:cstring(*fontFamily)
                                               traits:[[font fontDescriptor] symbolicTraits]
                                               weight:0
                                                 size:[font pointSize]];
        
        endLineNumberFont(newFont);
    } else if ([type isEqualToString:@"line-number-font-size"]) {
        beginLineNumberFont(font)
        
        NSFont *newFont = [fontManager fontWithFamily:[font familyName]
                                               traits:[[font fontDescriptor] symbolicTraits]
                                               weight:0
                                                 size:value->NumberValue()];
        
        endLineNumberFont(newFont);
    }
}

# pragma Mark - Private methods
- (NSColor *)colorWithString:(NSString *)htmlString
{
    NSError *error = nil;
    int length = [htmlString length];
    NSRegularExpression *regex = [NSRegularExpression         
                                  regularExpressionWithPattern:@"^#[0-9a-f]{3,6}$"
                                  options:NSRegularExpressionCaseInsensitive
                                  error:&error];
    
    // not matches return black color for default
    if (1 != [regex numberOfMatchesInString:htmlString options:0 range:NSMakeRange(0, length)]
        || (length != 4 && length != 7)) {
        return [NSColor blackColor];
    }
    
    // sub color
    if (4 == [htmlString length]) {
        htmlString = [[NSString alloc] initWithFormat:@"%@%@", htmlString, [htmlString substringFromIndex:1]];
    }
    
    unsigned int r, g, b;
    [[NSScanner scannerWithString:[htmlString substringWithRange:NSMakeRange(1, 2)]] scanHexInt:&r];
    [[NSScanner scannerWithString:[htmlString substringWithRange:NSMakeRange(3, 2)]] scanHexInt:&g];
    [[NSScanner scannerWithString:[htmlString substringWithRange:NSMakeRange(5, 2)]] scanHexInt:&b];
    
    return [NSColor colorWithCalibratedRed:((float) r / 255.0f) 
                                     green:((float) g / 255.0f) blue:((float) b / 255.0f) alpha:1.0f];
}

@end
