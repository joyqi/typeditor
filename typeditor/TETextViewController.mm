//
//  TETextViewController.m
//  typeditor
//
//  Created by 宁 祁 on 12-2-26.
//  Copyright (c) 2012年 MagnetJoy. All rights reserved.
//

#import "TETextViewController.h"
#import "TEV8.h"

@implementation TETextViewController

@synthesize window, lineNumber, textView, scroll, v8;

// init with parent window
- (id)initWithWindow:(NSWindow *)parent
{
    self = [super initWithNibName:[self className] bundle:nil];
    
    if (self) {
        window = parent;
        
        scroll = [[NSScrollView alloc] initWithFrame:[[window contentView] frame]];
        NSSize contentSize = [scroll contentSize];
        
        [scroll setBorderType:NSNoBorder];
        [scroll setHasVerticalScroller:YES];
        [scroll setHasHorizontalScroller:NO];
        [scroll setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [scroll setDrawsBackground:NO];
        
        textView = [[TETextView alloc] initWithFrame:[[window contentView] frame]];
        // [textView setEditorViewController:self];
        [textView setMinSize:NSMakeSize(0.0, contentSize.height)];
        [textView setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];
        [textView setVerticallyResizable:YES];
        [textView setHorizontallyResizable:NO];
        [textView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        
        [[textView textContainer] setContainerSize:NSMakeSize(contentSize.width, FLT_MAX)];
        [[textView textContainer] setWidthTracksTextView:YES];
        
        // disale rich edit
        [textView setRichText:NO];
        [textView setImportsGraphics:NO];
        
        [scroll setDocumentView:textView];
        [window setContentView:scroll];
        [window makeKeyAndOrderFront:nil];
        [window makeFirstResponder:textView];
        
        lineNumber = [[EditorLineNumberView alloc] initWithScrollView:scroll];
        [scroll setVerticalRulerView:lineNumber];
        
        v8 = [[TEV8 alloc] init];
        [v8 setController:self];
        
        // set delegate
        [textView setDelegate:self];
        [[textView textStorage] setDelegate:self];
    }
    
    return self;
}

- (void)textStorageDidProcessEditing:(NSNotification *)notification
{
    NSTextStorage *textStorage = [notification object];
    [v8 textChangeCallback:[textStorage string]];
}

@end
