//
//  EditorViewController.m
//  typeditor
//
//  Created by  on 12-2-20.
//  Copyright (c) 2012年 MagnetJoy. All rights reserved.
//

#import "EditorViewController.h"

@implementation EditorViewController

@synthesize window, scroll, editor, v8;

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
        
        [[editor textStorage] setDelegate:self];
        textStorage = [editor textStorage];
    }
    
    return self;
}

- (void)textStorageDidProcessEditing:(NSNotification *)notification
{
    // clear all style
    // textStorage = [notification object];
    NSString *string = [textStorage string];
    [textStorage removeAttribute:NSForegroundColorAttributeName range:NSMakeRange(0, [string length])];
    
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

- (void)setTextStyle:(int)location withLength:(int)length
{
    NSColor *blue = [NSColor blueColor];
    NSRange found = NSMakeRange(location, length);
    
    [textStorage addAttribute:NSForegroundColorAttributeName value:blue range:found];
}

- (void)setText:(int)location withLength:(int)length replacementString:(NSString *)string
{
    NSRange found = NSMakeRange(0, 1);
    NSLog(@"%d, %d", location, length);
    
    //[textStorage edited:NSTextStorageEditedCharacters range:found changeInLength:3];
    
    // check changeable
    //if ([editor shouldChangeTextInRange:found replacementString:string]) {
        //[textStorage beginEditing];
        [textStorage replaceCharactersInRange:found withString:@"bbb"];
        //[textStorage edited:<#(NSUInteger)#> range:<#(NSRange)#> changeInLength:<#(NSInteger)#>
        // [textStorage removeAttribute:<#(NSString *)#> range:<#(NSRange)#>]
        //[textStorage endEditing];
    //}
}

@end
