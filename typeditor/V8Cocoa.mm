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
#import "EditorTextView.h"

@interface V8Cocoa (Private)
- (BOOL) createContext:(id)editor;
- (BOOL) loadScript:(NSString *) file;
@end

# pragma Mark - v8 methods

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
    importEditor(editor, context);
    v8::Local<v8::String> key = v8::String::New("lexerCallback");
    
    if (args.Length() >= 1 || args[0]->IsFunction()) {
        if (!*(context->Global()->GetHiddenValue(key)) || context->Global()->GetHiddenValue(key)->IsNull()) {
            context->Global()->SetHiddenValue(key, v8::Array::New());
        }
        
        v8::Local<v8::Array> callback = v8::Local<v8::Array>::Cast(context->Global()->GetHiddenValue(key));
        callback->Set(callback->Length(), args[0]);
    }
    
    return v8::Undefined();
}

// register enter function
v8::Handle<v8::Value> onEnter(const v8::Arguments &args)
{
    importEditor(editor, context);
    v8::Local<v8::String> key = v8::String::New("enterCallback");
    
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
    importEditor(editor, context);
    
    if (4 <= args.Length() &&
        args[0]->IsNumber() &&
        args[1]->IsNumber() &&
        args[2]->IsString() &&
        !args[3]->IsNull()) {
        
        v8::Handle<v8::Value> arg = args[2];
        v8::String::Utf8Value type(arg);
        
        [(EditorTextView *)[editor editor] setTextStyle:args[0]->IntegerValue() withLength:args[1]->IntegerValue() forType:cstring(*type) withValue:args[3]];
    }
    
    return v8::Undefined();
}

// set default style
v8::Handle<v8::Value> editorStyle(const v8::Arguments &args)
{
    importEditor(editor, context);
    
    if (2 <= args.Length() &&
        args[0]->IsString() &&
        !args[1]->IsNull()) {
        
        v8::Handle<v8::Value> arg = args[0];
        v8::String::Utf8Value type(arg);
        
        [(EditorTextView *)[editor editor] setEditorStyle:cstring(*type) withValue:args[1]];
    }
    
    return v8::Undefined();
}

// get text
v8::Handle<v8::Value> text(const v8::Arguments &args)
{
    importEditor(editor, context);
    return v8::String::New([[[editor editor] string] cStringUsingEncoding:NSUTF8StringEncoding]);
}

// set style
v8::Handle<v8::Value> replace(const v8::Arguments &args)
{
    importEditor(editor, context);
    
    if (3 <= args.Length()) {
        v8::Handle<v8::Value> arg = args[2];
        v8::String::Utf8Value value(arg);

        [editor setText:args[0]->IntegerValue() withLength:args[1]->IntegerValue() replacementString:cstring(*value)];
    }
    
    return v8::Undefined();
}

// insert string
v8::Handle<v8::Value> insert(const v8::Arguments &args)
{
    importEditor(editor, context);
    
    if (2 <= args.Length()) {
        v8::Handle<v8::Value> arg = args[1];
        v8::String::Utf8Value value(arg);
        
        [editor setText:args[0]->IntegerValue() withLength:0 replacementString:cstring(*value)];
    }
    
    return v8::Undefined();
}

// remove string
v8::Handle<v8::Value> remove(const v8::Arguments &args)
{
    importEditor(editor, context);
    
    if (2 <= args.Length()) {
        [editor setText:args[0]->IntegerValue() withLength:args[1]->IntegerValue() replacementString:@""];
    }
    
    return v8::Undefined();
}

// get selected range
v8::Handle<v8::Value> selectedRange(const v8::Arguments &args)
{
    importEditor(editor, context);
    
    NSRange range = [[editor editor] selectedRange];
    v8::Local<v8::ObjectTemplate> resultTemplate = v8::ObjectTemplate::New();
    v8::Local<v8::Object> result = resultTemplate->NewInstance();
    
    result->Set(v8::String::New("location"), v8::Integer::New(range.location));
    result->Set(v8::String::New("length"), v8::Integer::New(range.length));
    
    return result;
}

// get current position
v8::Handle<v8::Value> currentPosition(const v8::Arguments &args)
{
    importEditor(editor, context);
    NSRange range = [[editor editor] selectedRange];
    
    return v8::Integer::New(range.location);
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
    proto_t->Set("log", v8::FunctionTemplate::New(log));
    proto_t->Set("lexer", v8::FunctionTemplate::New(lexer));
    proto_t->Set("onEnter", v8::FunctionTemplate::New(onEnter));
    proto_t->Set("style", v8::FunctionTemplate::New(style));
    proto_t->Set("editorStyle", v8::FunctionTemplate::New(editorStyle));
    proto_t->Set("text", v8::FunctionTemplate::New(text));
    proto_t->Set("replace", v8::FunctionTemplate::New(replace));
    proto_t->Set("insert", v8::FunctionTemplate::New(insert));
    proto_t->Set("remove", v8::FunctionTemplate::New(remove));
    proto_t->Set("selectedRange", v8::FunctionTemplate::New(selectedRange));
    proto_t->Set("currentPosition", v8::FunctionTemplate::New(currentPosition));
    
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
            cstring(*error));
        return FALSE;
    }
    
    v8::Handle<v8::Value> result = script->Run();
    
    if (result.IsEmpty()) {
        v8::String::Utf8Value error(try_catch.Exception());
        NSLog(@"Error with(%d:%d): %@", 
              try_catch.Message()->GetLineNumber(),
              try_catch.Message()->GetStartColumn(),
              cstring(*error));
        return FALSE;
    }
    
    return TRUE;
}

@end
