//
//  TETabStyle.m
//  typeditor
//
//  Created by 宁 祁 on 12-3-7.
//  Copyright (c) 2012年 MagnetJoy. All rights reserved.
//

#import "TETabStyle.h"

#define kPSMTEObjectCounterRadius 7.0
#define kPSMTECounterMinWidth 20
#define kPSMTEPadding 20

@implementation TETabStyle

- (NSString *)name
{
    return @"TE";
}

#pragma mark -
#pragma mark Creation/Destruction

- (id) init
{
    if ( (self = [super init]) ) {
        int systemVersion = 0;
		Gestalt(gestaltSystemVersion, &systemVersion);
        if (systemVersion >= 0x1070) {
            windowTitleBarBackgroundColor = [NSColor colorWithDeviceWhite:0.80 alpha:1.0];
        } else {
            windowTitleBarBackgroundColor = [NSColor colorWithDeviceWhite:0.76 alpha:1.0];
        }
        
        teCloseButton = [NSImage imageNamed:@"TabClose_Front.png"];
        teCloseButtonDown = [NSImage imageNamed:@"TabClose_Front_Pressed.png"];
        teCloseButtonOver = [NSImage imageNamed:@"TabClose_Front_Rollover.png"];
        
        teCloseDirtyButton = [NSImage imageNamed:@"TabClose_Dirty.png"];
        teCloseDirtyButtonDown = [NSImage imageNamed:@"TabClose_Dirty_Pressed.png"];
        teCloseDirtyButtonOver = [NSImage imageNamed:@"TabClose_Dirty_Rollover.png"];
        
        _addTabButtonImage = [NSImage imageNamed:@"TabNewTE.png"];
        _addTabButtonPressedImage = [NSImage imageNamed:@"TabNewTEPressed.png"];
        _addTabButtonRolloverImage = [NSImage imageNamed:@"TabNewTERollover.png"];
		
		_objectCountStringAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:[[NSFontManager sharedFontManager] convertFont:[NSFont fontWithName:@"Helvetica" size:11.0] toHaveTrait:NSBoldFontMask], NSFontAttributeName,
                                        [[NSColor whiteColor] colorWithAlphaComponent:0.85], NSForegroundColorAttributeName,
                                        nil, nil];
    }
    return self;
}

- (void)dealloc
{
    teCloseButton = nil;
    teCloseButtonDown = nil;
    teCloseButtonOver = nil;
    teCloseDirtyButton = nil;
    teCloseDirtyButtonDown = nil;
    teCloseDirtyButtonOver = nil;
    _addTabButtonImage = nil;
    _addTabButtonPressedImage = nil;
    _addTabButtonRolloverImage = nil;
    
    _objectCountStringAttributes = nil;
}

#pragma mark -
#pragma mark Control Specific

- (CGFloat)leftMarginForTabBarControl
{
    return 2.0f;
}

- (CGFloat)rightMarginForTabBarControl
{
    return 24.0f;
}

- (CGFloat)topMarginForTabBarControl
{
	return 10.0f;
}

- (void)setOrientation:(PSMTabBarOrientation)value
{
	orientation = value;
}

#pragma mark -
#pragma mark Add Tab Button

- (NSImage *)addTabButtonImage
{
    return _addTabButtonImage;
}

- (NSImage *)addTabButtonPressedImage
{
    return _addTabButtonPressedImage;
}

- (NSImage *)addTabButtonRolloverImage
{
    return _addTabButtonRolloverImage;
}

#pragma mark -
#pragma mark Cell Specific

- (NSRect)dragRectForTabCell:(PSMTabBarCell *)cell orientation:(PSMTabBarOrientation)tabOrientation
{
	NSRect dragRect = [cell frame];
	dragRect.size.width++;
	
	if ([cell tabState] & PSMTab_SelectedMask) {
		if (tabOrientation == PSMTabBarHorizontalOrientation) {
			dragRect.size.height -= 2.0;
		} else {
			dragRect.size.height += 1.0;
			dragRect.origin.y -= 1.0;
			dragRect.origin.x += 2.0;
			dragRect.size.width -= 3.0;
		}
	} else if (tabOrientation == PSMTabBarVerticalOrientation) {
		dragRect.origin.x--;
	}
	
	return dragRect;
}

