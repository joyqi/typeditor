//
//  V8Cocoa.m
//  typeditor
//
//  Created by  on 12-2-17.
//  Copyright (c) 2012年 MagnetJoy. All rights reserved.
//

#import "V8Cocoa.h"
#import "v8.h"
#import "EditorViewController.h"

@interface V8Cocoa (Private)
- (BOOL) createContext:(id)editor;
- (BOOL) loadScript:(NSString *) file;
@end

v8::Handle<v8::Value> logTest (const v8::Arguments &args) {
    NSLog(@"%d", args.Length());
    return v8::Undefined();
}

# pragma Mark - v8 methods
/*
v8::Handle<v8::Value> setGeneralProperty(const v8::Arguments &args)
{
    v8::HandleScope handle_scope;
    editor(editor);
    
    if (2 == args.Length()) {
        [editor setGeneralProperty:args[0]->IntegerValue() value:args[1]->NumberValue()];
    } else if (3 == args.Length()) {
        NSLog(@"%lld,%lld,%lld", args[0]->IntegerValue(), args[1]->IntegerValue(), args[2]->IntegerValue());
        [editor setGeneralProperty:args[0]->IntegerValue() parameter:args[1]->NumberValue() value:args[2]->NumberValue()];
    }
    
    return v8::Undefined();
}

v8::Handle<v8::Value> getGeneralProperty(const v8::Arguments &args)
{
    v8::HandleScope handle_scope;
    editor(editor);
    
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

v8::Handle<v8::Value> getLexerProperty(const v8::Arguments &args)
{
    v8::HandleScope handle_scope;
    editor(editor);
    
    if (1 <= args.Length()) {
        v8::Handle<v8::Value> arg = args[0];
        v8::String::Utf8Value value(arg);
        
        NSString * result = [editor getLexerProperty:[[NSString alloc] 
                                                      initWithCString:(const char *) *value encoding:NSUTF8StringEncoding]];
        
        return v8::String::New([result cStringUsingEncoding:NSUTF8StringEncoding]);
    }
    
    return v8::Undefined();
}
*/

v8::Handle<v8::Value> log(const v8::Arguments &args)
{
    v8::HandleScope handle_scope;
    
    if (1 <= args.Length()) {
        v8::Handle<v8::Value> arg = args[0];
        v8::String::Utf8Value value(arg);
        
        NSLog(@"%s",(const char *) *value);
    }
    
    return v8::Undefined();
}

// register lexer function
v8::Handle<v8::Value> lexer(const v8::Arguments &args)
{
    editor(editor, context);
    v8::Local<v8::String> key = v8::String::New("callback");
    
    if (args.Length() >= 1 || args[0]->IsFunction()) {
        if (!*(context->Global()->GetHiddenValue(key)) || context->Global()->GetHiddenValue(key)->IsNull()) {
            context->Global()->SetHiddenValue(key, v8::Array::New());
        }
        
        v8::Local<v8::Array> callback = v8::Local<v8::Array>::Cast(context->Global()->GetHiddenValue(key));
        callback->Set(callback->Length(), args[0]);
    }
    
    return v8::Undefined();
}

// set style
v8::Handle<v8::Value> style(const v8::Arguments &args)
{
    editor(editor, context);
    
    if (2 <= args.Length()) {
        [editor setTextStyle:args[0]->IntegerValue() withLength:args[1]->IntegerValue()];
    }
    
    return v8::Undefined();
}

@implementation V8Cocoa

- (void)dealloc
{
    // [super dealloc];
    context.Dispose();
}

- (BOOL)embed:(id)editor
{    
    if (self) {
        // init v8
        v8::HandleScope handle_scope;
        
        if (![self createContext:editor]) {
            NSLog(@"Error creating context");
            return FALSE;
        }
        
        v8::Context::Scope context_scope(context);
        
        if (![self loadScript:[[NSBundle mainBundle] pathForResource:@"init" ofType:@"js"]]) {
            NSLog(@"Error load init.js");
            return FALSE;
        }
        
        return TRUE;
    }
    
    return FALSE;
}

- (BOOL) createContext:(id)editor
{
    v8::HandleScope handle_scope;
    v8::Handle<v8::ObjectTemplate> global = v8::ObjectTemplate::New();
    context = v8::Context::New(NULL, global);
    
    if (context.IsEmpty()) {
        return FALSE;
    }
    
    v8::Context::Scope context_scope(context);
    
    // init a editor object
    v8::Handle<v8::FunctionTemplate> templ = v8::FunctionTemplate::New();
    v8::Local<v8::ObjectTemplate> objInst = templ->InstanceTemplate();
    objInst->SetInternalFieldCount(1);
    
    v8::Local<v8::Template> proto_t = templ->PrototypeTemplate();
    /*
    proto_t->Set("setGeneralProperty",  v8::FunctionTemplate::New(setGeneralProperty));
    proto_t->Set("getGeneralProperty", v8::FunctionTemplate::New(getGeneralProperty));
    proto_t->Set("getLexerProperty", v8::FunctionTemplate::New(getLexerProperty));
     */
    proto_t->Set("log", v8::FunctionTemplate::New(log));
    proto_t->Set("lexer", v8::FunctionTemplate::New(lexer));
    proto_t->Set("style", v8::FunctionTemplate::New(style));
    
    // v8::Handle<v8::Function> ctor = templ->GetFunction();
    v8::Handle<v8::Function> ctor = templ->GetFunction();
    v8::Handle<v8::Object> obj = ctor->NewInstance();
    obj->SetInternalField(0, v8::External::New((__bridge void *)editor));
    context->Global()->Set(v8::String::New("$"), obj);
    
    return TRUE;
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

@end
