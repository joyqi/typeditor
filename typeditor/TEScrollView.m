//
//  TEScrollView.m
//  typeditor
//
//  Created by  on 12-2-28.
//  Copyright (c) 2012年 MagnetJoy. All rights reserved.
//

#import "TE.h"
#import "TEScrollView.h"
#import "TEScroller.h"
#import "TELineNumberView.h"

@implementation TEScrollView

- (void) tile
{
    // [super tile];
    NSRect bounds = [self bounds], adjustBounds = bounds;
    CGFloat height = bounds.size.height;
    
    TELineNumberView *lineNumber = (TELineNumberView *)[self verticalRulerView];
    NSUInteger currentLineNumber = [lineNumber currentLineNumber];
    CGFloat fontWidth = TEFontWidth([lineNumber font]);
    
    
    CGFloat width = (currentLineNumber > 0 ? (floor(log10(currentLineNumber)) + 1) * fontWidth : fontWidth) + 2 * RULER_MARGIN;
    
    adjustBounds.origin.x += width;
    adjustBounds.size.width -= width;
    
    [[self contentView] setFrame:adjustBounds];
    
    [[self verticalScroller] setFrame:NSMakeRect(bounds.size.width - 15, 0, 15, height)];
    [lineNumber setFrame:NSMakeRect(0, 0, width, height)];
    [lineNumber setNeedsDisplay:YES];
    NSLog(@"%f", [lineNumber bounds].size.width);

    NSScroller *scroller = [self verticalScroller];
    [[self verticalScroller] removeFromSuperview];
    [self addSubview:scroller];
    
    [[self verticalRulerView] removeFromSuperview];
    [self addSubview:lineNumber];
    // [ invalidateHashMarks];
}

@end