- (NSRect)closeButtonRectForTabCell:(PSMTabBarCell *)cell withFrame:(NSRect)cellFrame
{
    if ([cell hasCloseButton] == NO) {
        return NSZeroRect;
    }
    
    NSRect result;
    result.size = [teCloseButton size];
    result.origin.x = cellFrame.origin.x + MARGIN_X;
    result.origin.y = cellFrame.origin.y + MARGIN_Y + 2.0;
    
    if ([cell state] == NSOnState) {
        result.origin.y -= 1;
    }
    
    return result;
}

- (NSRect)iconRectForTabCell:(PSMTabBarCell *)cell
{
    NSRect cellFrame = [cell frame];
    
    if ([cell hasIcon] == NO) {
        return NSZeroRect;
    }
    
    NSRect result;
    result.size = NSMakeSize(kPSMTabBarIconWidth, kPSMTabBarIconWidth);
    result.origin.x = cellFrame.origin.x + MARGIN_X;
	result.origin.y = cellFrame.origin.y + MARGIN_Y;
    
    if ([cell hasCloseButton] && ![cell isCloseButtonSuppressed]) {
        result.origin.x += [teCloseButton size].width + kPSMTabBarCellPadding;
    }
    
    if ([cell state] == NSOnState) {
        result.origin.y -= 1;
    }
	
    return result;
}

- (NSRect)indicatorRectForTabCell:(PSMTabBarCell *)cell
{
    NSRect cellFrame = [cell frame];
    
    if ([[cell indicator] isHidden]) {
        return NSZeroRect;
    }
    
    NSRect result;
    result.size = NSMakeSize(kPSMTabBarIndicatorWidth, kPSMTabBarIndicatorWidth);
    result.origin.x = cellFrame.origin.x + cellFrame.size.width - MARGIN_X - kPSMTabBarIndicatorWidth;
    result.origin.y = cellFrame.origin.y + MARGIN_Y;
    
    if ([cell state] == NSOnState) {
        result.origin.y -= 1;
    }
	
    return result;
}

- (NSRect)objectCounterRectForTabCell:(PSMTabBarCell *)cell
{
    NSRect cellFrame = [cell frame];
    
    if ([cell count] == 0) {
        return NSZeroRect;
    }
    
    CGFloat countWidth = [[self attributedObjectCountValueForTabCell:cell] size].width;
    countWidth += (2 * kPSMTEObjectCounterRadius - 6.0);
    if (countWidth < kPSMTECounterMinWidth) {
        countWidth = kPSMTECounterMinWidth;
    }
    
    NSRect result;
    result.size = NSMakeSize(countWidth, 2 * kPSMTEObjectCounterRadius); // temp
    result.origin.x = cellFrame.origin.x + cellFrame.size.width - MARGIN_X - result.size.width;
    result.origin.y = cellFrame.origin.y + MARGIN_Y + 1.0;
    
    if (![[cell indicator] isHidden]) {
        result.origin.x -= kPSMTabBarIndicatorWidth + kPSMTabBarCellPadding;
    }
    
    return result;
}


- (CGFloat)minimumWidthOfTabCell:(PSMTabBarCell *)cell
{
    CGFloat resultWidth = 0.0;
    
    // left margin
    resultWidth = MARGIN_X;
    
    // close button?
    if ([cell hasCloseButton] && ![cell isCloseButtonSuppressed]) {
        resultWidth += [teCloseButton size].width + kPSMTabBarCellPadding;
    }
    
    // icon?
    if ([cell hasIcon]) {
        resultWidth += kPSMTabBarIconWidth + kPSMTabBarCellPadding;
    }
    
    // the label
    resultWidth += kPSMMinimumTitleWidth;
    
    // object counter?
    if ([cell count] > 0) {
        resultWidth += [self objectCounterRectForTabCell:cell].size.width + kPSMTabBarCellPadding;
    }
    
    // indicator?
    if ([[cell indicator] isHidden] == NO)
        resultWidth += kPSMTabBarCellPadding + kPSMTabBarIndicatorWidth;
    
    // right margin
    resultWidth += MARGIN_X;
    
    return ceil(resultWidth);
}

