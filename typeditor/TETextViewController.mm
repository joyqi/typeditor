//
//  TETextViewController.m
//  typeditor
//
//  Created by 宁 祁 on 12-2-26.
//  Copyright (c) 2012年 MagnetJoy. All rights reserved.
//

#import "TETextViewController.h"
#import "TEV8.h"
#import "INAppStoreWindow.h"

@implementation TETextViewController

@synthesize window, lineNumberView, textView, scrollView, v8, tabViewItem, containter;

// init with parent window
- (id)initWithWindow:(INAppStoreWindow *)parent
{
    self = [super initWithNibName:[self className] bundle:nil];
    
    if (self) {
        window = parent;
        NSRect windowFrame = [[window contentView] frame];
        windowFrame.origin.y += TE_WINDOW_BOTTOM_HEIGHT;
        windowFrame.size.height -= TE_WINDOW_BOTTOM_HEIGHT;
        
        NSRect scrollFrame = {{0, 0}, windowFrame.size};
        
        containter = [[NSView alloc] initWithFrame:windowFrame];
        [containter setHidden:YES];
        [containter setAutoresizesSubviews:YES];
        [containter setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [[window contentView] addSubview:containter];
        focused = NO;
        
        scrollView = [[NSScrollView alloc] initWithFrame:scrollFrame];
        NSSize contentSize = [scrollView contentSize];
        
        [scrollView setBorderType:NSNoBorder];
        [scrollView setHasVerticalScroller:YES];
        [scrollView setHasHorizontalScroller:NO];
        [scrollView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        
        textView = [[TETextView alloc] initWithFrame:scrollFrame];
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
        [containter addSubview:scrollView];
        
        lineNumberView = [[TELineNumberView alloc] initWithScrollView:scrollView];
        [scrollView setVerticalRulerView:lineNumberView];
        
        // scroll view changed
        [[scrollView contentView] setPostsBoundsChangedNotifications:YES];
        [[scrollView contentView] setPostsFrameChangedNotifications:YES];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(boundsDidChange:) name:NSViewBoundsDidChangeNotification object:[scrollView contentView]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(frameDidChange:) name:NSViewFrameDidChangeNotification object:[scrollView contentView]];
        
        // 将v8引擎作为独立线程载入
        dispatch_queue_t queue = dispatch_queue_create("com.example.CriticalTaskQueue", NULL);
        dispatch_async(queue, ^{
            v8 = [[TEV8 alloc] init];
            [v8 setTextViewController:self];
        });
        
        // set delegate
        [textView setDelegate:self];
        [[textView textStorage] setDelegate:self];
    }
    
    return self;
}

- (void) setTabViewItem:(NSTabViewItem *)_tabViewItem
{
    tabViewItem = _tabViewItem;
    [containter setIdentifier:[_tabViewItem identifier]];
}

- (BOOL)textView:(NSTextView *)currentTextView shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)replacementString
{
    NSString *string = [[currentTextView string] stringByReplacingCharactersInRange:affectedCharRange withString:replacementString];
    [v8 sendMessage:TEV8_MSG_TEXT_CHANGE withObject:string];
    
    return YES;
}

- (void)boundsDidChange:(NSNotification *)aNotification
{
    [textView setShouldDrawText:YES];
}

- (void)frameDidChange:(NSNotification *)aNotification
{
    [textView setShouldDrawText:YES];
}

- (void)focus
{
    [containter setHidden:NO];
    [window makeKeyAndOrderFront:nil];
    [window makeFirstResponder:textView];
    focused = YES;
}

- (void)blur
{
    [containter setHidden:YES];
    focused = NO;
}

@end
