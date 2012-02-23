//
//  EditorStyle.h
//  typeditor
//
//  Created by 宁 祁 on 12-2-23.
//  Copyright (c) 2012年 MagnetJoy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EditorStyle : NSObject {
    
    // font name
    NSFont *_font;
    
    // foreground color
    NSColor *_color;
    
    // backgourn color
    NSColor *_backgroundColor;
}

@property (strong, nonatomic) NSFont *font;
@property (strong, nonatomic) NSColor *color;
@property (strong, nonatomic) NSColor *backgroundColor;

- (id) init:(NSFont *)font withColor:(NSColor *)color withBackgroundColor:(NSColor *)color;
@end
