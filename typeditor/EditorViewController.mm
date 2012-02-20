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

@synthesize window, scroll, editor, holdReplacement, editing, v8;

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
        
        editor = [[NSTextView alloc] initWithFrame:[[window contentView] frame]];
        [editor setMinSize:NSMakeSize(0.0, contentSize.height)];
        [editor setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];
        [editor setVerticallyResizable:YES];
        [editor setHorizontallyResizable:NO];
        [editor setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        
        [[editor textContainer] setContainerSize:NSMakeSize(contentSize.width, FLT_MAX)];
        [[editor textContainer] setWidthTracksTextView:YES];
        
        [scroll setDocumentView:editor];
        [window setContentView:scroll];
        [window makeKeyAndOrderFront:nil];
        [window makeFirstResponder:editor];
        
        v8 = [[V8Cocoa alloc] init];
        [v8 embed:self];
        
        // set delegate
        [editor setDelegate:self];
        [[editor textStorage] setDelegate:self];
        textStorage = [editor textStorage];
        
        // init var
        editing = NO;
        holdReplacement = [NSMutableArray array];
        
        // default font
        font = [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica" traits:0 weight:0 size:12.0f];
        // font = [NSFont fontWithName:@"Helvetica" size:12.0f];
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
    
    
    v8::HandleScope handle_scope;
    v8::Persistent<v8::Context> context = [self v8]->context;
    v8::Context::Scope context_scope(context);
    
    v8::Local<v8::Value> callback = context->Global()->GetHiddenValue(v8::String::New("callback"));
    
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

- (void)setTextStyle:(int)location withLength:(int)length forType:(NSString *)type withValue:(id)value
{
    NSRange found = NSMakeRange(location, length);
    
    if ([type isEqualToString:@"color"]) {
        [textStorage addAttribute:NSForegroundColorAttributeName value:[self colorWithString:(NSString *)value] range:found];
    } else if ([type isEqualToString:@"background-color"]) {
        [textStorage addAttribute:NSBackgroundColorAttributeName value:[self colorWithString:(NSString *)value] range:found];
    } else if ([type isEqualToString:@"underline"]) {
        [textStorage addAttribute:NSUnderlineStyleAttributeName value:value range:found];
    } else if ([type isEqualToString:@"underline-color"]) {
        [textStorage addAttribute:NSUnderlineColorAttributeName value:[self colorWithString:(NSString *)value] range:found];
    } else if ([type isEqualToString:@"font-family"]) {
        font(currentFont);
        NSFontManager *fontManager = [NSFontManager sharedFontManager];
        NSFont *newFont = [fontManager fontWithFamily:value
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
                                                 size:[(NSNumber *)value floatValue]];

        if (newFont) {
            [textStorage addAttribute:NSFontAttributeName value:newFont range:found];
        }
    } else if ([type isEqualToString:@"font-weight"]) {
        font(currentFont);
        NSFontManager *fontManager = [NSFontManager sharedFontManager];
        NSFont *newFont = [fontManager fontWithFamily:[currentFont familyName]
                                               traits:[[currentFont fontDescriptor] symbolicTraits] | [(NSString *)value isEqualToString:@"bold"] ? NSBoldFontMask : NSUnboldFontMask
                                               weight:0
                                                 size:[currentFont pointSize]];
        
        if (newFont) {
            [textStorage addAttribute:NSFontAttributeName value:newFont range:found];
        }
    } else if ([type isEqualToString:@"font-style"]) {
        font(currentFont);
        NSFontManager *fontManager = [NSFontManager sharedFontManager];
        NSFont *newFont = [fontManager fontWithFamily:[currentFont familyName]
                                               traits:[[currentFont fontDescriptor] symbolicTraits] | ([(NSString *)value isEqualToString:@"italic"] ? NSItalicFontMask : NSUnitalicFontMask)
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

- (void)setDefaultFont:(NSString *)fontName size:(CGFloat)fontSize
{
    font = [NSFont fontWithName:fontName size:fontSize];
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
