//
//  EditorStyle.m
//  typeditor
//
//  Created by 宁 祁 on 12-2-23.
//  Copyright (c) 2012年 MagnetJoy. All rights reserved.
//

#import "EditorStyle.h"

@implementation EditorStyle

@synthesize font = _font, color = _color, backgroundColor = _backgroundColor;

- (id) init:(NSFont *)font withColor:(NSColor *)color withBackgroundColor:(NSColor *)backgroundColor
{
    self = [super init];
    if (self) {
        _font = font;
        _color = color;
        _backgroundColor = backgroundColor;
        
        font = nil;
        color = nil;
        backgroundColor = nil;
    }
    
    return self;
}

@end
