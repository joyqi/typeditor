//
//  TEScrollView.h
//  typeditor
//
//  Created by  on 12-2-28.
//  Copyright (c) 2012年 MagnetJoy. All rights reserved.
//

#import <AppKit/AppKit.h>

NS_INLINE void TEFillRoundedRect(NSRect rect, CGFloat x, CGFloat y)
{
    NSBezierPath* thePath = [NSBezierPath bezierPath];
	
    [thePath appendBezierPathWithRoundedRect:rect xRadius:x yRadius:y];
    [thePath fill];
}

NS_INLINE void TEStrokeRoundedRect(NSRect rect, CGFloat x, CGFloat y)
{
    NSBezierPath* thePath = [NSBezierPath bezierPath];
	
	[thePath setLineWidth:1];
    [thePath appendBezierPathWithRoundedRect:rect xRadius:x yRadius:y];
    [thePath stroke];
}

NS_INLINE void TEDrawPath(CGContextRef context, CGRect rect, float ovalWidth, float ovalHeight)
{
    float fw, fh;
    
    if (ovalWidth == 0 || ovalHeight == 0) {
        CGContextAddRect(context, rect);
        return;
    }
    
    CGContextSaveGState(context);
    
    CGContextTranslateCTM (context, CGRectGetMinX(rect),
                           CGRectGetMinY(rect));
    CGContextScaleCTM (context, ovalWidth, ovalHeight);
    fw = CGRectGetWidth (rect) / ovalWidth;
    fh = CGRectGetHeight (rect) / ovalHeight;
    
    CGContextMoveToPoint(context, fw, fh/2);
    CGContextAddArcToPoint(context, fw, fh, fw/2, fh, 1);
    CGContextAddArcToPoint(context, 0, fh, 0, fh/2, 1);
    CGContextAddArcToPoint(context, 0, 0, fw/2, 0, 1);
    CGContextAddArcToPoint(context, fw, 0, fw, fh/2, 1);
    CGContextClosePath(context);
    
    CGContextRestoreGState(context);
}

NS_INLINE void TECGContextFillRoundRect(CGContextRef context, CGRect rect, float ovalWidth, float ovalHeight)
{
    TEDrawPath(context, rect, ovalWidth, ovalHeight);
    CGContextEOFillPath(context);
}

NS_INLINE void TECGContextStrokeRoundRect(CGContextRef context, CGRect rect, float ovalWidth, float ovalHeight)
{
    TEDrawPath(context, rect, ovalWidth, ovalHeight);
    CGContextStrokePath(context);
}

@interface TEScroller : NSScroller {
    int _animationStep;
	float _oldValue;
	BOOL _scheduled;
	BOOL _disableFade;
    BOOL _shouldClearBackground;
}

@property (nonatomic, assign) BOOL shouldClearBackground;

- (void) showScroller;

@end
