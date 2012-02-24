//
//  EditorStyle.h
//  typeditor
//
//  Created by 宁 祁 on 12-2-23.
//  Copyright (c) 2012年 MagnetJoy. All rights reserved.
//

#import <Foundation/Foundation.h>

#define EditorStyleAttributeName @"EditorStyleAttributeName"

@interface EditorStyle : NSObject {
    
    NSString *_type;
    
    // font name
    NSFont *_font;
    
    // foreground color
    NSColor *_color;
    
    // backgourn color
    NSColor *_backgroundColor;
    
    // attributes
    NSMutableDictionary *_attributes;
}

@property (strong, nonatomic) NSString *type;
@property (strong, nonatomic) NSFont *font;
@property (strong, nonatomic) NSColor *color;
@property (strong, nonatomic) NSColor *backgroundColor;
@property (strong, nonatomic) NSMutableDictionary *attributes;

- (id) init:(NSString *)type withFont:(NSFont *)font withColor:(NSColor *)color withBackgroundColor:(NSColor *)backgroundColor;
@end
