//
//  TETabStyle.h
//  typeditor
//
//  Created by 宁 祁 on 12-3-7.
//  Copyright (c) 2012年 MagnetJoy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PSMTabStyle.h"

@interface TETabStyle : NSObject <PSMTabStyle> {
    NSImage *teCloseButton;
    NSImage *teCloseButtonDown;
    NSImage *teCloseButtonOver;
    NSImage *teCloseDirtyButton;
    NSImage *teCloseDirtyButtonDown;
    NSImage *teCloseDirtyButtonOver;
    NSImage *_addTabButtonImage;
    NSImage *_addTabButtonPressedImage;
    NSImage *_addTabButtonRolloverImage;
	
	NSDictionary *_objectCountStringAttributes;
    
    NSColor *windowTitleBarBackgroundColor;
	
	PSMTabBarOrientation orientation;
	PSMTabBarControl *tabBar;
}

- (void)drawInteriorWithTabCell:(PSMTabBarCell *)cell inView:(NSView*)controlView;

- (void)encodeWithCoder:(NSCoder *)aCoder;
- (id)initWithCoder:(NSCoder *)aDecoder;

@end
