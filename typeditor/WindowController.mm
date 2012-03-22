//
//  WindowController.m
//  typeditor
//
//  Created by 宁 祁 on 12-2-19.
//  Copyright (c) 2012年 MagnetJoy. All rights reserved.
//

#import "WindowController.h"
#import "PSMTabBarControl.h"
#import "PSMRolloverButton.h"
#import "TETextViewController.h"
#import "TETabStyle.h"

@interface WindowController (Private)
- (void)createTabNamed:(NSString *)name withText:(NSString *)text isFocus:(BOOL)focus;
@end

@implementation WindowController

- (id)initWithApp:(NSObject *)app
{
    self = [super initWithWindowNibName:@"WindowController"];
    if (self) {
        autoIncrementId = 0;
        mainWindow = (INAppStoreWindow *)[self window];
        
        // init tab
        NSRect tabFrame = {{0, 0}, {[mainWindow frame].size.width, TE_WINDOW_TAB_HEIGHT}};
        
        tabView = [[NSTabView alloc] initWithFrame:NSZeroRect];
        tabBar = [[PSMTabBarControl alloc] initWithFrame:tabFrame];
        [tabBar setStyle:[[TETabStyle alloc] init]];
        
        [tabView setDelegate:(id)tabBar];
        [tabBar setTabView:tabView];
        [tabBar setDelegate:self];
        [tabBar setShowAddTabButton:YES];
        [tabBar setAutoresizingMask:NSViewWidthSizable];
        [[mainWindow titleBarView] setAutoresizesSubviews:YES];
        [[mainWindow titleBarView] addSubview:tabBar];
        [[mainWindow titleBarView] addSubview:tabView];
        
        [[tabBar addTabButton] setTarget:self];
        [[tabBar addTabButton] setAction:@selector(addNewTab:)];
        
        titleTextField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, TE_WINDOW_TAB_HEIGHT - 2.0f, tabFrame.size.width, TE_WINDOW_TITLE_HEIGHT - TE_WINDOW_TAB_HEIGHT)];
        [titleTextField setBackgroundColor:[NSColor clearColor]];
        [titleTextField setBezeled:NSNoBorder];
        [titleTextField setEditable:NO];
        [titleTextField setTextColor:[NSColor grayColor]];
        [titleTextField setAlignment:NSCenterTextAlignment];
        [titleTextField setAutoresizingMask:NSViewWidthSizable];
        
        [[mainWindow titleBarView] addSubview:titleTextField];
        
        [tabBar setDelegate:self];
        [mainWindow setDelegate:self];
        
        // Initialization code here.
        [mainWindow setTrafficLightButtonsLeftMargin:7.0f];
        [mainWindow setCenterTrafficLightButtons:NO];
        [mainWindow setHideTitleBarInFullScreen:NO];
        [mainWindow setCenterFullScreenButton:YES];
        [mainWindow setTitleBarHeight:TE_WINDOW_TITLE_HEIGHT];
        [mainWindow setShowsBaselineSeparator:NO];
        [mainWindow setAutorecalculatesContentBorderThickness:YES forEdge:NSMinYEdge];
        [mainWindow setContentBorderThickness:TE_WINDOW_BOTTOM_HEIGHT forEdge:NSMinYEdge];
        [mainWindow setMinSize:NSMakeSize(TE_WINDOW_MIN_WIDTH, TE_WINDOW_MIN_HEIGHT)];
        
        textViewController = [[TETextViewController alloc] initWithWindow:mainWindow];
        [self createTabNamed:NSLocalizedString(@"Untitled", nil) withText:@"" isFocus:YES];
    }
    
    return self;
}

- (void)setTitle:(NSString *)title
{
    [titleTextField setStringValue:title];
}

- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    [self setTitle:[tabViewItem label]];
    [textViewController selectTabNamed:[tabViewItem identifier]];
}

- (void)tabView:(NSTabView *)aTabView didCloseTabViewItem:(NSTabViewItem *)tabViewItem
{
    [textViewController closeTabNamed:[tabViewItem identifier]];
}

- (void)addNewTab:(id)sender
{
    [self createTabNamed:NSLocalizedString(@"Untitled", nil) withText:@"" isFocus:YES];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
}

#pragma mark - Private methods

- (void)createTabNamed:(NSString *)name withText:(NSString *)text isFocus:(BOOL)focus
{
    autoIncrementId ++;
    NSString *identifier = [NSString stringWithFormat:@"tab-%d", autoIncrementId];
    NSTabViewItem *tabViewItem = [[NSTabViewItem alloc] initWithIdentifier:identifier];
    [tabViewItem setLabel:name];
    
    [textViewController createTabNamed:identifier withText:text];
    [tabView addTabViewItem:tabViewItem];
    
    if (focus) {
        [tabView selectTabViewItem:tabViewItem];
    }
}

@end
