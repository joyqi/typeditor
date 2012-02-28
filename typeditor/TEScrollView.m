//
//  TEScrollView.m
//  typeditor
//
//  Created by  on 12-2-28.
//  Copyright (c) 2012年 MagnetJoy. All rights reserved.
//

#import "TEScrollView.h"
#import "TEScroller.h"

@implementation TEScrollView

- (void) tile
{
    [super tile];
    
	NSRect frame;
	CGFloat height;
    NSRect bounds = [self bounds], adjustBounds = bounds;
    
	adjustBounds.origin.x += [[self verticalRulerView] frame].size.width;
    adjustBounds.size.width -= [[self verticalRulerView] frame].size.width;
    
    [[self contentView] setFrame:adjustBounds];
    height = bounds.size.height;
	frame = NSMakeRect(bounds.size.width - 15, 0, 15, height);
	[[self verticalScroller] setFrame:frame];
	
	NSScroller *scroller = [self verticalScroller];
	[[self verticalScroller] removeFromSuperview];
	[self addSubview:scroller];
}

@end
