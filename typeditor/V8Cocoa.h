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

#define v8method(method) \
    v8::Handle<v8::Value> (* method)(const v8::Arguments &) = (v8::Handle<v8::Value> (*)(const v8::Arguments &))[self methodForSelector:@selector(method: args:)]

@interface V8Cocoa : NSObject {
    ScintillaView *scintillaView;
    v8::Persistent<v8::Context> context;
}

- (BOOL)embedScintilla:(ScintillaView *) senderScintillaView;
- (ScintillaView *)scintillaView;

- (v8::Handle<v8::Value>) log:(const v8::Arguments& )args;

@end
