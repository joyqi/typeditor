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

@synthesize window, lineNumberView, textView, scrollView, v8;

// init with parent window
- (id)initWithWindow:(NSWindow *)parent
{
    self = [super initWithNibName:[self className] bundle:nil];
    
    if (self) {
        window = parent;
        
        scrollView = [[NSScrollView alloc] initWithFrame:[[window contentView] frame]];
        NSSize contentSize = [scrollView contentSize];
        
        [scrollView setBorderType:NSNoBorder];
        [scrollView setHasVerticalScroller:YES];
        [scrollView setHasHorizontalScroller:NO];
        [scrollView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [scrollView setDrawsBackground:NO];
        
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
        
        [scrollView setDocumentView:textView];
        [window setContentView:scrollView];
        [window makeKeyAndOrderFront:nil];
        [window makeFirstResponder:textView];
        
        lineNumberView = [[TELineNumberView alloc] initWithScrollView:scrollView];
        [scrollView setVerticalRulerView:lineNumberView];
        
        // scroll view changed
        [[scrollView contentView] setPostsBoundsChangedNotifications:YES];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(boundsDidChange:) name:NSViewBoundsDidChangeNotification object:[scrollView contentView]];
        
        v8 = [[TEV8 alloc] init];
        [v8 setTextViewController:self];
        
        // set delegate
        [textView setDelegate:self];
        [[textView textStorage] setDelegate:self];
    }
    
    return self;
}

- (BOOL)textView:(NSTextView *)currentTextView shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)replacementString
{
    NSString *string = [[currentTextView string] stringByReplacingCharactersInRange:affectedCharRange withString:replacementString];
    [v8 textChangeCallback:string];
    
    return YES;
}

- (void)boundsDidChange:(NSNotification *)aNotification
{
    NSClipView *contentView = [aNotification object];
    NSRect rect = [contentView documentVisibleRect];
    
    [textView didScroll:rect];
}

@end
