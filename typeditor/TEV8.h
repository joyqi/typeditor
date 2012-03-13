//
//  TEV8.h
//  typeditor
//
//  Created by 宁 祁 on 12-2-25.
//  Copyright (c) 2012年 MagnetJoy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "v8.h"
#import "TETextViewController.h"

#define TEV8_MSG_TEXT_CHANGE @"text-change"
#define TEV8_MSG_INIT_TEXT_VIEW @"init-text-view"
#define TEV8_MSG_INIT_LINE_NUMBER @"init-text-number"

#define TEV8GetController(controller, c) \
    v8::HandleScope handle_scope; \
    v8::Local<v8::Object> self = args.Holder(); \
    if (self->InternalFieldCount() != 1) { \
        return v8::Undefined(); \
    } \
    v8::Local<v8::External> wrap = v8::Local<v8::External>::Cast(self->GetInternalField(0)); \
    TETextViewController *controller = (__bridge TETextViewController *) wrap->Value(); \
    v8::Persistent<v8::Context> c = [controller v8]->context; \
    v8::Context::Scope context_scope(c);

// 把value转换成float
NS_INLINE CGFloat TEV8FloatVaule(const v8::Local<v8::Value> &value) {
    if (*value && !value->IsUndefined() && value->IsNumber()) {
        return value->NumberValue();
    }
    
    return NSNotFound;
}

NS_INLINE NSInteger TEV8BooleanValue(const v8::Local<v8::Value> &value) {
    if (*value && !value->IsUndefined() && value->IsBoolean()) {
        return value->BooleanValue();
    }
    
    return NSNotFound;
}

NS_INLINE NSInteger TEV8IntegerValue(const v8::Local<v8::Value> &value) {
    if (*value && !value->IsUndefined() && value->NumberValue()) {
        return value->IntegerValue();
    }
    
    return NSNotFound;
}

NS_INLINE NSString *TEV8StringValue(const v8::Local<v8::Value> &value) {
    if (*value && !value->IsUndefined() && value->IsString()) {
        v8::String::Utf8Value string(value->ToString());
        return TEMakeString(*string);
    }
    
    return NULL;
}

NS_INLINE NSColor *TEV8ColorValue(const v8::Local<v8::Value> &value, NSColor *color) {
    if (*value && !value->IsUndefined() && value->IsString()) {
        v8::String::Utf8Value string(value->ToString());
        return TEMakeRGBColor(TEMakeString(*string));
    }
    
    return color;
}

@interface TEV8 : NSObject {
    
@public
    v8::Persistent<v8::Context> context;
    
@private
    TETextViewController *textViewController;
    NSMutableDictionary *messages;
}

@property (strong, nonatomic) TETextViewController *textViewController;

- (void)textChangeCallback:(NSString *)string;
- (void)sendMessage:(NSString *)msgType withObject:(id)obj;
@end
