//
//  EditorLineNumberMarker.h
//  typeditor
//
//  Created by 宁 祁 on 12-2-21.
//  Copyright (c) 2012年 MagnetJoy. All rights reserved.
//

#import <AppKit/AppKit.h>

#define EDITOR_LINE_CODING_KEY		@"line"

@interface EditorLineNumberMarker : NSRulerMarker {
    NSUInteger		_lineNumber;
}

- (id)initWithRulerView:(NSRulerView *)aRulerView lineNumber:(CGFloat)line image:(NSImage *)anImage imageOrigin:(NSPoint)imageOrigin;

- (void)setLineNumber:(NSUInteger)line;
- (NSUInteger)lineNumber;

@end
