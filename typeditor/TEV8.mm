//
//  TEV8.m
//  typeditor
//
//  Created by 宁 祁 on 12-2-25.
//  Copyright (c) 2012年 MagnetJoy. All rights reserved.
//

#import "TEV8.h"

#pragma mark - inline method

// 把value转换成float
CGFloat TEV8FloatVaule(const v8::Local<v8::Value> &value) {
    if (*value && !value->IsUndefined() && value->IsNumber()) {
        return value->NumberValue();
    }
    
    return NSNotFound;
}

NSInteger TEV8BooleanValue(const v8::Local<v8::Value> &value) {
    if (*value && !value->IsUndefined() && value->IsBoolean()) {
        return value->BooleanValue();
    }
    
    return NSNotFound;
}

NSInteger TEV8IntegerValue(const v8::Local<v8::Value> &value) {
    if (*value && !value->IsUndefined() && value->NumberValue()) {
        return value->IntegerValue();
    }
    
    return NSNotFound;
}

NSString *TEV8StringValue(const v8::Local<v8::Value> &value) {
    if (*value && !value->IsUndefined() && value->IsString()) {
        v8::String::Utf8Value string(value->ToString());
        return TEMakeString(*string);
    }
    
    return NULL;
}

NSColor *TEV8ColorValue(const v8::Local<v8::Value> &value, NSColor *color) {
    if (*value && !value->IsUndefined() && value->IsString()) {
        v8::String::Utf8Value string(value->ToString());
        return TEMakeRGBColor(TEMakeString(*string));
    }
    
    return color;
}

NSString *TEV8UUID() {
    CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef strRef = CFUUIDCreateString(kCFAllocatorDefault, uuidRef);
    NSString *uuidString = [NSString stringWithString:(__bridge NSString*)strRef];
    CFRelease(strRef);
    CFRelease(uuidRef);
    
    return uuidString;
}

@interface TEV8 (Private)
- (BOOL)loadScript:(NSString *) file;
- (NSUInteger)createConstants:(const v8::Local<v8::Object> &)proto;
- (void)initLineNumber:(TELineNumberView *)lineNumberView withGlobal:(const v8::Local<v8::Object> &)proto;
- (void)initTextView:(TETextView *)textView withGlobal:(const v8::Local<v8::Object> &)proto withLength:(NSUInteger)length;
@end

