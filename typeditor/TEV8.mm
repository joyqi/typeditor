//
//  TEV8.m
//  typeditor
//
//  Created by 宁 祁 on 12-2-25.
//  Copyright (c) 2012年 MagnetJoy. All rights reserved.
//

#import "TEV8.h"

@interface TEV8 (Private)
- (BOOL) loadScript:(NSString *) file;
- (NSUInteger) createConstants:(const v8::Local<v8::Object> &)proto;
- (void) setUpStyles:(const v8::Local<v8::Object> &)proto withLength:(NSUInteger)length;
@end

// register lexer function
v8::Handle<v8::Value> TEV8Lexer(const v8::Arguments &args)
{
    TEV8GetController(textViewController, context);
    v8::Local<v8::String> key = v8::String::New("lexerCallback");
    
    if (args.Length() >= 1 || args[0]->IsFunction()) {
        context->Global()->SetHiddenValue(key, args[0]);
    }
    
    return v8::Undefined();
}

v8::Handle<v8::Value> TEV8Log(const v8::Arguments &args)
{
    v8::HandleScope handle_scope;
    
    if (1 <= args.Length()) {
        v8::Handle<v8::Value> arg = args[0];
        v8::String::Utf8Value value(arg);
        
        NSLog(@"%s",(const char *) *value);
    }
    
    return v8::Undefined();
}

@implementation TEV8

@synthesize textViewController;

- (void) setController:(TETextViewController *)controller
{
    if (self) {
        
        textViewController = controller;
        
        // init v8
        v8::HandleScope handle_scope;
        v8::Handle<v8::ObjectTemplate> global = v8::ObjectTemplate::New();
        context = v8::Context::New(NULL, global);
        
        if (context.IsEmpty()) {
            return;
        }
        
        v8::Context::Scope context_scope(context);
        
        // init a editor object
        v8::Handle<v8::FunctionTemplate> templ = v8::FunctionTemplate::New();
        v8::Local<v8::ObjectTemplate> objInst = templ->InstanceTemplate();
        objInst->SetInternalFieldCount(1);
        
        v8::Local<v8::Template> proto_t = templ->PrototypeTemplate();
        proto_t->Set("lexer", v8::FunctionTemplate::New(TEV8Lexer));
        proto_t->Set("log", v8::FunctionTemplate::New(TEV8Log));
        
        v8::Handle<v8::Function> ctor = templ->GetFunction();
        v8::Handle<v8::Object> obj = ctor->NewInstance();
        obj->SetInternalField(0, v8::External::New((__bridge void *)textViewController));
        NSUInteger count = [self createConstants:context->Global()];
        context->Global()->Set(v8::String::New("$"), obj);
        
        [self loadScript:[[NSBundle mainBundle] pathForResource:@"init" ofType:@"js"]];
        [self setUpStyles:context->Global() withLength:count];
    }
}

- (void) textChangeCallback:(NSString *)string
{
    v8::HandleScope handle_scope;
    v8::Local<v8::Value> callback = context->Global()->GetHiddenValue(v8::String::New("lexerCallback"));
    
    if (!callback->IsUndefined() && callback->IsFunction()) {
        v8::Local<v8::Function> func = v8::Local<v8::Function>::Cast(callback);
        v8::Local<v8::Value> argv[1];
        argv[0] = v8::String::New([string cStringUsingEncoding:NSUTF8StringEncoding]);
        
        v8::Local<v8::Value> value = func->Call(context->Global(), 1, argv);
        
        // fecth result value
        if (!value->IsUndefined() && value->IsArray()) {
            v8::Local<v8::Array> array = v8::Local<v8::Array>::Cast(value);
            NSUInteger length = array->Length() / 3, pos;
            TETextView *textView = [textViewController textView];
            
            for (pos = 0; pos < length; pos ++) {
                [textView setGlyphRange:TEMakeGlyphRange(array->Get(pos * 3)->IntegerValue(),
                                                         array->Get(pos * 3 + 1)->IntegerValue(),
                                                         array->Get(pos * 3 + 2)->IntegerValue()) 
                              withIndex:pos];
            }
            
            [textView setGlyphRangesNum:length];
        }
    }
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
        v8::String::Utf8Value errorString(try_catch.Exception());
        NSLog(@"Error with(%d:%d): %@", 
              try_catch.Message()->GetLineNumber(),
              try_catch.Message()->GetStartColumn(),
              TEMakeString(*errorString));
        return FALSE;
    }
    
    v8::Handle<v8::Value> result = script->Run();
    
    if (result.IsEmpty()) {
        v8::String::Utf8Value errorString(try_catch.Exception());
        NSLog(@"Error with(%d:%d): %@", 
              try_catch.Message()->GetLineNumber(),
              try_catch.Message()->GetStartColumn(),
              TEMakeString(*errorString));
    }
    
    return TRUE;
}

