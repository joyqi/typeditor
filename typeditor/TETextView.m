//
//  TETextView.m
//  typeditor
//
//  Created by 宁 祁 on 12-2-25.
//  Copyright (c) 2012年 MagnetJoy. All rights reserved.
//

#import "TETextView.h"

@implementation TETextView

@synthesize glyphRangesNum;

- (void) defineGlyphStyle:(TEGlyphStyle *)style withType:(NSUInteger)type {
    if (type < TE_MAX_GLYPH_STYLES_NUM) {
        definedGlyphStyles[type] = style;
    }
}

- (void) setGlyphRange:(TEGlyphRange)glyphRange withIndex:(NSUInteger)index {
    if (index < TE_MAX_GLYPH_RANGES_NUM) {
        glyphRanges[index] = glyphRange;
    }
}

- (NSRange) rectToGlyphRange:(NSRect)rect {
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

// refresh rect with higthlight color
- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    NSRange range = [self rectToGlyphRange:dirtyRect];
    NSUInteger from = range.location, to = range.location + range.length;
    NSTextStorage *ts = [self textStorage];
    
    // 重新渲染
    for (NSUInteger i = from; i <= to; i ++) {
        TEGlyphRange gr = glyphRanges[i];
        [ts setAttributes:definedGlyphStyles[gr.styleType]->attributes range:NSMakeRange(gr.location, gr.length)];
    }
}

@end
