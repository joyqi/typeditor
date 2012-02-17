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
@end

static V8Cocoa *sharedV8 = NULL;

v8::Handle<v8::Value> setProperty(const v8::Arguments& args)
{
    v8::HandleScope handle_scope;
    
    if (2 == args.Length()) {
        [[V8Cocoa scintillaView] setGeneralProperty:args[0]->IntegerValue() value:args[1]->NumberValue()];
    } else if (3 == args.Length()) {
        [[V8Cocoa scintillaView] setGeneralProperty:args[0]->IntegerValue() parameter:args[1]->NumberValue() value:args[2]->NumberValue()];
    }
    
    return v8::Undefined();
}

v8::Handle<v8::Value> log(const v8::Arguments& args)
{
    v8::HandleScope handle_scope;
    
    NSLog(@"TEST TEST");
    
    return v8::Undefined();
}

@implementation V8Cocoa

- (id)init
{    
    if (!sharedV8) {
        sharedV8 = [super init];
    }
    
    return sharedV8;
}

+ (V8Cocoa *)shared
{
    if (!sharedV8) {
        sharedV8 = [[V8Cocoa alloc] init];
    }
    
    return sharedV8;
}

+ (ScintillaView *)scintillaView
{
    return [V8Cocoa shared]->scintillaView;
}

- (void)embedScintilla:(ScintillaView *) senderScintillaView
{
    v8::TryCatch try_catch;
    
    scintillaView = senderScintillaView;

    // init v8
    v8::HandleScope handle_scope;
    v8::Persistent<v8::Context> context = [self createContext];
    v8::Context::Scope context_scope(context);
    
    if (context.IsEmpty()) {
        NSLog(@"Error creating context");
        return;
    }
    
    NSString *file = [[NSBundle mainBundle] pathForResource:@"init" ofType:@"js"];
    NSString *string = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    
    v8::Handle<v8::Script> script = v8::Script::Compile(v8::String::New([string cStringUsingEncoding:NSUTF8StringEncoding]),
        v8::String::New([file cStringUsingEncoding:NSUTF8StringEncoding]));
    
    if (script.IsEmpty()) {
        NSLog(@"File not found: %@", file);
        return;
    }
    
    v8::Handle<v8::Value> result = script->Run();
    if (result.IsEmpty()) {
        v8::String::Utf8Value error(try_catch.Exception());
        NSLog(@"Error with: %@", [[NSString alloc] initWithCString:*error encoding:NSUTF8StringEncoding]);
    }
    
    context.Dispose();
}

- (v8::Persistent<v8::Context>) createContext
{
    v8::Handle<v8::ObjectTemplate> global = v8::ObjectTemplate::New();
    global->Set(v8::String::New("setProperty"), v8::FunctionTemplate::New(setProperty));
    global->Set(v8::String::New("log"), v8::FunctionTemplate::New(log));
    return v8::Context::New(NULL, global);
}

@end
