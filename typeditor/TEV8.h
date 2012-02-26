//
//  TEV8.h
//  typeditor
//
//  Created by 宁 祁 on 12-2-25.
//  Copyright (c) 2012年 MagnetJoy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "v8.h"
#import "TE.h"

// 把value转换成float
NS_INLINE CGFloat TEV8FloatVaule(const v8::Local<v8::Value> &value) {
    if (!value->IsUndefined() && value->IsNumber()) {
        return value->NumberValue();
    }
    
    return NSNotFound;
}

NS_INLINE NSInteger TEV8BooleanValue(const v8::Local<v8::Value> &value) {
    if (!value->IsUndefined() && value->IsBoolean()) {
        return value->BooleanValue();
    }
    
    return NSNotFound;
}

NS_INLINE NSString *TEV8StringValue(const v8::Local<v8::Value> &value) {
    if (!value->IsUndefined() && value->IsString()) {
        v8::String::Utf8Value string(value->ToString());
        return TEMakeString(*string);
    }
    
    return NULL;
}

NS_INLINE NSColor *TEV8ColorValue(const v8::Local<v8::Value> &value, NSColor *color) {
    if (!value->IsUndefined() && value->IsString()) {
        v8::String::Utf8Value string(value->ToString());
        return TEMakeRGBColor(TEMakeString(*string));
    }
    
    return color;
}

@class TETextView;

@interface TEV8 : NSObject {
    
    // v8 context
    v8::Persistent<v8::Context> context;
}

- (id) initWithTextView:(TETextView *)textView;
@end

@interface TEV8 (TETextView)
- (void) initTextView:(TETextView *)textView;
@end
