//
//  TETextView.h
//  typeditor
//
//  Created by 宁 祁 on 12-2-25.
//  Copyright (c) 2012年 MagnetJoy. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "TE.h"

@interface TETextView : NSTextView {
    
    // 预定义的glyph style 数组
    TEGlyphStyle *definedGlyphStyles[TE_MAX_GLYPH_STYLES_NUM];
    
    // glyph的预定义缓冲区
    TEGlyphRange glyphRanges[TE_MAX_GLYPH_RANGES_NUM];
    NSUInteger glyphRangesNum;
}

@property (assign) NSUInteger glyphRangesNum;

- (void) defineGlyphStyle:(TEGlyphStyle *)style withType:(NSUInteger)type;
- (void) setGlyphRange:(TEGlyphRange)glyphRange withIndex:(NSUInteger)index;
- (NSRange) rectToGlyphRange:(NSRect)rect;

@end
