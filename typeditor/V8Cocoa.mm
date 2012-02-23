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

const char *LEXER_TYPE = "none boolean character number string conditional constant define delimiter float function "
"indentifier keyword label macro special_char special_comment match operator class statement structure "
"tag title todo typedef type comment";

@interface V8Cocoa (Private)
- (BOOL) createContext:(id)editor;
- (BOOL) loadScript:(NSString *) file;
- (void) createConstants:(const v8::Local<v8::Object> &) proto;
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

// register tab function
v8::Handle<v8::Value> onTab(const v8::Arguments &args)
{
    importEditor(editor, context);
    v8::Local<v8::String> key = v8::String::New("tabHandler");
    
    if (args.Length() >= 1 || args[0]->IsFunction()) {
        context->Global()->SetHiddenValue(key, args[0]);
    }
    
    return v8::Undefined();
}

// register tab function
v8::Handle<v8::Value> onNewLine(const v8::Arguments &args)
{
    importEditor(editor, context);
    v8::Local<v8::String> key = v8::String::New("newLineHandler");
    
    if (args.Length() >= 1 || args[0]->IsFunction()) {
        context->Global()->SetHiddenValue(key, args[0]);
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
v8::Handle<v8::Value> string(const v8::Arguments &args)
{
    importEditor(editor, context);
    
    NSString *result;
    
    if (2 <= args.Length() &&
        args[0]->IsNumber() &&
        args[1]->IsNumber()) {
        result = [(EditorTextView *)[editor editor] stringAt:args[0]->IntegerValue() withLength:args[1]->IntegerValue()];
    } else if (1 <= args.Length() &&
        args[0]->IsNumber()) {
        result = [(EditorTextView *)[editor editor] stringAt:args[0]->IntegerValue()];
    } else {
        result = [[editor editor] string];
    }
    
    return result ? v8::String::New([result cStringUsingEncoding:NSUTF8StringEncoding]) : v8::Undefined();
}

// get text
v8::Handle<v8::Value> line(const v8::Arguments &args)
{
    importEditor(editor, context);
    
    if (1 <= args.Length() &&
        args[0]->IsNumber()) {
        return v8::Integer::New([(EditorTextView *)[editor editor] lineAt:args[0]->IntegerValue()]);
    } else {
        return v8::Integer::New([(EditorTextView *)[editor editor] lineCurrent]);
    }
    
    return v8::Undefined();
}

// get line range
v8::Handle<v8::Value> lineRange(const v8::Arguments &args)
{
    importEditor(editor, context);
    
    if (1 <= args.Length() &&
        args[0]->IsNumber()) {
        NSRange range = [(EditorTextView *)[editor editor] lineRange:args[0]->IntegerValue()];
        v8::Local<v8::ObjectTemplate> resultTemplate = v8::ObjectTemplate::New();
        v8::Local<v8::Object> result = resultTemplate->NewInstance();
        
        result->Set(v8::String::New("location"), v8::Integer::New(range.location));
        result->Set(v8::String::New("length"), v8::Integer::New(range.length));
        
        return result;
    }
    
    return v8::Undefined();
}

// get charactor width
v8::Handle<v8::Value> width(const v8::Arguments &args)
{
    importEditor(editor, context);
    
    if (2 <= args.Length() &&
        args[0]->IsNumber() &&
        args[1]->IsNumber()) {
        return v8::Integer::New([(EditorTextView *)[editor editor] countWidth:NSMakeRange(args[0]->IntegerValue(), args[1]->IntegerValue())]);
    }
    
    return v8::Undefined();
}

// indent with width
v8::Handle<v8::Value> indent(const v8::Arguments &args)
{
    importEditor(editor, context);
    
    if (2 <= args.Length() &&
        args[0]->IsNumber() &&
        args[1]->IsNumber()) {
        [(EditorTextView *)[editor editor] appendTab:args[0]->IntegerValue() withWidth:args[1]->IntegerValue()];
    }
    
    return v8::Undefined();
}

// indent with width
v8::Handle<v8::Value> select(const v8::Arguments &args)
{
    importEditor(editor, context);
    
    if (2 <= args.Length() &&
        args[0]->IsNumber() &&
        args[1]->IsNumber()) {
        [(EditorTextView *)[editor editor] setSelectedRange:NSMakeRange(args[0]->IntegerValue(), args[1]->IntegerValue())];
    } else if (1 <= args.Length() &&
               args[0]->IsNumber()) {
        [(EditorTextView *)[editor editor] setSelectedRange:NSMakeRange(args[0]->IntegerValue(), 1)];
    }
    
    return v8::Undefined();
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

// highlight range
v8::Handle<v8::Value> highlight(const v8::Arguments &args)
{
    importEditor(editor, context);
    
    if (2 <= args.Length() &&
        args[0]->IsNumber() &&
        args[1]->IsNumber()) {
        [[editor editor] showFindIndicatorForRange:NSMakeRange(args[0]->IntegerValue(), args[0]->IntegerValue())];
    } else if (1 <= args.Length() &&
               args[0]->IsNumber()) {
        [[editor editor] showFindIndicatorForRange:NSMakeRange(args[0]->IntegerValue(), 1)];
    }
    
    return v8::Undefined();
}

// scroll to range
v8::Handle<v8::Value> scrollTo(const v8::Arguments &args)
{
    importEditor(editor, context);
    
    if (2 <= args.Length() &&
        args[0]->IsNumber() &&
        args[1]->IsNumber()) {
        [[editor editor] scrollRangeToVisible:NSMakeRange(args[0]->IntegerValue(), args[0]->IntegerValue())];
    } else if (1 <= args.Length() &&
               args[0]->IsNumber()) {
        [[editor editor] scrollRangeToVisible:NSMakeRange(args[0]->IntegerValue(), 1)];
    }
    
    return v8::Undefined();
}

// get current position
v8::Handle<v8::Value> currentPosition(const v8::Arguments &args)
{
    importEditor(editor, context);
    NSRange range = [[editor editor] selectedRange];
    
    return v8::Integer::New(range.location);
}

// get is softTab
v8::Handle<v8::Value> isSoftTab(const v8::Arguments &args)
{
    importEditor(editor, context);
    return v8::BooleanObject::New([(EditorTextView *)[editor editor] softTab]);
}

// get is softTab
v8::Handle<v8::Value> tabStop(const v8::Arguments &args)
{
    importEditor(editor, context);
    return v8::Integer::New([(EditorTextView *)[editor editor] tabStop]);
}

@implementation V8Cocoa

- (void)dealloc
{
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
    proto_t->Set("onTab", v8::FunctionTemplate::New(onTab));
    proto_t->Set("onNewLine", v8::FunctionTemplate::New(onNewLine));
    proto_t->Set("style", v8::FunctionTemplate::New(style));
    proto_t->Set("editorStyle", v8::FunctionTemplate::New(editorStyle));
    proto_t->Set("string", v8::FunctionTemplate::New(string));
    proto_t->Set("line", v8::FunctionTemplate::New(line));
    proto_t->Set("lineRange", v8::FunctionTemplate::New(lineRange));
    proto_t->Set("replace", v8::FunctionTemplate::New(replace));
    proto_t->Set("insert", v8::FunctionTemplate::New(insert));
    proto_t->Set("remove", v8::FunctionTemplate::New(remove));
    proto_t->Set("select", v8::FunctionTemplate::New(select));
    proto_t->Set("selectedRange", v8::FunctionTemplate::New(selectedRange));
    proto_t->Set("currentPosition", v8::FunctionTemplate::New(currentPosition));
    proto_t->Set("highlight", v8::FunctionTemplate::New(highlight));
    proto_t->Set("scrollTo", v8::FunctionTemplate::New(scrollTo));
    proto_t->Set("tabStop", v8::FunctionTemplate::New(tabStop));
    proto_t->Set("isSoftTab", v8::FunctionTemplate::New(isSoftTab));
    proto_t->Set("width", v8::FunctionTemplate::New(width));
    proto_t->Set("indent", v8::FunctionTemplate::New(indent));
    
    v8::Handle<v8::Function> ctor = templ->GetFunction();
    v8::Handle<v8::Object> obj = ctor->NewInstance();
    obj->SetInternalField(0, v8::External::New((__bridge void *)editor));
    context->Global()->Set(v8::String::New("$"), obj);
    
    [self createConstants:context->Global()];
    
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

- (void) createConstants:(const v8::Local<v8::Object> &) proto
{
    char *result, constants[1024], *q = constants, prefix[32] = "$";
    v8::Handle<v8::ObjectTemplate> stylesTemplate = v8::ObjectTemplate::New();
    v8::Local<v8::Object> styles = stylesTemplate->NewInstance();

    strcpy(constants, LEXER_TYPE);
    while ((result = strsep(&q, " ")) != NULL) {
        // define constants
        proto->Set(v8::String::New(strcat(prefix, result)), v8::String::New(result));
        memset(prefix + 1, 0, 31);
        
        // define default styles
        v8::Handle<v8::ObjectTemplate> styleTemplate = v8::ObjectTemplate::New();
        v8::Local<v8::Object> style = styleTemplate->NewInstance();
        styles->Set(v8::String::New(result), style);
    }
    
    proto->Set(v8::String::New("styles"), styles);
}

@end