- (CGFloat)desiredWidthOfTabCell:(PSMTabBarCell *)cell
{
    CGFloat resultWidth = 0.0;
    
    // left margin
    resultWidth = MARGIN_X;
    
    // close button?
    if ([cell hasCloseButton] && ![cell isCloseButtonSuppressed])
        resultWidth += [teCloseButton size].width + kPSMTabBarCellPadding;
    
    // icon?
    if ([cell hasIcon]) {
        resultWidth += kPSMTabBarIconWidth + kPSMTabBarCellPadding;
    }
    
    // the label
    resultWidth += [[cell attributedStringValue] size].width;
    
    // object counter?
    if ([cell count] > 0) {
        resultWidth += [self objectCounterRectForTabCell:cell].size.width + kPSMTabBarCellPadding;
    }
    
    // indicator?
    if ([[cell indicator] isHidden] == NO)
        resultWidth += kPSMTabBarCellPadding + kPSMTabBarIndicatorWidth;
    
    // right margin
    resultWidth += MARGIN_X;
    
    return ceil(resultWidth);
}

- (CGFloat)tabCellHeight
{
	return kPSMTabBarControlHeight;
}

#pragma mark -
#pragma mark Cell Values

- (NSAttributedString *)attributedObjectCountValueForTabCell:(PSMTabBarCell *)cell
{
    NSString *contents = [NSString stringWithFormat:@"%lu", (unsigned long)[cell count]];
    return [[NSMutableAttributedString alloc] initWithString:contents attributes:_objectCountStringAttributes];
}

- (NSAttributedString *)attributedStringValueForTabCell:(PSMTabBarCell *)cell
{
    NSMutableAttributedString *attrStr;
    NSString *contents = [cell stringValue];
    attrStr = [[NSMutableAttributedString alloc] initWithString:contents];
    NSRange range = NSMakeRange(0, [contents length]);
    
    // Add font attribute
    [attrStr addAttribute:NSFontAttributeName value:[NSFont boldSystemFontOfSize:11.0] range:range];
    [attrStr addAttribute:NSForegroundColorAttributeName value:[[NSColor textColor] colorWithAlphaComponent:([[tabBar window] isMainWindow] ? 0.75 : 0.5)] range:range];
    
    // Add shadow attribute
    NSShadow* shadow = shadow = [[NSShadow alloc] init];
    [shadow setShadowColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.5]];
    [shadow setShadowOffset:NSMakeSize(0, -1)];
    [shadow setShadowBlurRadius:1.0];
    [attrStr addAttribute:NSShadowAttributeName value:shadow range:range];
    
    // Paragraph Style for Truncating Long Text
    static NSMutableParagraphStyle *TruncatingTailParagraphStyle = nil;
    if (!TruncatingTailParagraphStyle) {
        TruncatingTailParagraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [TruncatingTailParagraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
        [TruncatingTailParagraphStyle setAlignment:NSCenterTextAlignment];
    }
    
    [attrStr addAttribute:NSParagraphStyleAttributeName value:TruncatingTailParagraphStyle range:range];
    
    return attrStr;
}

#pragma mark -
#pragma mark ---- drawing ----

