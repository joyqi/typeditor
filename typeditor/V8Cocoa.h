//
//  V8Cocoa.h
//  typeditor
//
//  Created by  on 12-2-17.
//  Copyright (c) 2012年 MagnetJoy. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "v8.h"

#define importEditor(e, c) \
v8::HandleScope handle_scope; \
v8::Local<v8::Object> self = args.Holder(); \
if (self->InternalFieldCount() != 1) { \
    return v8::Undefined(); \
} \
v8::Local<v8::External> wrap = v8::Local<v8::External>::Cast(self->GetInternalField(0)); \
EditorViewController *e = (__bridge EditorViewController *) wrap->Value(); \
v8::Persistent<v8::Context> c = [e v8]->context; \
v8::Context::Scope context_scope(c);

#define cstring(str) \
[[NSString alloc] initWithCString:str encoding:NSUTF8StringEncoding]

@interface V8Cocoa : NSObject {
@public
    v8::Persistent<v8::Context> context;
}

- (BOOL)embed:(id)editor;

@end
