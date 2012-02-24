//
//  EditorViewController.m
//  typeditor
//
//  Created by  on 12-2-20.
//  Copyright (c) 2012年 MagnetJoy. All rights reserved.
//

#import "EditorViewController.h"

@interface EditorViewController (Private)
@end

@implementation EditorViewController

@synthesize window, scroll, editor, lineNumber, v8;

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
    }
    
    return self;
}

- (void)textStorageDidProcessEditing:(NSNotification *)notification
{
    // is editing
}

- (void)textDidChange:(NSNotification*)notification
{
    // did change
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

@end