- (void)drawTabCell:(PSMTabBarCell *)cell
{
    NSRect cellFrame = [cell frame];	
    NSColor *lineColor = ([[tabBar window] isMainWindow]) ? [NSColor darkGrayColor] : [NSColor grayColor];
    NSBezierPath *bezier = [NSBezierPath bezierPath];
	
    if ([cell state] == NSOnState)
    {
        // selected tab
        NSRect tabRect = NSOffsetRect(NSInsetRect(cellFrame, 0.5, -10), 0, -10.5);
        bezier = [NSBezierPath bezierPathWithRect:tabRect];
        [lineColor set];
        [bezier setLineWidth:1.0];
        
        // special case of hidden control; need line across top of cell
        if ([[cell controlView] frame].size.height < 2)
        {
            NSRectFillUsingOperation(tabRect, NSCompositeSourceOver);
        }
        else
        {
            // background
            [NSGraphicsContext saveGraphicsState];
            [bezier addClip];
            // NSDrawWindowBackground(cellFrame);
            if ([[tabBar window] isMainWindow]) {
                [windowTitleBarBackgroundColor set];
                NSRectFill( cellFrame );
            } else {
                NSDrawWindowBackground(cellFrame);
            }
            
            [NSGraphicsContext restoreGraphicsState];
            
            [bezier stroke];
        }
    }
    else
    {
        // unselected tab
        NSRect aRect = NSMakeRect(cellFrame.origin.x, cellFrame.origin.y, cellFrame.size.width, cellFrame.size.height);
        aRect.origin.y += 0.5;
        aRect.origin.x += 1.5;
        aRect.size.width -= 1;
        
        [lineColor set];
        
        aRect.origin.x -= 1;
        aRect.size.width += 1;
        
        // frame
        [bezier moveToPoint:NSMakePoint(aRect.origin.x, aRect.origin.y)];
        [bezier lineToPoint:NSMakePoint(aRect.origin.x + aRect.size.width, aRect.origin.y)];
        if (!([cell tabState] & PSMTab_RightIsSelectedMask))
        {
            [bezier lineToPoint:NSMakePoint(aRect.origin.x + aRect.size.width, aRect.origin.y + aRect.size.height)];
        }
        
        [bezier stroke];
    }
    
    [self drawInteriorWithTabCell:cell inView:[cell controlView]];
}


