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

#define TECheckMessage 100

#define TEV8Context(c, controller) \
    v8::HandleScope handle_scope; \
    v8::Local<v8::Object> self = args.Holder(); \
    if (self->InternalFieldCount() != 2) { \
        return v8::Undefined(); \
    } \
    v8::Local<v8::External> wrapController = v8::Local<v8::External>::Cast(self->GetInternalField(0)); \
    TETextViewController *controller = (__bridge TETextViewController *) wrapController->Value(); \
    v8::Persistent<v8::Context> c = [controller v8]->context; \
    v8::Context::Scope context_scope(c);

@interface TEV8 : NSObject <NSMachPortDelegate> {
    
@public
    v8::Isolate *isolate;
    v8::Persistent<v8::Context> context;
    
@private
    TETextViewController *textViewController;
    TEMessage *messages;
    
    NSMutableDictionary *lexers;
    
    NSPort *localPort;
    
    NSString *suffix;
    
    NSUInteger readPos;
    NSUInteger writePos;
    NSUInteger typeCount;
}

@property (strong, nonatomic) TETextViewController *textViewController;
@property (strong, nonatomic) NSMutableDictionary *lexers;

- (id)initWithTextViewController:(TETextViewController *)aTextViewController;
- (void)textChangeCallback:(NSString *)string;
- (void)sendMessage:(TEMessageType)msgType withObject:(id)obj;
@end