// register lexer function
v8::Handle<v8::Value> TEV8Lexer(const v8::Arguments &args)
{
    TEV8Context(context, textViewController);
    
    v8::Local<v8::String> key = v8::String::New("lexers");
    
    if (args.Length() >= 2 && args[0]->IsArray() && args[1]->IsFunction()) {
        v8::Local<v8::Value> lexersValue;
        
        if (!context->Global()->Has(key)) {
            v8::Handle<v8::ObjectTemplate> lexersTemplate = v8::ObjectTemplate::New();
            lexersValue = lexersTemplate->NewInstance();
            context->Global()->SetHiddenValue(key, lexersValue);
        } else {
            lexersValue = context->Global()->GetHiddenValue(key);
        }
        
        v8::Local<v8::Object> lexersObject = lexersValue->ToObject();
        
        // reigister args
        NSString *UUID = TEV8UUID();
        v8::Local<v8::String> funcKey = v8::String::New([UUID UTF8String]);
        lexersObject->Set(funcKey, args[1]);
        
        v8::Local<v8::Array> callbackArray = v8::Local<v8::Array>::Cast(args[0]);
        NSUInteger length = callbackArray->Length(), pos;
        
        for (pos = 0; pos < length; pos ++) {
            NSString *suffix = TEV8StringValue(callbackArray->Get(pos));
            NSMutableArray *callbacks = [[[textViewController v8] lexers] objectForKey:suffix];
            
            if (!callbacks) {
                callbacks = [NSMutableArray array];
                [[[textViewController v8] lexers] setValue:callbacks forKey:suffix];
            }
            
            [callbacks addObject:UUID];
        }
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

@synthesize textViewController, lexers;

- (id)init
{
    self = [super init];
    
    if (self) {
        size_t messageSize = sizeof(TEMessage) * TE_MAX_MESSAGES_BUFFER;
        messages = (TEMessage *)malloc(messageSize);
        memset(messages, 0, messageSize);
        readPos = 0;
        writePos = 0;
        
        lexers = [NSMutableDictionary dictionary];
        suffix = @"*";
    }
    
    return self;
}

- (void)setTextViewController:(TETextViewController *)controller
{
    textViewController = controller;
    
    // init v8
    v8::Isolate* isolate = v8::Isolate::New();
    v8::Isolate::Scope iscope(isolate);
    
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
    objInst->SetInternalFieldCount(2);
    
    v8::Local<v8::Template> proto_t = templ->PrototypeTemplate();
    proto_t->Set("lexer", v8::FunctionTemplate::New(TEV8Lexer));
    proto_t->Set("log", v8::FunctionTemplate::New(TEV8Log));
    
    v8::Handle<v8::Function> ctor = templ->GetFunction();
    v8::Handle<v8::Object> obj = ctor->NewInstance();
    obj->SetInternalField(0, v8::External::New((__bridge void *)textViewController));
    obj->SetInternalField(1, v8::External::New((__bridge void *)self));
    NSUInteger count = [self createConstants:context->Global()];
    context->Global()->Set(v8::String::New("$"), obj);
    
    [self loadScript:[[NSBundle mainBundle] pathForResource:@"init" ofType:@"js"]];
    
    // life cycle
    while (true) {
        if (readPos != writePos) {
            TEMessage *message = &messages[readPos];
            
            do {
                switch (message->type) {
                    case TEMessageTypeInitTextView:
                        [self initTextView:(__bridge TETextView *)message->ptr withGlobal:context->Global() withLength:count];
                        break;
                    case TEMessageTypeInitLineNumber:
                        [self initLineNumber:(__bridge TELineNumberView *)message->ptr withGlobal:context->Global()];
                        break;
                    case TEMessageTypeTextChange:
                        [self textChangeCallback:(__bridge NSString *)message->ptr];
                        break;
                    case TEMessageTypeSuffixChange:
                        suffix = (__bridge NSString *)message->ptr;
                        break;
                    case TEMessageTypeCloseTab:
                        [[textViewController tabStorages] removeObjectForKey:(__bridge NSString *)message->ptr];
                        break;
                    default:
                        break;
                }
                
                message = message->next;
                readPos ++;
                if (readPos >= TE_MAX_MESSAGES_BUFFER) {
                    readPos = 0;
                }
                
            } while (message);
        }
    }
}

- (void)sendMessage:(TEMessageType)msgType withObject:(id)obj
{
    NSUInteger lastPos = writePos - 1, currentPos = writePos;
    if (currentPos >= TE_MAX_MESSAGES_BUFFER) {
        currentPos = 0;
        lastPos = TE_MAX_MESSAGES_BUFFER - 1;
    }
    
    messages[currentPos].type = msgType;
    messages[currentPos].ptr = (__bridge void *)obj;
    messages[currentPos].next = NULL;
    
    if (messages[lastPos].ptr) {
        messages[lastPos].next = &messages[currentPos];
    }
    
    writePos = currentPos + 1;
}

- (void)textChangeCallback:(NSString *)string
{
    v8::HandleScope handle_scope;
    NSArray *callbackKeys = [lexers objectForKey:suffix];
    
    if (!callbackKeys || ![callbackKeys count]) {
        return;
    }
    
    v8::Local<v8::Value> callbacks = context->Global()->GetHiddenValue(v8::String::New("lexers"));
    if (!&callbacks || !callbacks->IsObject()) {
        return;
    }
    
    for (NSString *key in callbackKeys) {
        v8::Local<v8::Value> callback = callbacks->ToObject()->Get(v8::String::New([key UTF8String]));
        
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
                [textView setShouldDrawText:YES];
            }
        }
    }
}

- (BOOL)loadScript:(NSString *) file
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

- (NSUInteger)createConstants:(const v8::Local<v8::Object> &)proto
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

