//
//  TETabStorage.h
//  typeditor
//
//  Created by  on 12-3-9.
//  Copyright (c) 2012年 MagnetJoy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TETextView.h"
#import "TELineNumberView.h"

@interface TETabStorage : NSObject {
    TETextView *_textView;
    TELineNumberView *_lineNumberView;
    NSRange _selectedRange;
}

@property (strong, nonatomic) TETextView *textView;
@property (strong, nonatomic) TELineNumberView *lineNumberView;
@property (assign, nonatomic) NSRange selectedRange;

@end
