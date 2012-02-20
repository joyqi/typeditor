//
//  EditorViewReplacement.h
//  typeditor
//
//  Created by 宁 祁 on 12-2-20.
//  Copyright (c) 2012年 MagnetJoy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EditorViewReplacement : NSObject {
    // replace area
    NSRange _area;
    
    // replace string
    NSString *_string;
}

@property (nonatomic, assign) NSRange area;
@property (nonatomic, strong) NSString *string;

- (id) init:(NSRange)area replacementString:(NSString *)string; 
@end