- (void)drawInteriorWithTabCell:(PSMTabBarCell *)cell inView:(NSView*)controlView
{
    NSRect cellFrame = [cell frame];
    
    // close button - only show if mouse over cell
    if ([cell hasCloseButton] && ![cell isCloseButtonSuppressed] && [cell isHighlighted])
    {
        NSSize closeButtonSize = NSZeroSize;
        NSRect closeButtonRect = [cell closeButtonRectForFrame:cellFrame];
        NSImage *closeButton = nil;
        
        closeButton = [cell isEdited] ? teCloseDirtyButton : teCloseButton;
        if ([cell closeButtonOver]) closeButton = [cell isEdited] ? teCloseDirtyButtonOver : teCloseButtonOver;
        if ([cell closeButtonPressed]) closeButton = [cell isEdited] ? teCloseDirtyButtonDown : teCloseButtonDown;
        
        closeButtonSize = [closeButton size];
        if ([controlView isFlipped]) {
            closeButtonRect.origin.y += closeButtonRect.size.height;
        }
        
        [closeButton compositeToPoint:closeButtonRect.origin operation:NSCompositeSourceOver fraction:1.0];
    }
    
    // icon
    //  if ([cell hasIcon])
    //  {
    //    NSRect iconRect = [self iconRectForTabCell:cell];
    //    NSImage *icon = [[[cell representedObject] identifier] icon];
    //      
    //    if ([controlView isFlipped])
    //    {
    //      iconRect.origin.y += iconRect.size.height;
    //    }
    //      
    //    // center in available space (in case icon image is smaller than kPSMTabBarIconWidth)
    //    if ([icon size].width < kPSMTabBarIconWidth)
    //    {
    //      iconRect.origin.x += (kPSMTabBarIconWidth - [icon size].width)/2.0;
    //    }
    //    
    //    if ([icon size].height < kPSMTabBarIconWidth)
    //    {
    //      iconRect.origin.y -= (kPSMTabBarIconWidth - [icon size].height)/2.0;
    //    }
    //      
    //    [icon compositeToPoint:iconRect.origin operation:NSCompositeSourceOver fraction:1.0];
    //  }
    
    // object counter
    if ([cell count] > 0)
    {
        [[cell countColor] ?: [NSColor colorWithCalibratedWhite:0.3 alpha:0.6] set];
        NSBezierPath *path = [NSBezierPath bezierPath];
        NSRect myRect = [self objectCounterRectForTabCell:cell];
        if ([cell state] == NSOnState) {
            myRect.origin.y -= 1.0;
        }
        [path moveToPoint:NSMakePoint(myRect.origin.x + kPSMTEObjectCounterRadius, myRect.origin.y)];
        [path lineToPoint:NSMakePoint(myRect.origin.x + myRect.size.width - kPSMTEObjectCounterRadius, myRect.origin.y)];
        [path appendBezierPathWithArcWithCenter:NSMakePoint(myRect.origin.x + myRect.size.width - kPSMTEObjectCounterRadius, myRect.origin.y + kPSMTEObjectCounterRadius) radius:kPSMTEObjectCounterRadius startAngle:270.0 endAngle:90.0];
        [path lineToPoint:NSMakePoint(myRect.origin.x + kPSMTEObjectCounterRadius, myRect.origin.y + myRect.size.height)];
        [path appendBezierPathWithArcWithCenter:NSMakePoint(myRect.origin.x + kPSMTEObjectCounterRadius, myRect.origin.y + kPSMTEObjectCounterRadius) radius:kPSMTEObjectCounterRadius startAngle:90.0 endAngle:270.0];
        [path fill];
        
        // draw attributed string centered in area
        NSRect counterStringRect;
        NSAttributedString *counterString = [self attributedObjectCountValueForTabCell:cell];
        counterStringRect.size = [counterString size];
        counterStringRect.origin.x = myRect.origin.x + ((myRect.size.width - counterStringRect.size.width) / 2.0) + 0.25;
        counterStringRect.origin.y = myRect.origin.y + ((myRect.size.height - counterStringRect.size.height) / 2.0) + 0.5;
        [counterString drawInRect:counterStringRect];
    }
    
    // draw label
    NSRect labelRect = cellFrame;
    NSAttributedString *string = [cell attributedStringValue];
    NSSize textSize = [string size];
    float textHeight = textSize.height;
    float labelWidth = MIN(cellFrame.size.width - (kPSMTEPadding * 2), textSize.width);
    labelRect.size.height = textHeight;
    labelRect.size.width = labelWidth;
    labelRect.origin.x = cellFrame.origin.x + ((cellFrame.size.width - labelWidth) / 2);
    labelRect.origin.y = ((cellFrame.size.height - textHeight) / 2);
    
    [string drawInRect:labelRect];
}

- (void)drawBackgroundInRect:(NSRect)rect
{
	//Draw for our whole bounds; it'll be automatically clipped to fit the appropriate drawing area
	rect = [tabBar bounds];
	
	[NSGraphicsContext saveGraphicsState];
	[[NSGraphicsContext currentContext] setShouldAntialias:NO];
    
    [[NSColor colorWithCalibratedWhite:0.0 alpha:([[tabBar window] isMainWindow] ? 0.1 : 0.05)] set];
    NSRectFillUsingOperation(rect, NSCompositeSourceAtop);
    
    NSGradient *shadow = [[NSGradient alloc ] initWithStartingColor:[NSColor colorWithDeviceWhite:0 alpha:([[tabBar window] isMainWindow] ? 0.15 : 0.1)] endingColor:[NSColor clearColor]];
    NSRect shadowRect = NSMakeRect(rect.origin.x, rect.origin.y, rect.size.width, 7);
    [shadow drawInRect:shadowRect angle:90];
    shadow = nil;
    
    if ([[tabBar window] isMainWindow])
    {
        [[NSColor darkGrayColor] set];
    }
    else
    {
        [[NSColor grayColor] set];
    }
	
    [NSBezierPath strokeLineFromPoint:NSMakePoint(rect.origin.x, rect.origin.y + 0.5) toPoint:NSMakePoint(rect.origin.x + rect.size.width, rect.origin.y + 0.5)];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(rect.origin.x, rect.origin.y + rect.size.height - 0.5) toPoint:NSMakePoint(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height - 0.5)];
	
	[NSGraphicsContext restoreGraphicsState];
}


