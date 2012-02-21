//
//  EditorLineNumberView.h
//  typeditor
//
//  Created by 宁 祁 on 12-2-21.
//  Copyright (c) 2012年 MagnetJoy. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "EditorLineNumberMarker.h"

#define DEFAULT_THICKNESS	22.0
#define RULER_MARGIN		5.0

#define EDITOR_FONT_CODING_KEY				@"font"
#define EDITOR_TEXT_COLOR_CODING_KEY		@"textColor"
#define EDITOR_ALT_TEXT_COLOR_CODING_KEY	@"alternateTextColor"
#define EDITOR_BACKGROUND_COLOR_CODING_KEY	@"backgroundColor"

@interface EditorLineNumberView : NSRulerView {
    // Array of character indices for the beginning of each line
    NSMutableArray      *_lineIndices;
	// Maps line numbers to markers
	NSMutableDictionary	*_linesToMarkers;
	NSFont              *_font;
	NSColor				*_textColor;
	NSColor				*_alternateTextColor;
	NSColor				*_backgroundColor;
    float               value;
}

- (id)initWithScrollView:(NSScrollView *)aScrollView;

- (id)initWithScrollView:(NSScrollView *)scrollView orientation:(NSRulerOrientation)orientation;

- (void)setFont:(NSFont *)aFont;
- (NSFont *)font;

- (void)setTextColor:(NSColor *)color;
- (NSColor *)textColor;

- (void)setAlternateTextColor:(NSColor *)color;
- (NSColor *)alternateTextColor;

- (void)setBackgroundColor:(NSColor *)color;
- (NSColor *)backgroundColor;

- (NSUInteger)lineNumberForLocation:(CGFloat)location;
- (EditorLineNumberMarker *)markerAtLine:(NSUInteger)line;

@end