- (NSUInteger) createConstants:(const v8::Local<v8::Object> &)proto
{
    TEGetGlyphStyleNames(names);
    char *result, constants[1024], *q = constants, prefix[32] = "$";
    v8::Handle<v8::ObjectTemplate> stylesTemplate = v8::ObjectTemplate::New();
    v8::Local<v8::Object> styles = stylesTemplate->NewInstance();
    NSUInteger pos = 0;
    
    strcpy(constants, names);
    while ((result = strsep(&q, " ")) != NULL) {
        // define constants
        proto->Set(v8::String::New(strcat(prefix, result)), v8::Integer::New(pos));
        memset(prefix + 1, 0, 31);
        
        // define default styles
        v8::Handle<v8::ObjectTemplate> styleTemplate = v8::ObjectTemplate::New();
        v8::Local<v8::Object> style = styleTemplate->NewInstance();
        styles->Set(v8::Integer::New(pos), style);
        
        pos ++;
    }
    
    proto->Set(v8::String::New("styles"), styles);
    return pos;
}

- (void) setUpStyles:(const v8::Local<v8::Object> &)proto withLength:(NSUInteger)length
{
    v8::Local<v8::Value> styles = proto->Get(v8::String::New("styles"));
    
    if (!*styles || styles->IsUndefined() || !styles->IsObject()) {
        return;
    }
    
    v8::Local<v8::Object> stylesObject = styles->ToObject();
    
    // 设置编辑器
    TETextView *textView = [textViewController textView];
    
    // 默认字体
    NSFont *defaultFont = TEMakeTextViewFont(NULL, 
                                             TEV8StringValue(stylesObject->Get(v8::String::New("font"))), 
                                             TEV8FloatVaule(stylesObject->Get(v8::String::New("size"))), 
                                             TEV8BooleanValue(stylesObject->Get(v8::String::New("bold"))), 
                                             TEV8BooleanValue(stylesObject->Get(v8::String::New("italic"))));
    [textView setFont:defaultFont];
    
    // 默认字体颜色
    NSColor *defaultColor = TEV8ColorValue(stylesObject->Get(v8::String::New("color")), [NSColor textColor]);
    [textView setColor:defaultColor];
    
    // 默认背景颜色
    NSColor *defaultBackgroundColor = TEV8ColorValue(stylesObject->Get(v8::String::New("background")), [NSColor textBackgroundColor]);
    [textView setBackgroundColor:defaultBackgroundColor];
    
    // 设置所有style的颜色
    for (NSUInteger i = 0; i < length; i ++) {
        v8::Local<v8::Object> style = v8::Local<v8::Object>::Cast(stylesObject->Get(v8::Integer::New(i)));
        
        [textView defineGlyphStyle:TEMakeGlyphStyle(i, 
                                                    TEMakeTextViewFont(defaultFont, 
                                                                       TEV8StringValue(style->Get(v8::String::New("font"))), 
                                                                       TEV8FloatVaule(style->Get(v8::String::New("size"))), 
                                                                       TEV8BooleanValue(style->Get(v8::String::New("bold"))), 
                                                                       TEV8BooleanValue(style->Get(v8::String::New("italic")))), 
                                                    TEV8ColorValue(style->Get(v8::String::New("color")), defaultColor), 
                                                    TEV8ColorValue(style->Get(v8::String::New("background")), defaultBackgroundColor)) withType:i];
    }
}

@end