- (void)drawTabBar:(PSMTabBarControl *)bar inRect:(NSRect)rect
{	
	if (tabBar != bar) {
		tabBar = bar;
	}
	
	[self drawBackgroundInRect:rect];
	
	// no tab view == not connected
    if (![bar tabView])
    {
        NSRect labelRect = rect;
        labelRect.size.height -= 4.0;
        labelRect.origin.y += 4.0;
        NSMutableAttributedString *attrStr;
        NSString *contents = @"PSMTabBarControl";
        attrStr = [[NSMutableAttributedString alloc] initWithString:contents];
        NSRange range = NSMakeRange(0, [contents length]);
        [attrStr addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:11.0] range:range];
        NSMutableParagraphStyle *centeredParagraphStyle = nil;
        if (!centeredParagraphStyle) {
            centeredParagraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
            [centeredParagraphStyle setAlignment:NSCenterTextAlignment];
        }
        [attrStr addAttribute:NSParagraphStyleAttributeName value:centeredParagraphStyle range:range];
        [attrStr drawInRect:labelRect];
        return;
    }
    
    // draw cells
    NSEnumerator *e = [[bar cells] objectEnumerator];
    PSMTabBarCell *cell;
    while ( (cell = [e nextObject]) ) {
        if ([bar isAnimating] || (![cell isInOverflowMenu] && NSIntersectsRect([cell frame], rect))) {
            [cell drawWithFrame:[cell frame] inView:bar];
        }
    }
}   	

#pragma mark -
#pragma mark Archiving

- (void)encodeWithCoder:(NSCoder *)aCoder 
{
    //[super encodeWithCoder:aCoder];
    if ([aCoder allowsKeyedCoding]) {
        [aCoder encodeObject:teCloseButton forKey:@"teCloseButton"];
        [aCoder encodeObject:teCloseButtonDown forKey:@"teCloseButtonDown"];
        [aCoder encodeObject:teCloseButtonOver forKey:@"teCloseButtonOver"];
        [aCoder encodeObject:teCloseDirtyButton forKey:@"teCloseDirtyButton"];
        [aCoder encodeObject:teCloseDirtyButtonDown forKey:@"teCloseDirtyButtonDown"];
        [aCoder encodeObject:teCloseDirtyButtonOver forKey:@"teCloseDirtyButtonOver"];
        [aCoder encodeObject:_addTabButtonImage forKey:@"addTabButtonImage"];
        [aCoder encodeObject:_addTabButtonPressedImage forKey:@"addTabButtonPressedImage"];
        [aCoder encodeObject:_addTabButtonRolloverImage forKey:@"addTabButtonRolloverImage"];
    }
}

- (id)initWithCoder:(NSCoder *)aDecoder 
{
    // self = [super initWithCoder:aDecoder];
    //if (self) {
    if ([aDecoder allowsKeyedCoding]) {
        teCloseButton = [aDecoder decodeObjectForKey:@"teCloseButton"];
        teCloseButtonDown = [aDecoder decodeObjectForKey:@"teCloseButtonDown"];
        teCloseButtonOver = [aDecoder decodeObjectForKey:@"teCloseButtonOver"];
        teCloseDirtyButton = [aDecoder decodeObjectForKey:@"teCloseDirtyButton"];
        teCloseDirtyButtonDown = [aDecoder decodeObjectForKey:@"teCloseDirtyButtonDown"];
        teCloseDirtyButtonOver = [aDecoder decodeObjectForKey:@"teCloseDirtyButtonOver"];
        _addTabButtonImage = [aDecoder decodeObjectForKey:@"addTabButtonImage"];
        _addTabButtonPressedImage = [aDecoder decodeObjectForKey:@"addTabButtonPressedImage"];
        _addTabButtonRolloverImage = [aDecoder decodeObjectForKey:@"addTabButtonRolloverImage"];
    }
    //}
    return self;
}

@end
