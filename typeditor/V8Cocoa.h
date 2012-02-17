//
//  V8Cocoa.h
//  typeditor
//
//  Created by  on 12-2-17.
//  Copyright (c) 2012年 MagnetJoy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ScintillaView.h"
#import "v8.h"

@interface V8Cocoa : NSObject {
    ScintillaView *scintillaView;
}

- (void)embedScintilla:(ScintillaView *) senderScintillaView;
+ (V8Cocoa *)shared;
+ (ScintillaView *)scintillaView;

@end
