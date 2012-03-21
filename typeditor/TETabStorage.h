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
    NSString *_text;
    TELineNumberView *_lineNumberView;
    NSRange _selectedRange;
}

@property (strong, nonatomic) NSString *text;
@property (strong, nonatomic) TELineNumberView *lineNumberView;
@property (assign, nonatomic) NSRange selectedRange;

@end
