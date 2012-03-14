//
//  TETextView.m
//  typeditor
//
//  Created by 宁 祁 on 12-2-25.
//  Copyright (c) 2012年 MagnetJoy. All rights reserved.
//

#import "TETextView.h"

@implementation TETextView

@synthesize glyphRangesNum, color, lineHeight, tabStop, selectedColor, selectedBackgroundColor, shouldDrawText;

- (void) defineGlyphStyle:(TEGlyphStyle *)style withType:(NSUInteger)type
{
    if (type < TE_MAX_GLYPH_STYLES_NUM) {
        [definedGlyphStyles insertObject:style atIndex:type];
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

- (void) setPaddingX:(CGFloat)padingX
{
    NSSize paddingSize = [self textContainerInset];
    paddingSize.width = padingX;
    [self setTextContainerInset:paddingSize];
}

- (void) setPaddingY:(CGFloat)padingX
{
    NSSize paddingSize = [self textContainerInset];
    paddingSize.height = padingX;
    [self setTextContainerInset:paddingSize];
}

- (id) initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    
    if (self) {
        glyphRanges = (TEGlyphRange *)malloc(sizeof(TEGlyphRange) * TE_MAX_GLYPH_RANGES_NUM);
        definedGlyphStyles = [NSMutableArray arrayWithCapacity:TE_MAX_GLYPH_STYLES_NUM];
        layoutManager = [self layoutManager];
    }
    
    return self;
}

- (void) dealloc
{
    free(glyphRanges);
}

- (BOOL)shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)replacementString
{
    BOOL should = [super shouldChangeTextInRange:affectedCharRange replacementString:replacementString];
    shouldDrawText = YES;
    return should;
}

- (NSRange) rectToGlyphRange:(NSRect)rect effectiveRange:(NSRange *)range
{
    NSLayoutManager *lm = [self layoutManager];
    NSRange glyphRange = [lm glyphRangeForBoundingRect:rect inTextContainer:[self textContainer]];
    NSRange characterRange = [lm characterRangeForGlyphRange:glyphRange actualGlyphRange:NULL];
    NSInteger p = 0, q = glyphRangesNum - 1, m = 0, n = 0,
    from = characterRange.location, to = characterRange.location + characterRange.length;
    
    range->location = characterRange.location;
    range->length = characterRange.length;
    
    while (p <= q) {
        m = (p + q) / 2;
        
        NSUInteger start = glyphRanges[m].location, stop = glyphRanges[m].location + glyphRanges[m].length;
        
        if (from >= start && from <= stop) {
            break;
        } else if (from < start) {
            q = m - 1;
        } else if (from > stop) {
            p = m + 1;
        }
    }
    
    // 找到开始处以后再用循环方法找到结尾处
    for (n = m; n < glyphRangesNum - 1; n ++) {
        if (to <= glyphRanges[n].location + glyphRanges[n].length) {
            break;
        }
    }
    
    return NSMakeRange(m, n - m);
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
    // 重新渲染
    if (shouldDrawText && glyphRangesNum > 0) {
        NSRange effectiveRange;
        NSRange range = [self rectToGlyphRange:dirtyRect effectiveRange:&effectiveRange];
        NSUInteger from = range.location, to = range.location + range.length;
        
        for (NSUInteger i = from; i <= to; i ++) {
            TEGlyphRange gr = glyphRanges[i];
            
            // ignore failed
            if (gr.styleType >= TE_MAX_GLYPH_STYLES_NUM) {
                continue;
            }
            
            TEGlyphStyle *style = [definedGlyphStyles objectAtIndex:gr.styleType];
            [layoutManager setTemporaryAttributes:style->attributes forCharacterRange:NSMakeRange(gr.location, gr.length)];
        }
        
        shouldDrawText = NO;
    }
    
    [super drawRect:dirtyRect];
}

@end
