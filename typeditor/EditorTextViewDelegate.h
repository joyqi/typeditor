//
//  EditorViewDelegate.h
//  typeditor
//
//  Created by 宁 祁 on 12-2-22.
//  Copyright (c) 2012年 MagnetJoy. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol EditorTextViewDelegate <NSTextViewDelegate>
@optional
- (void)insertText:(id)insertString;
@end
