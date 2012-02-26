//
//  TEGlyphStyle.h
//  typeditor
//
//  Created by 宁 祁 on 12-2-26.
//  Copyright (c) 2012年 MagnetJoy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TEGlyphStyle : NSObject {
@public
    
    // font type
    NSNumber *type;
    
    // font name
    NSFont *font;
    
    // foreground color
    NSColor *color;
    
    // backgourn color
    NSColor *backgroundColor;
    
    // attributes
    NSDictionary *attributes;
}
@end
