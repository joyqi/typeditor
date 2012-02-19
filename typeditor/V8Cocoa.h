//
//  V8Cocoa.h
//  typeditor
//
//  Created by  on 12-2-17.
//  Copyright (c) 2012年 MagnetJoy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ScintillaView.h"
#import "v8.h"

#define editor(e) \
v8::Local<v8::Object> self = args.Holder(); \
if (self->InternalFieldCount() != 1) { \
    return v8::Undefined(); \
} \
v8::Local<v8::External> wrap = v8::Local<v8::External>::Cast(self->GetInternalField(0)); \
ScintillaView *e = (__bridge ScintillaView *) wrap->Value();

@interface V8Cocoa : NSObject {
    ScintillaView *scintillaView;
    v8::Persistent<v8::Context> context;
}

- (BOOL)embedScintilla:(ScintillaView *) senderScintillaView;
- (ScintillaView *)scintillaView;

@end
