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

@synthesize window, textView, scrollView, v8, containter;

// init with parent window
- (id)initWithWindow:(INAppStoreWindow *)parent
{
    self = [super initWithNibName:[self className] bundle:nil];
    
    if (self) {
        window = parent;
        tabStorages = [NSMutableDictionary dictionary];
        NSRect windowFrame = [[window contentView] frame];
        windowFrame.origin.y += TE_WINDOW_BOTTOM_HEIGHT;
        windowFrame.size.height -= TE_WINDOW_BOTTOM_HEIGHT;
        
        NSRect scrollFrame = {{0, 0}, windowFrame.size};
        
        containter = [[NSView alloc] initWithFrame:windowFrame];
        [containter setAutoresizesSubviews:YES];
        [containter setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [[window contentView] addSubview:containter];
        
        scrollView = [[NSScrollView alloc] initWithFrame:scrollFrame];
        
        [scrollView setBorderType:NSNoBorder];
        [scrollView setHasVerticalScroller:YES];
        [scrollView setHasHorizontalScroller:NO];
        [scrollView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [containter addSubview:scrollView];
        
        NSSize contentSize = [scrollView contentSize];
        textView = [[TETextView alloc] initWithFrame:scrollFrame];
        
        [textView setMinSize:NSMakeSize(0.0, contentSize.height)];
        [textView setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];
        [textView setVerticallyResizable:YES];
        [textView setHorizontallyResizable:NO];
        [textView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [textView setRichText:NO];
        [textView setImportsGraphics:NO];
        
        // clear all text container
        [[textView textContainer] setContainerSize:NSMakeSize(contentSize.width, FLT_MAX)];
        [[textView textContainer] setWidthTracksTextView:YES];
        [textView setDelegate:self];
        [scrollView setDocumentView:textView];
        
        // scroll view changed
        [[scrollView contentView] setPostsBoundsChangedNotifications:YES];
        [[scrollView contentView] setPostsFrameChangedNotifications:YES];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(boundsDidChange:) name:NSViewBoundsDidChangeNotification object:[scrollView contentView]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(frameDidChange:) name:NSViewFrameDidChangeNotification object:[scrollView contentView]];
        
        // 将v8引擎作为独立线程载入
        v8 = [[TEV8 alloc] init];
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(queue, ^{
            [v8 setTextViewController:self];
        });
        
        // init text view
        [v8 sendMessage:TEMessageTypeInitTextView withObject:textView];
    }
    
    return self;
}

- (void)createTabNamed:(NSString *)name withText:(NSString *)text
{
    NSRange selectedRange = {0, 0};
    
    TELineNumberView *lineNumberView = [[TELineNumberView alloc] initWithScrollView:scrollView];
    [lineNumberView setOrientation:NSVerticalRuler];
    [lineNumberView setScrollView:scrollView];
    
    // init line number
    [v8 sendMessage:TEMessageTypeInitLineNumber withObject:lineNumberView];
    
    TETabStorage *tabStorage = [[TETabStorage alloc] init];
    [tabStorage setSelectedRange:selectedRange];
    [tabStorage setText:@""];
    [tabStorage setLineNumberView:lineNumberView];
    
    [tabStorages setValue:tabStorage forKey:name];
}

-(void)textDidChange:(NSNotification *)notification
{
    [v8 sendMessage:TEMessageTypeTextChange withObject:[(TETextView *)[notification object] string]];
}

- (void)selectTabNamed:(NSString *)name
{
    if (lastTab && ![lastTab isEqualToString:name]) {
        TETabStorage *lastTabStorage = [tabStorages objectForKey:lastTab];
        if (lastTabStorage) {
            [lastTabStorage setText:[[textView string] copy]];
            [lastTabStorage setSelectedRange:[textView selectedRange]];
        }
    }
    
    TETabStorage *tabStorage = [tabStorages objectForKey:name];

    if (tabStorage) {
        [window makeKeyAndOrderFront:nil];
        [window makeFirstResponder:textView];
        [textView setString:[tabStorage text]];
        [scrollView setVerticalRulerView:[tabStorage lineNumberView]];
        [textView scrollRangeToVisible:[tabStorage selectedRange]];
        [v8 sendMessage:TEMessageTypeTextChange withObject:[tabStorage text]];
    }
    
    lastTab = name;
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
