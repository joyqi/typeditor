//
//  EditorViewController.m
//  typeditor
//
//  Created by  on 12-2-20.
//  Copyright (c) 2012年 MagnetJoy. All rights reserved.
//

#import "EditorViewController.h"
#import "EditorViewReplacement.h"

@interface EditorViewController (Private)
- (NSColor *)colorWithString:(NSString *)stringColor;
@end

@implementation EditorViewController

@synthesize window, scroll, editor, holdReplacement, editing, font, v8;

// init with parent window
- (id)initWithWindow:(NSWindow *)parent
{
    self = [super initWithNibName:@"EditorViewController" bundle:nil];
    
    if (self) {
        window = parent;
        
        scroll = [[NSScrollView alloc] initWithFrame:[[window contentView] frame]];
        NSSize contentSize = [scroll contentSize];
        
        [scroll setBorderType:NSNoBorder];
        [scroll setHasVerticalScroller:YES];
        [scroll setHasHorizontalScroller:NO];
        [scroll setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [scroll setDrawsBackground:NO];
        
        editor = [[EditorTextView alloc] initWithFrame:[[window contentView] frame]];
        [editor setMinSize:NSMakeSize(0.0, contentSize.height)];
        [editor setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];
        [editor setVerticallyResizable:YES];
        [editor setHorizontallyResizable:NO];
        [editor setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        
        [[editor textContainer] setContainerSize:NSMakeSize(contentSize.width, FLT_MAX)];
        [[editor textContainer] setWidthTracksTextView:YES];
        
        // disale rich edit
        [editor setRichText:NO];
        [editor setImportsGraphics:NO];
        
        // default font
        font = [editor font];
        if (!font) {
            font = [NSFont fontWithName:@"Helvetica" size:12.0f];
        }
        
        [scroll setDocumentView:editor];
        [window setContentView:scroll];
        [window makeKeyAndOrderFront:nil];
        [window makeFirstResponder:editor];
        
        lineNumber = [[EditorLineNumberView alloc] initWithScrollView:scroll];
        [scroll setVerticalRulerView:lineNumber];
        [scroll setRulersVisible:YES];
        
        v8 = [[V8Cocoa alloc] init];
        [v8 embed:self];
        
        // set delegate
        [editor setDelegate:self];
        [[editor textStorage] setDelegate:self];
        textStorage = [editor textStorage];
        
        // init var
        editing = NO;
        holdReplacement = [NSMutableArray array];
    }
    
    return self;
}

- (void)textStorageDidProcessEditing:(NSNotification *)notification
{
    // is editing
    editing = YES;
    
    // clear all style
    // textStorage = [notification object];
    NSString *string = [textStorage string];
    NSRange range = NSMakeRange(0, [string length]);
    
    [textStorage removeAttribute:NSForegroundColorAttributeName range:range];
    [textStorage removeAttribute:NSBackgroundColorAttributeName range:range];
    [textStorage removeAttribute:NSUnderlineStyleAttributeName range:range];
    [textStorage removeAttribute:NSUnderlineColorAttributeName range:range];
    [textStorage removeAttribute:NSFontAttributeName range:range];
    [textStorage addAttribute:NSFontAttributeName value:font range:range];
    [textStorage fixAttributesInRange:range];

    
    v8::HandleScope handle_scope;
    v8::Persistent<v8::Context> context = [self v8]->context;
    v8::Context::Scope context_scope(context);
    
    v8::Local<v8::Value> callback = context->Global()->GetHiddenValue(v8::String::New("lexerCallback"));
    
    if (*callback && !callback->IsNull()) {        
        v8::Local<v8::Array> callbackArray = v8::Local<v8::Array>::Cast(callback);
        v8::Local<v8::Value> argv[1];
        int index, length = callbackArray->Length();
        
        argv[0] = v8::String::New([string cStringUsingEncoding:NSUTF8StringEncoding]);
        
        for (index = 0; index < length; index ++) {
            v8::Local<v8::Function> func = v8::Local<v8::Function>::Cast(callbackArray->Get(index));
            func->Call(context->Global(), 1, argv);
        }
    }
}

- (void)textDidChange:(NSNotification*)notification
{
    editing = FALSE;
    
    if (0 == [holdReplacement count]) {
        return;
    }
    
    for (EditorViewReplacement *replacement in holdReplacement) {
        [textStorage beginEditing];
        [textStorage replaceCharactersInRange:[replacement area] withString:[replacement string]];
        [textStorage endEditing];
    }
    
    [holdReplacement removeAllObjects];
}

- (void)insertText:(id)insertString
{
    v8::HandleScope handle_scope;
    v8::Persistent<v8::Context> context = [self v8]->context;
    v8::Context::Scope context_scope(context);
    
    v8::Local<v8::Value> callback = context->Global()->GetHiddenValue(v8::String::New("enterCallback"));
    
    if (*callback && !callback->IsNull()) {        
        v8::Local<v8::Array> callbackArray = v8::Local<v8::Array>::Cast(callback);
        v8::Local<v8::Value> argv[2];
        int index, length = callbackArray->Length();
        
        argv[0] = v8::String::New([insertString cStringUsingEncoding:NSUTF8StringEncoding]);
        argv[1] = v8::Integer::New([editor selectedRange].location);
        
        for (index = 0; index < length; index ++) {
            v8::Local<v8::Function> func = v8::Local<v8::Function>::Cast(callbackArray->Get(index));
            func->Call(context->Global(), 2, argv);
        }
    }
}

- (void)setTextStyle:(int)location withLength:(int)length forType:(NSString *)type withValue:(v8::Local<v8::Value>)value
{
    NSRange found = NSMakeRange(location, length);
    
    if ([type isEqualToString:@"color"]) {
        v8::String::Utf8Value color(value);
        [textStorage addAttribute:NSForegroundColorAttributeName value:[self colorWithString:cstring(*color)] range:found];
    } else if ([type isEqualToString:@"background-color"]) {
        v8::String::Utf8Value bg(value);
        [textStorage addAttribute:NSBackgroundColorAttributeName value:[self colorWithString:cstring(*bg)] range:found];
    } else if ([type isEqualToString:@"underline"]) {
        [textStorage addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:value->IntegerValue()] range:found];
    } else if ([type isEqualToString:@"underline-color"]) {
        v8::String::Utf8Value underline(value);
        [textStorage addAttribute:NSUnderlineColorAttributeName value:[self colorWithString:cstring(*underline)] range:found];
    } else if ([type isEqualToString:@"font-family"]) {
        font(currentFont);
        v8::String::Utf8Value fontName(value);
        NSFontManager *fontManager = [NSFontManager sharedFontManager];
        NSFont *newFont = [fontManager fontWithFamily:cstring(*fontName)
                                                  traits:[[currentFont fontDescriptor] symbolicTraits]
                                                  weight:0
                                                    size:[currentFont pointSize]];
        if (newFont) {
            [textStorage addAttribute:NSFontAttributeName value:newFont range:found];
        }
    } else if ([type isEqualToString:@"font-size"]) {
        font(currentFont);
        NSFontManager *fontManager = [NSFontManager sharedFontManager];
        NSFont *newFont = [fontManager fontWithFamily:[currentFont familyName]
                                               traits:[[currentFont fontDescriptor] symbolicTraits]
                                               weight:0
                                                 size:value->NumberValue()];

        if (newFont) {
            [textStorage addAttribute:NSFontAttributeName value:newFont range:found];
        }
    } else if ([type isEqualToString:@"font-weight"]) {
        font(currentFont);
        v8::String::Utf8Value fontWeight(value);
        NSFontManager *fontManager = [NSFontManager sharedFontManager];
        NSFont *newFont = [fontManager fontWithFamily:[currentFont familyName]
                                               traits:[[currentFont fontDescriptor] symbolicTraits] | [cstring(*fontWeight) isEqualToString:@"bold"] ? NSBoldFontMask : NSUnboldFontMask
                                               weight:0
                                                 size:[currentFont pointSize]];
        
        if (newFont) {
            [textStorage addAttribute:NSFontAttributeName value:newFont range:found];
        }
    } else if ([type isEqualToString:@"font-style"]) {
        font(currentFont);
        v8::String::Utf8Value fontStyle(value);
        NSFontManager *fontManager = [NSFontManager sharedFontManager];
        NSFont *newFont = [fontManager fontWithFamily:[currentFont familyName]
                                               traits:[[currentFont fontDescriptor] symbolicTraits] | ([cstring(*fontStyle) isEqualToString:@"italic"] ? NSItalicFontMask : NSUnitalicFontMask)
                                               weight:0
                                                 size:[currentFont pointSize]];
        
        if (newFont) {
            [textStorage addAttribute:NSFontAttributeName value:newFont range:found];
        }
    }
}

- (void)setText:(int)location withLength:(int)length replacementString:(NSString *)string
{
    NSRange area = NSMakeRange(location, length);
    // NSRange append = NSMakeRange(location, 0);
    
    // if is not edting
    if (!editing) {
        [textStorage replaceCharactersInRange:area withString:string];
    } else {
        // add to hold replacement
        EditorViewReplacement *replacement = [[EditorViewReplacement alloc] init:area replacementString:string];
        [holdReplacement addObject:replacement];
        replacement = nil;
    }
}

- (void)setEditorStyle:(NSString *)type withValue:(v8::Local<v8::Value>)value
{
    if ([type isEqualToString:@"color"]) {
        v8::String::Utf8Value color(value);
        [editor setTextColor:[self colorWithString:cstring(*color)]];
    } else if ([type isEqualToString:@"background-color"]) {
        v8::String::Utf8Value bg(value);
        [editor setBackgroundColor:[self colorWithString:cstring(*bg)]];
    } else if ([type isEqualToString:@"font-family"]) {
        v8::String::Utf8Value fontName(value);
        NSFontManager *fontManager = [NSFontManager sharedFontManager];
        NSFont *newFont = [fontManager fontWithFamily:cstring(*fontName)
                                               traits:[[font fontDescriptor] symbolicTraits]
                                               weight:0
                                                 size:[font pointSize]];
        if (newFont) {
            font = newFont;
            [editor setFont:font];
        }
    } else if ([type isEqualToString:@"font-size"]) {
        NSFontManager *fontManager = [NSFontManager sharedFontManager];
        NSFont *newFont = [fontManager fontWithFamily:[font familyName]
                                               traits:[[font fontDescriptor] symbolicTraits]
                                               weight:0
                                                 size:value->NumberValue()];
        
        if (newFont) {
            font = newFont;
            [editor setFont:font];
        }
    } else if ([type isEqualToString:@"font-weight"]) {
        v8::String::Utf8Value fontWeight(value);
        NSFontManager *fontManager = [NSFontManager sharedFontManager];
        NSFont *newFont = [fontManager fontWithFamily:[font familyName]
                                               traits:[[font fontDescriptor] symbolicTraits] | [cstring(*fontWeight) isEqualToString:@"bold"] ? NSBoldFontMask : NSUnboldFontMask
                                               weight:0
                                                 size:[font pointSize]];
        
        if (newFont) {
            font = newFont;
            [editor setFont:font];
        }
    } else if ([type isEqualToString:@"font-style"]) {
        v8::String::Utf8Value fontStyle(value);
        NSFontManager *fontManager = [NSFontManager sharedFontManager];
        NSFont *newFont = [fontManager fontWithFamily:[font familyName]
                                               traits:[[font fontDescriptor] symbolicTraits] | ([cstring(*fontStyle) isEqualToString:@"italic"] ? NSItalicFontMask : NSUnitalicFontMask)
                                               weight:0
                                                 size:[font pointSize]];
        
        if (newFont) {
            font = newFont;
            [editor setFont:font];
        }
    } else if ([type isEqualToString:@"padding-horizontal"]) {
        NSSize size = [editor textContainerInset];
        size.width = value->IntegerValue();
        [editor setTextContainerInset:size];
    } else if ([type isEqualToString:@"padding-vertical"]) {
        NSSize size = [editor textContainerInset];
        size.height = value->IntegerValue();
        [editor setTextContainerInset:size];
    } else if ([type isEqualToString:@"line-height"]) {
        NSDictionary *attributes = [[editor typingAttributes] mutableCopy];
        NSMutableParagraphStyle *paragraphStyle;
        
        if ([editor defaultParagraphStyle]) {
            paragraphStyle = [[editor defaultParagraphStyle] mutableCopy];
        } else {
            paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
        }
        
        [paragraphStyle setMaximumLineHeight:value->NumberValue()];
        [paragraphStyle setMinimumLineHeight:value->NumberValue()];
        [attributes setValue:paragraphStyle forKey:NSParagraphStyleAttributeName];
        [editor setTypingAttributes:attributes];
        [editor setDefaultParagraphStyle:paragraphStyle];
    } else if ([type isEqualToString:@"cursor-width"]) {
        [editor setInsertionPointWidth:value->NumberValue()];
    } else if ([type isEqualToString:@"cursor-color"]) {
        v8::String::Utf8Value color(value);
        [editor setInsertionPointColor:[self colorWithString:cstring(*color)]];
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
