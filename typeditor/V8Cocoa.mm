//
//  V8Cocoa.m
//  typeditor
//
//  Created by  on 12-2-17.
//  Copyright (c) 2012年 MagnetJoy. All rights reserved.
//

#import "V8Cocoa.h"
#import "v8.h"

@interface V8Cocoa (Private)
- (v8::Persistent<v8::Context>) createContext;
- (BOOL) loadScript:(NSString *) file;
@end

@implementation V8Cocoa

- (void)dealloc
{
    // [super dealloc];
    scintillaView = nil;
    context.Dispose();
}

- (ScintillaView *)scintillaView
{
    return scintillaView;
}

- (BOOL)embedScintilla:(ScintillaView *) senderScintillaView
{
    scintillaView = senderScintillaView;

    // init v8
    v8::HandleScope handle_scope;
    context = [self createContext];
    v8::Context::Scope context_scope(context);
    
    if (context.IsEmpty()) {
        NSLog(@"Error creating context");
        return FALSE;
    }
    
    if (![self loadScript:[[NSBundle mainBundle] pathForResource:@"init" ofType:@"js"]]) {
        NSLog(@"Error load init.js");
        return FALSE;
    }
    
    return TRUE;
}

- (v8::Persistent<v8::Context>) createContext
{
    v8method(setGeneralProperty);
    v8method(getGeneralProperty);
    v8method(getLexerProperty);
    v8method(log);
    
    
    v8::Handle<v8::ObjectTemplate> global = v8::ObjectTemplate::New();
    global->Set(v8::String::New("setGeneralProperty"), v8::FunctionTemplate::New(setGeneralProperty));
    global->Set(v8::String::New("getGeneralProperty"), v8::FunctionTemplate::New(getGeneralProperty));
    global->Set(v8::String::New("getLexerProperty"), v8::FunctionTemplate::New(getLexerProperty));
    global->Set(v8::String::New("log"), v8::FunctionTemplate::New(log));
    return v8::Context::New(NULL, global);
}

- (BOOL) loadScript:(NSString *) file
{
    v8::TryCatch try_catch;
    v8::HandleScope handle_scope;

    NSError *error = nil;
    NSString *string = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:&error];
    
    if (error && [[error domain] isEqual: NSCocoaErrorDomain]) {
        NSLog(@"Open script file with error: %@", error);
        return FALSE;
    }
    
    v8::Handle<v8::Script> script = v8::Script::Compile(v8::String::New([string cStringUsingEncoding:NSUTF8StringEncoding]),
        v8::String::New([file cStringUsingEncoding:NSUTF8StringEncoding]));
    
    if (script.IsEmpty()) {
        v8::String::Utf8Value error(try_catch.Exception());
        NSLog(@"Error with(%d:%d): %@", 
            try_catch.Message()->GetLineNumber(),
            try_catch.Message()->GetStartColumn(),
            [[NSString alloc] initWithCString:*error encoding:NSUTF8StringEncoding]);
        return FALSE;
    }
    
    v8::Handle<v8::Value> result = script->Run();
    
    if (result.IsEmpty()) {
        v8::String::Utf8Value error(try_catch.Exception());
        NSLog(@"Error with(%d:%d): %@", 
              try_catch.Message()->GetLineNumber(),
              try_catch.Message()->GetStartColumn(),
              [[NSString alloc] initWithCString:*error encoding:NSUTF8StringEncoding]);
        return FALSE;
    }
    
    return TRUE;
}

# pragma Mark - v8 methods
- (v8::Handle<v8::Value>) setGeneralProperty:(const v8::Arguments& )args
{
    v8::HandleScope handle_scope;
    ScintillaView *editor = [self scintillaView];
    
    if (2 == args.Length()) {
        [editor setGeneralProperty:args[0]->IntegerValue() value:args[1]->NumberValue()];
    } else if (3 == args.Length()) {
        NSLog(@"%lld,%lld,%lld", args[0]->IntegerValue(), args[1]->IntegerValue(), args[2]->IntegerValue());
        [editor setGeneralProperty:args[0]->IntegerValue() parameter:args[1]->NumberValue() value:args[2]->NumberValue()];
    }
    
    return v8::Undefined();
}

- (v8::Handle<v8::Value>) getGeneralProperty:(const v8::Arguments& )args
{
    v8::HandleScope handle_scope;
    ScintillaView *editor = [self scintillaView];
    
    if (1 == args.Length()) {
        return v8::Number::New([editor getGeneralProperty:args[0]->IntegerValue()]);
    } else if (2 == args.Length()) {
        return v8::Number::New([editor getGeneralProperty:args[0]->IntegerValue() parameter:args[0]->NumberValue()]);
    } else if (3 == args.Length()) {
        return v8::Number::New([editor getGeneralProperty:args[0]->IntegerValue() 
                                                parameter:args[1]->NumberValue() extra:args[2]->NumberValue()]);
    }
    
    return v8::Undefined();
}

- (v8::Handle<v8::Value>) getLexerProperty:(const v8::Arguments& )args
{
    v8::HandleScope handle_scope;
    ScintillaView *editor = [self scintillaView];
    
    if (1 <= args.Length()) {
        v8::Handle<v8::Value> arg = args[0];
        v8::String::Utf8Value value(arg);
        
        NSString * result = [editor getLexerProperty:[[NSString alloc] 
            initWithCString:(const char *) *value encoding:NSUTF8StringEncoding]];
        
        return v8::String::New([result cStringUsingEncoding:NSUTF8StringEncoding]);
    }
    
    return v8::Undefined();
}

- (v8::Handle<v8::Value>) log:(const v8::Arguments& )args
{
    v8::HandleScope handle_scope;
    
    if (1 <= args.Length()) {
        v8::Handle<v8::Value> arg = args[0];
        v8::String::Utf8Value value(arg);
        
        NSLog(@"%s",(const char *) *value);
    }
    
    return v8::Undefined();
}

@end
