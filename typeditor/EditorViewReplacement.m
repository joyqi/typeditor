//
//  EditorViewReplacement.m
//  typeditor
//
//  Created by 宁 祁 on 12-2-20.
//  Copyright (c) 2012年 MagnetJoy. All rights reserved.
//

#import "EditorViewReplacement.h"

@implementation EditorViewReplacement

@synthesize area = _area, string = _string;

- (id) init:(NSRange)area replacementString:(NSString *)string
{
    self = [super init];
    if (self) {
        [self setArea:area];
        [self setString:string];
    }
    
    return self;
}

@end