- (void)initLineNumber:(TELineNumberView *)lineNumberView withGlobal:(const v8::Local<v8::Object> &)proto
{
    v8::Local<v8::Value> styles = proto->Get(v8::String::New("styles"));
    
    if (!*styles || styles->IsUndefined() || !styles->IsObject()) {
        return;
    }
    
    v8::Local<v8::Object> stylesObject = styles->ToObject();
    
        
    // begin lineNumber
    NSScrollView *scrollView = [textViewController scrollView];
    BOOL lineNumber = TEV8BooleanValue(stylesObject->Get(v8::String::New("lineNumber")));
    if (NSNotFound != lineNumber) {
        [scrollView setRulersVisible:lineNumber];
    }
    
    // 设置行号颜色
    NSColor *lineNumberColor = TEV8ColorValue(stylesObject->Get(v8::String::New("lineNumberColor")), [lineNumberView textColor]);
    [lineNumberView setTextColor:lineNumberColor];
    
    // 设置行号背景颜色
    NSColor *lineNumberBackground = TEV8ColorValue(stylesObject->Get(v8::String::New("lineNumberBackground")), [lineNumberView backgroundColor]);
    [lineNumberView setBackgroundColor:lineNumberBackground];
    
    // 设置行号字体
    NSFont *lineNumberFont = TEMakeTextViewFont([lineNumberView font], 
                                                TEV8StringValue(stylesObject->Get(v8::String::New("lineNumberFont"))), 
                                                TEV8FloatVaule(stylesObject->Get(v8::String::New("lineNumberSize"))), 
                                                NO, NO);
    [lineNumberView setFont:lineNumberFont];
}

- (void)initTextView:(TETextView *)textView withGlobal:(const v8::Local<v8::Object> &)proto withLength:(NSUInteger)length
{
    v8::Local<v8::Value> styles = proto->Get(v8::String::New("styles"));
    
    if (!*styles || styles->IsUndefined() || !styles->IsObject()) {
        return;
    }
    
    v8::Local<v8::Object> stylesObject = styles->ToObject();
    
    // begin textView
    // 设置编辑器
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
    
    // 设置行高
    CGFloat lineHeight = TEV8FloatVaule(stylesObject->Get(v8::String::New("lineHeight")));
    if (NSNotFound != lineHeight) {
        [textView setLineHeight:lineHeight];
    }
    
    // 设置选择的文本颜色
    NSColor *selectedColor = TEV8ColorValue(stylesObject->Get(v8::String::New("selectedColor")), [NSColor selectedTextColor]);
    [textView setSelectedColor:selectedColor];
    
    // 设置选择的背景颜色
    NSColor *selectedBackground = TEV8ColorValue(stylesObject->Get(v8::String::New("selectedBackground")), [NSColor selectedTextBackgroundColor]);
    [textView setSelectedBackgroundColor:selectedBackground];
    
    // 设置光标颜色
    NSColor *cursorColor = TEV8ColorValue(stylesObject->Get(v8::String::New("cursorColor")), [NSColor blackColor]);
    [textView setInsertionPointColor:cursorColor];
    
    // 设置水平位移
    CGFloat paddingX = TEV8FloatVaule(stylesObject->Get(v8::String::New("paddingX")));
    if (NSNotFound != paddingX) {
        [textView setPaddingX:paddingX];
    }
    
    // 设置垂直位移
    CGFloat paddingY = TEV8FloatVaule(stylesObject->Get(v8::String::New("paddingY")));
    if (NSNotFound != paddingY) {
        [textView setPaddingY:paddingY];
    }
    
    // 设置tab宽度
    NSInteger tabStop = TEV8IntegerValue(stylesObject->Get(v8::String::New("tabStop")));
    if (NSNotFound != tabStop) {
        [textView setTabStop:tabStop];
    }
    
    // 设置所有style的颜色
    for (NSUInteger i = 0; i < length; i ++) {
        v8::Local<v8::Value> styleItem = stylesObject->Get(v8::Integer::New(i));
        if (!*styleItem || styleItem->IsUndefined() || !styleItem->IsObject()) {
            [textView defineGlyphStyle:TEMakeGlyphStyle(i, defaultFont, defaultColor, defaultBackgroundColor) withType:i];
            continue;
        }
        
        v8::Local<v8::Object> style = v8::Local<v8::Object>::Cast(styleItem);
        
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
