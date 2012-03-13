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
#import "TETabStorage.h"

@implementation TETextViewController

@synthesize window, lineNumberView, textView, scrollView, v8, containter;

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
        
        scrollView = [[NSScrollView alloc] initWithFrame:scrollFrame];
        
        [scrollView setBorderType:NSNoBorder];
        [scrollView setHasVerticalScroller:YES];
        [scrollView setHasHorizontalScroller:NO];
        [scrollView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [containter addSubview:scrollView];
        
        lineNumberView = [[TELineNumberView alloc] init];
        [lineNumberView setOrientation:NSVerticalRuler];
        [lineNumberView setScrollView:scrollView];
        [scrollView setVerticalRulerView:lineNumberView];
        
        // scroll view changed
        [[scrollView contentView] setPostsBoundsChangedNotifications:YES];
        [[scrollView contentView] setPostsFrameChangedNotifications:YES];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(boundsDidChange:) name:NSViewBoundsDidChangeNotification object:[scrollView contentView]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(frameDidChange:) name:NSViewFrameDidChangeNotification object:[scrollView contentView]];
        
        // 将v8引擎作为独立线程载入
        v8 = [[TEV8 alloc] init];
        dispatch_queue_t queue = dispatch_queue_create("com.example.CriticalTaskQueue", NULL);
        dispatch_async(queue, ^{
            [v8 setTextViewController:self];
        });
        
        // init line number
        // [v8 sendMessage:TEV8_MSG_INIT_LINE_NUMBER withObject:lineNumberView];
    }
    
    return self;
}

- (void)createTabNamed:(NSString *)name withText:(NSString *)text
{
    TETextView *newTextView = [[TETextView alloc] initWithFrame:[scrollView frame]];
    NSSize contentSize = [scrollView contentSize];
    NSRange selectedRange = {0, 0};
    
    [newTextView setMinSize:NSMakeSize(0.0, contentSize.height)];
    [newTextView setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];
    [newTextView setVerticallyResizable:YES];
    [newTextView setHorizontallyResizable:NO];
    [newTextView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [newTextView setRichText:NO];
    [newTextView setImportsGraphics:NO];
    
    // clear all text container
    [[newTextView textContainer] setContainerSize:NSMakeSize(contentSize.width, FLT_MAX)];
    [[newTextView textContainer] setWidthTracksTextView:YES];
    
    // set text
    [newTextView setString:text];
    [newTextView setDelegate:self];
    
    TETabStorage *tabStorage = [[TETabStorage alloc] init];
    [tabStorage setTextView:newTextView];
    [tabStorage setSelectedRange:selectedRange];
    
    [tabStorages setValue:tabStorage forKey:name];
    [v8 sendMessage:TEV8_MSG_INIT_TEXT_VIEW withObject:newTextView];
}

-(void)textDidChange:(NSNotification *)notification
{
    NSLog(@"%@", [notification object]);
}

- (void)selectTabNamed:(NSString *)name
{
    TETabStorage *tabStorage = [tabStorages objectForKey:name];
    if (tabStorage) {
        [scrollView setDocumentView:[tabStorage textView]];
        [lineNumberView setClientView:textView];
        textView = [tabStorage textView];
        
        [window makeKeyAndOrderFront:nil];
        [window makeFirstResponder:textView];
        [textView scrollRangeToVisible:[tabStorage selectedRange]];
    }
}

- (void)boundsDidChange:(NSNotification *)aNotification
{
    [textView setShouldDrawText:YES];
}

- (void)frameDidChange:(NSNotification *)aNotification
{
    [textView setShouldDrawText:YES];
}

@end
