//
//  EditorStyle.m
//  typeditor
//
//  Created by 宁 祁 on 12-2-23.
//  Copyright (c) 2012年 MagnetJoy. All rights reserved.
//

#import "EditorStyle.h"

@implementation EditorStyle

@synthesize type = _type, font = _font, color = _color, backgroundColor = _backgroundColor, attributes = _attributes;

- (id) init:(NSString *)type withFont:(NSFont *)font withColor:(NSColor *)color withBackgroundColor:(NSColor *)backgroundColor
{
    self = [super init];
    if (self) {
        _type = type;
        _font = font;
        _color = color;
        _backgroundColor = backgroundColor;
        _attributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                       type, EditorStyleAttributeName,
                       font, NSFontAttributeName,
                       color, NSForegroundColorAttributeName,
                       backgroundColor, NSBackgroundColorAttributeName, nil];
        
        type = nil;
        font = nil;
        color = nil;
        backgroundColor = nil;
    }
    
    return self;
}

@end
