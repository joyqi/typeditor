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
@end

@implementation EditorViewController

@synthesize window, scroll, editor, holdReplacement, editing, lineNumber, v8;

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
        [editor setEditorViewController:self];
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
        
        [scroll setDocumentView:editor];
        [window setContentView:scroll];
        [window makeKeyAndOrderFront:nil];
        [window makeFirstResponder:editor];
        
        lineNumber = [[EditorLineNumberView alloc] initWithScrollView:scroll];
        [scroll setVerticalRulerView:lineNumber];
        
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
    
    // make a font copy
    [textStorage removeAttribute:NSForegroundColorAttributeName range:range];
    [textStorage addAttribute:NSForegroundColorAttributeName value:[editor defaultColor] range:range];
    [textStorage removeAttribute:NSBackgroundColorAttributeName range:range];
    [textStorage removeAttribute:NSUnderlineStyleAttributeName range:range];
    [textStorage removeAttribute:NSUnderlineColorAttributeName range:range];
    [textStorage removeAttribute:NSFontAttributeName range:range];
    [textStorage addAttribute:NSFontAttributeName value:[editor defaultFont] range:range];
    [textStorage fixAttributesInRange:range];

    
    v8::HandleScope handle_scope;
    v8::Persistent<v8::Context> context = v8->context;
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
        [editor didChangeText];
    }
    
    [holdReplacement removeAllObjects];
}

- (void)insertText:(id)insertString
{
    // run layout callback
    
    // run insert callback
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

- (BOOL)textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector
{    
    return NO;
}

- (void)setText:(int)location withLength:(int)length replacementString:(NSString *)string
{
    NSRange area = NSMakeRange(location, length);
    // NSRange append = NSMakeRange(location, 0);
    
    // if is not edting
    if (!editing) {
        [textStorage beginEditing];
        [textStorage replaceCharactersInRange:area withString:string];
        [textStorage endEditing];
        [editor didChangeText];
    } else {
        // add to hold replacement
        EditorViewReplacement *replacement = [[EditorViewReplacement alloc] init:area replacementString:string];
        [holdReplacement addObject:replacement];
        replacement = nil;
    }
}

@end
