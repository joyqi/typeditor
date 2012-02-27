//
//  EditorLineNumberMarker.m
//  typeditor
//
//  Created by 宁 祁 on 12-2-21.
//  Copyright (c) 2012年 MagnetJoy. All rights reserved.
//

#import "TELineNumberMarker.h"

@implementation TELineNumberMarker

- (id)initWithRulerView:(NSRulerView *)aRulerView lineNumber:(CGFloat)line image:(NSImage *)anImage imageOrigin:(NSPoint)imageOrigin
{
	if ((self = [super initWithRulerView:aRulerView markerLocation:0.0 image:anImage imageOrigin:imageOrigin]) != nil)
	{
		_lineNumber = line;
	}
	return self;
}

- (void)setLineNumber:(NSUInteger)line
{
	_lineNumber = line;
}

- (NSUInteger)lineNumber
{
	return _lineNumber;
}

#pragma mark NSCoding methods

- (id)initWithCoder:(NSCoder *)decoder
{
	if ((self = [super initWithCoder:decoder]) != nil)
	{
		if ([decoder allowsKeyedCoding])
		{
			_lineNumber = [[decoder decodeObjectForKey:TE_LINE_NUMBER_LINE_CODING_KEY] unsignedIntegerValue];
		}
		else
		{
			_lineNumber = [[decoder decodeObject] unsignedIntegerValue];
		}
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
	[super encodeWithCoder:encoder];
	
	if ([encoder allowsKeyedCoding])
	{
		[encoder encodeObject:[NSNumber numberWithUnsignedInteger:_lineNumber] forKey:TE_LINE_NUMBER_LINE_CODING_KEY];
	}
	else
	{
		[encoder encodeObject:[NSNumber numberWithUnsignedInteger:_lineNumber]];
	}
}


#pragma mark NSCopying methods

- (id)copyWithZone:(NSZone *)zone
{
	id		copy;
	
	copy = [super copyWithZone:zone];
	[copy setLineNumber:_lineNumber];
	
	return copy;
}

@end
