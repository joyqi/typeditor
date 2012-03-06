//
//  TETextViewController.m
//  typeditor
//
//  Created by 宁 祁 on 12-2-26.
//  Copyright (c) 2012年 MagnetJoy. All rights reserved.
//

#import "TETextViewController.h"
#import "PSMTabBarControl.h"
#import "TEV8.h"
#import "INAppStoreWindow.h"

@implementation TETextViewController

@synthesize window, lineNumberView, textView, scrollView, v8;

// init with parent window
- (id)initWithWindow:(NSWindow *)parent
{
    self = [super initWithNibName:[self className] bundle:nil];
    
    if (self) {
        window = parent;
        NSRect windowFrame = [[window contentView] frame], 
        scrollFrame = { { 0, 0}, windowFrame.size },
        tabFrame = { {0, 0}, {windowFrame.size.width, 22.0f} };
        
        containter = [[NSView alloc] initWithFrame:windowFrame];
        [containter setAutoresizesSubviews:YES];
        [containter setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [window setContentView:containter];
        
        // init tabbar
        tabView = [[NSTabView alloc] initWithFrame:NSZeroRect];
        tabBar = [[PSMTabBarControl alloc] initWithFrame:tabFrame];
        
        [tabBar setStyleNamed:@"Unified"];
        
        [tabView setDelegate:(id)tabBar];
        [tabBar setTabView:tabView];
        [tabBar setDelegate:self];
        [[(INAppStoreWindow *)window titleBarView] addSubview:tabBar];
        
        NSTabViewItem *item = [[NSTabViewItem alloc] initWithIdentifier:@"test"];
        [item setLabel:@"dddd"];
        [tabView addTabViewItem:item];
        
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
        [window makeKeyAndOrderFront:nil];
        [window makeFirstResponder:textView];
        [containter addSubview:scrollView];
        
        lineNumberView = [[TELineNumberView alloc] initWithScrollView:scrollView];
        [scrollView setVerticalRulerView:lineNumberView];
        
        // scroll view changed
        [[scrollView contentView] setPostsBoundsChangedNotifications:YES];
        [[scrollView contentView] setPostsFrameChangedNotifications:YES];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(boundsDidChange:) name:NSViewBoundsDidChangeNotification object:[scrollView contentView]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(frameDidChange:) name:NSViewFrameDidChangeNotification object:[scrollView contentView]];
        
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
    [textView setShouldDrawText:YES];
}

- (void)frameDidChange:(NSNotification *)aNotification
{
    [textView setShouldDrawText:YES];
    [tabBar setFrameSize:NSMakeSize([window frame].size.width, 22.0f)];
}

@end
