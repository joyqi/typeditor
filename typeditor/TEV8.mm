//
//  TEV8.m
//  typeditor
//
//  Created by 宁 祁 on 12-2-25.
//  Copyright (c) 2012年 MagnetJoy. All rights reserved.
//

#import "TEV8.h"
#import "TETextView.h"

@interface TEV8 (Private)
- (BOOL) loadScript:(NSString *) file;
- (NSUInteger) createConstants:(const v8::Local<v8::Object> &)proto;
- (void) setUpTextView:(TETextView *)textView withObject:(const v8::Local<v8::Object> &)proto withLength:(NSUInteger)length;
@end

@implementation TEV8

- (id) initWithTextView:(TETextView *)textView
{
    self = [super init];
    
    if (self) {
        
        // init v8
        v8::HandleScope handle_scope;
        v8::Handle<v8::ObjectTemplate> global = v8::ObjectTemplate::New();
        context = v8::Context::New(NULL, global);
        
        if (context.IsEmpty()) {
            return self;
        }
        
        v8::Context::Scope context_scope(context);
        
        // init a editor object
        v8::Handle<v8::FunctionTemplate> templ = v8::FunctionTemplate::New();
        v8::Local<v8::ObjectTemplate> objInst = templ->InstanceTemplate();
        objInst->SetInternalFieldCount(1);
        
        v8::Local<v8::Template> proto_t = templ->PrototypeTemplate();
        
        v8::Handle<v8::Function> ctor = templ->GetFunction();
        v8::Handle<v8::Object> obj = ctor->NewInstance();
        obj->SetInternalField(0, v8::External::New((__bridge void *)textView));
        context->Global()->Set(v8::String::New("$"), obj);
        
        NSUInteger count = [self createConstants:context->Global()];
        [self loadScript:[[NSBundle mainBundle] pathForResource:@"init" ofType:@"js"]];
        [self setUpTextView:textView withObject:context->Global() withLength:count];
    }
    
    return self;
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
              TEMakeString(*error));
        return FALSE;
    }
    
    v8::Handle<v8::Value> result = script->Run();
    
    if (result.IsEmpty()) {
        v8::String::Utf8Value error(try_catch.Exception());
        NSLog(@"Error with(%d:%d): %@", 
              try_catch.Message()->GetLineNumber(),
              try_catch.Message()->GetStartColumn(),
              TEMakeString(*error));
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

- (void) setUpTextView:(TETextView *)textView withObject:(const v8::Local<v8::Object> &)proto withLength:(NSUInteger)length
{
    // 默认字体
    NSFont *defaultFont = TEMakeTextViewFont(NULL, 
                                             TEV8StringValue(proto->Get(v8::String::New("font"))), 
                                             TEV8FloatVaule(proto->Get(v8::String::New("size"))), 
                                             TEV8BooleanValue(proto->Get(v8::String::New("bold"))), 
                                             TEV8BooleanValue(proto->Get(v8::String::New("italic"))));
    
    // 默认字体颜色
    NSColor *defaultColor = TEV8ColorValue(proto->Get(v8::String::New("color")), [NSColor textColor]);
    
    // 默认背景颜色
    NSColor *defaultBackgroundColor = TEV8ColorValue(proto->Get(v8::String::New("background")), [NSColor textBackgroundColor]);
    
    // 设置所有style的颜色
    for (NSUInteger i = 0; i < length; i ++) {
        v8::Local<v8::Object> style = v8::Local<v8::Object>::Cast(proto->Get(v8::Integer::New(i)));
        
        [textView defineGlyphStyle:TEMakeGlyphStyle(i, 
                                                    TEMakeTextViewFont(defaultFont, 
                                                                       TEV8StringValue(style->Get(v8::String::New("font"))), 
                                                                       TEV8FloatVaule(style->Get(v8::String::New("font"))), 
                                                                       TEV8BooleanValue(style->Get(v8::String::New("bold"))), 
                                                                       TEV8BooleanValue(style->Get(v8::String::New("italic")))), 
                                                    TEV8ColorValue(style->Get(v8::String::New("color")), defaultColor), 
                                                    TEV8ColorValue(style->Get(v8::String::New("background")), defaultBackgroundColor)) withType:i];
    }
}

@end
