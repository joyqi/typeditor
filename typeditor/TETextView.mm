//
//  TETextView.m
//  typeditor
//
//  Created by 宁 祁 on 12-2-25.
//  Copyright (c) 2012年 MagnetJoy. All rights reserved.
//

#import "TETextView.h"

@implementation TETextView

@synthesize glyphRangesNum, color, lineHeight, tabStop, selectedColor, selectedBackgroundColor;

- (void) defineGlyphStyle:(TEGlyphStyle *)style withType:(NSUInteger)type
{
    if (type < TE_MAX_GLYPH_STYLES_NUM) {
        definedGlyphStyles[type] = style;
    }
}

- (void) setGlyphRange:(TEGlyphRange)glyphRange withIndex:(NSUInteger)index
{
    if (index < TE_MAX_GLYPH_RANGES_NUM) {
        glyphRanges[index] = glyphRange;
    }
}

- (NSFont *) font
{
    NSFont *font = [self font];
    if (!font) {
        font = TEMakeTextViewFont(NULL, NULL, NSNotFound, NSNotFound, NSNotFound);
        [self setFont:font];
    }
    
    return font;
}

- (void) setFont:(NSFont *)obj
{
    [super setFont:obj];
    TETextViewSetTypingAttribute(obj, NSFontAttributeName);
}

- (void) setColor:(NSColor *)obj
{
    color = obj;
    TETextViewSetTypingAttribute(obj, NSForegroundColorAttributeName);
}

- (void) setLineHeight:(CGFloat)height
{
    lineHeight = height;
    TETextViewSetParagraphStyle(setMaximumLineHeight, height,
                                setMinimumLineHeight, height);
}

- (void) setTabStop:(NSUInteger)length
{
    tabStop = length;
    TETextViewSetParagraphStyle(setTabStops, [NSArray array],
                                setDefaultTabInterval, length * TEFontWidth([self font]));
}

- (void) setSelectedColor:(NSColor *)obj
{
    selectedColor = obj;
    TETextViewSetSelectedAttribute(obj, NSForegroundColorAttributeName);
}

- (void) setSelectedBackgroundColor:(NSColor *)obj
{
    selectedBackgroundColor = obj;
    TETextViewSetSelectedAttribute(obj, NSBackgroundColorAttributeName);
}

- (id) initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    
    if (self) {
        // [NSTimer timerWithTimeInterval:1 target:self selector:@selector(cursorDrawCursor) userInfo:<#(id)#> repeats:<#(BOOL)#>
    }
    
    return self;
}

- (BOOL)shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)replacementString
{
    shouldDrawText = YES;
    return YES;
}

- (NSRange) rectToGlyphRange:(NSRect)rect
{
    NSLayoutManager *lm = [self layoutManager];
    NSRange glyphRange = [lm glyphRangeForBoundingRect:rect inTextContainer:[self textContainer]];
    NSRange characterRange = [lm characterRangeForGlyphRange:glyphRange actualGlyphRange:NULL];
    NSUInteger p = floor(glyphRangesNum / 2), q, from = characterRange.location,
    to = characterRange.location + characterRange.length;

    // 使用二分法来查找当前的range的开始处
    do {
        NSUInteger start = glyphRanges[p].location, stop = glyphRanges[p].location + glyphRanges[p].length;
        
        if (from >= start && from <= stop) {
            break;
        } else if (from < start) {
            p = floor(p / 2);
        } else if (from > stop) {
            p = p + ceil(p / 2);
        }
        
    } while (p > 0 && p < glyphRangesNum - 1);
    
    // 找到开始处以后再用循环方法找到结尾处
    for (q = p; q < glyphRangesNum; q ++) {
        if (to <= glyphRanges[p].location + glyphRanges[p].length) {
            break;
        }
    }
    
    return NSMakeRange(p, q - p);
}

- (void)drawInsertionPointInRect:(NSRect)rect color:(NSColor *)cursorColor turnedOn:(BOOL)flag
{
    if (flag) {
        [cursorColor set];
        NSRectFill(rect);
    } else {
        [self setNeedsDisplayInRect:[self visibleRect] avoidAdditionalLayout:NO];
    }
}

- (void)_drawInsertionPointInRect:(NSRect)rect color:(NSColor *)cursorColor
{
    
    [cursorColor set];
    NSRectFill(rect);
}

// refresh rect with higthlight color
- (void)drawRect:(NSRect)dirtyRect
{
    NSRange range = [self rectToGlyphRange:dirtyRect];
    NSUInteger from = range.location, to = range.location + range.length;
    NSTextStorage *ts = [self textStorage];
    NSLayoutManager *lm = [self layoutManager];
    
    // 重新渲染
    if (shouldDrawText) {
        NSRange visibleGlyphRange = [lm glyphRangeForBoundingRect:[self visibleRect]
                                                  inTextContainer:[self textContainer]];
        NSRange visableCharacterRange = [lm characterRangeForGlyphRange:visibleGlyphRange actualGlyphRange:NULL];
        
        for (NSUInteger i = from; i <= to; i ++) {
            TEGlyphRange gr = glyphRanges[i];
            
            TEGlyphStyle *style = definedGlyphStyles[gr.styleType];
            [ts setAttributes:style->attributes range:NSMakeRange(fmax(visableCharacterRange.location, gr.location),
                                                                  fmin(gr.length + gr.location - visableCharacterRange.location, gr.length))];
        }
        
        shouldDrawText = NO;
    }
    
    [super drawRect:dirtyRect];
}

@end
