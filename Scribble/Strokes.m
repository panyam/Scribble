//
//  Strokes.m
//  Salmon
//
//  Created by Sri Panyam on 4/06/2015.
//  Copyright (c) 2015 osb. All rights reserved.
//

#import "Strokes.h"

#define KEY_MAKER(key)                                                              \
CFStringRef Key##key()                                                              \
{                                                                                   \
    static CFStringRef stringKey = 0;                                               \
    static dispatch_once_t onceToken;                                               \
    dispatch_once(&onceToken, ^{                                                    \
        stringKey = CFStringCreateWithCString(NULL, #key, kCFStringEncodingASCII);  \
    });                                                                             \
    return stringKey;                                                               \
}

KEY_MAKER(LineWidth)
KEY_MAKER(LineColor)
KEY_MAKER(StartNew)
KEY_MAKER(X)
KEY_MAKER(Y)
KEY_MAKER(MinX)
KEY_MAKER(MinY)
KEY_MAKER(MaxX)
KEY_MAKER(MaxY)
KEY_MAKER(Points)
KEY_MAKER(Strokes)

CGPoint midPoint(CGPoint p1, CGPoint p2) {
    return CGPointMake((p1.x + p2.x) * 0.5, (p1.y + p2.y) * 0.5);
}

StrokePoint StrokePointMake(CGPoint location, CGFloat timestamp)
{
    StrokePoint out;
    out.location = location;
    out.timestamp = timestamp;
    return out;
}

CGFloat CFNumberToFloat(CFNumberRef numberRef, CGFloat defaultValue)
{
	CGFloat out = defaultValue;
	if (!numberRef)
		return defaultValue;
	if (!CFNumberGetValue(numberRef, CFNumberGetType(numberRef), &out))
		out = defaultValue;
	return out;
}


Stroke *StrokeNew()
{
    Stroke *out = calloc(1, sizeof(Stroke));
    StrokeInit(out);
    NSLog(@"Created Stroke: %p", out);
    return out;
}

void StrokeInit(Stroke *stroke)
{
    bzero(stroke, sizeof(Stroke));
    stroke->points = LinkedListNew();
    stroke->pathRef = CGPathCreateMutable();
    stroke->lineWidth = DEFAULT_LINE_WIDTH;
    stroke->lineColor = DEFAULT_LINE_COLOR.CGColor;
    stroke->minX = INT_MAX;
    stroke->minY = INT_MAX;
    stroke->maxX = -INT_MAX;
    stroke->maxY = -INT_MAX;
}

void StrokeClear(Stroke *stroke)
{
    if (stroke)
    {
        LinkedListRelease(stroke->points, nil);
        stroke->points = 0;
        CGPathRelease(stroke->pathRef);
        stroke->pathRef = 0;
    }
}

void StrokeRelease(Stroke *stroke)
{
    StrokeClear(stroke);
    if (stroke)
        free(stroke);
}

StrokePoint *StrokeAddPoint(Stroke *stroke, CGPoint point, CGFloat timestamp, BOOL newSubpath)
{
    // only add if new point or if distance is at least certain distance away
    CGPoint currentPoint = point;
    CGPoint previousPoint = point;
    CGPoint previousPreviousPoint = point;
    if (!StrokeIsEmpty(stroke) && !newSubpath)
    {
        StrokePoint *lastPoint = LinkedListNodeData(LinkedListTail(stroke->points));

        // if the finger has moved less than the min dist ...
        CGFloat dx = point.x - lastPoint->location.x;
        CGFloat dy = point.y - lastPoint->location.y;

        if ((dx * dx + dy * dy) < kPointMinDistanceSquared) {
            // ... then ignore this movement
            return NULL;
        }
    }

    // get the last 2 points that we have been adding so far
    if (!newSubpath)
    {
        LinkedListNode *previousNode = LinkedListTail(stroke->points);
        if (previousNode)
        {
            StrokePoint *prevStrokePoint = LinkedListNodeData(previousNode);
            previousPreviousPoint = previousPoint = prevStrokePoint->location;

            if (!prevStrokePoint->startNewSubpath)
            {
                LinkedListNode *previousPreviousNode = LinkedListNodePrev(previousNode);
                if (previousPreviousNode)
                {
                    prevStrokePoint = LinkedListNodeData(previousPreviousNode);
                    previousPreviousPoint = prevStrokePoint->location;
                }
            }
        }
    }

    // update points: previousPrevious -> mid1 -> previous -> mid2 -> current
    CGPoint mid1 = midPoint(previousPoint, previousPreviousPoint);
    CGPoint mid2 = midPoint(currentPoint, previousPoint);

    StrokePoint *newPoint = LinkedListAddObject(stroke->points, sizeof(StrokePoint));
    newPoint->location = point;
    newPoint->timestamp = timestamp;
    newPoint->startNewSubpath = newSubpath;

    // to represent the finger movement, create a new path segment,
    // a quadratic bezier path from mid1 to mid2, using previous as a control point
    CGMutablePathRef subpath = CGPathCreateMutable();
    CGPathMoveToPoint(subpath, NULL, mid1.x, mid1.y);
    CGPathAddQuadCurveToPoint(subpath, NULL, previousPoint.x, previousPoint.y, mid2.x, mid2.y);

    // compute the rect containing the new segment plus padding for drawn line
    CGRect bounds = CGPathGetBoundingBox(subpath);
    CGRect drawBox = CGRectInset(bounds, -2.0 * stroke->lineWidth, -2.0 * stroke->lineWidth);
    if (drawBox.origin.x < stroke->minX)
        stroke->minX = drawBox.origin.x;
    if (drawBox.origin.y < stroke->minY)
        stroke->minY = drawBox.origin.y;
    if (drawBox.origin.x + drawBox.size.width > stroke->maxX)
        stroke->maxX = drawBox.origin.x + drawBox.size.width;
    if (drawBox.origin.y + drawBox.size.height > stroke->maxY)
        stroke->maxY = drawBox.origin.y + drawBox.size.height;

    // append the quad curve to the accumulated path so far.
    CGPathAddPath(stroke->pathRef, NULL, subpath);
    CGPathRelease(subpath);

    return newPoint;
}

BOOL StrokeIsEmpty(Stroke *stroke)
{
    return stroke == NULL || stroke->points == NULL || LinkedListHead(stroke->points) == NULL;
}

void StrokeSetLineColor(Stroke *stroke, CGColorRef newColor)
{
    if (stroke && stroke->lineColor != newColor)
    {
        CGColorRelease(stroke->lineColor);
        stroke->lineColor = newColor;
        CGColorRetain(newColor);
    }
}

StrokeList *StrokeListNew()
{
    StrokeList *out = calloc(1, sizeof(StrokeList));
    out->strokes = LinkedListNew();
    return out;
}

void StrokeListClear(StrokeList *sl)
{
    if (sl)
    {
        LinkedListRelease(sl->strokes, ^(void *stroke, NSInteger index) {
            StrokeClear((Stroke *)stroke);
        });
        sl->strokes = LinkedListNew();
        sl->currentStroke = NULL;
    }
}

void StrokeListRelease(StrokeList *sl)
{
	StrokeListClear(sl);
	if (sl)
		free(sl);
}

void StrokeListStartNewStroke(StrokeList *strokeList, CGColorRef lineColor, CGFloat lineWidth)
{
    if (lineWidth <= 0)
        lineWidth = DEFAULT_LINE_WIDTH;
    if (lineColor == 0)
        lineColor = DEFAULT_LINE_COLOR.CGColor;
    // only add a new stroke if the current stroke is *not* empty
    if (strokeList->currentStroke == NULL || !StrokeIsEmpty(strokeList->currentStroke))
    {
        strokeList->currentStroke = LinkedListAddObject(strokeList->strokes, sizeof(Stroke));
        strokeList->currentStroke->points = LinkedListNew();
        strokeList->currentStroke->pathRef = CGPathCreateMutable();
    }
    strokeList->currentStroke->lineWidth = lineWidth;
    StrokeSetLineColor(strokeList->currentStroke, lineColor);
}

void StrokeListDraw(StrokeList *strokeList, CGContextRef context, CGFloat alpha)
{
    if (!strokeList)
        return ;
    
    LinkedListIterate(strokeList->strokes, ^(void *obj, NSUInteger idx, BOOL *stop) {
        Stroke *stroke = obj;
        CGContextSetLineWidth(context, stroke->lineWidth);
        CGColorRef lineColor = stroke->lineColor;
        if (alpha > 0)  // needs alpha dimming
        {
            size_t numComponents = CGColorGetNumberOfComponents(stroke->lineColor);
            const CGFloat *comps = CGColorGetComponents(stroke->lineColor);
            UIColor *color = nil;
            if (numComponents == 2)
            {
                color = [UIColor colorWithRed:comps[0] green:comps[0] blue:comps[0] alpha:alpha];
            } else
            {
                color = [UIColor colorWithRed:comps[0] green:comps[1] blue:comps[2] alpha:alpha];
            }
            lineColor = color.CGColor;
        }
        CGContextSetStrokeColorWithColor(context, lineColor);
        CGContextSetLineCap(context, kCGLineCapRound);
        CGContextAddPath(context, stroke->pathRef);
        CGContextStrokePath(context);
    });
}

void CFDataAppendString(CFMutableDataRef dataRef, const char *str)
{
    size_t len = strlen(str);
    CFDataAppendBytes(dataRef, (const UInt8 *)str, len);
}

void CFDataAppendInteger(CFMutableDataRef dataRef, NSInteger value)
{
    char buffer[32];
    sprintf(buffer, "%ld", (long)value);
    CFDataAppendString(dataRef, buffer);
}

void CFDataAppendFloat(CFMutableDataRef dataRef, CGFloat value, int numPlaces)
{
    char format[32];
    sprintf(format, "%%.%df", numPlaces);
    char buffer[32];
    sprintf(buffer, format, value);
    CFDataAppendString(dataRef, buffer);
}

/**
 * Serialize a stroke list and return the data ref.
 * The data ref object must be CFRelease-ed after it is used.
 * TODO: send in a "protocol" object so we can do any format instead of hardcoding one here
 */
void StrokeListSerialize(StrokeList *strokeList, CFMutableDataRef dataRef)
{
    if (strokeList == NULL || dataRef == NULL)
        return ;

	CGFloat minX = INT_MAX;
	CGFloat minY = INT_MAX;
	CGFloat maxX = -INT_MAX;
	CGFloat maxY = -INT_MAX;
    CFDataAppendString(dataRef, "{\"Strokes\": [");
    LinkedListIterate(strokeList->strokes, ^(void *obj, NSUInteger idx, BOOL *stop) {
        Stroke *stroke = obj;
        if (idx > 0)
        {
            CFDataAppendString(dataRef, ",");
        }
        StrokeSerialize(stroke, dataRef);
		if (stroke->minX < minX)
			minX = stroke->minX
		if (stroke->minY < minY)
			minY = stroke->minY
		if (stroke->maxX > maxX)
			maxX = stroke->maxX
		if (stroke->maxY > maxY)
			maxY = stroke->maxY
    });
    CFDataAppendString(dataRef, "]");

    // Write the bounding box
    CFDataAppendString(dataRef, ",\"MinX\":");
    CFDataAppendFloat(dataRef, minX, 2);
    CFDataAppendString(dataRef, ",\"MinY\":");
    CFDataAppendFloat(dataRef, minY, 2);
    CFDataAppendString(dataRef, ",\"MaxX\":");
    CFDataAppendFloat(dataRef, maxX, 2);
    CFDataAppendString(dataRef, ",\"MaxY\":");
    CFDataAppendFloat(dataRef, maxY, 2);
	
	// Finish
    CFDataAppendString(dataRef, "}");
}

void StrokeSerialize(Stroke *stroke, CFMutableDataRef dataRef)
{
    CFDataAppendString(dataRef, "{");

    CFDataAppendString(dataRef, "\"LineWidth\":");
    CFDataAppendFloat(dataRef, stroke->lineWidth, 2);

    CFDataAppendString(dataRef, ",\"LineColor\":");
    CFDataAppendString(dataRef, "[");
    size_t numComponents = CGColorGetNumberOfComponents(stroke->lineColor);
    const CGFloat *colorComps = CGColorGetComponents(stroke->lineColor);
    for (int i = 0;i < numComponents;i++)
    {
        if (i > 0)
            CFDataAppendString(dataRef, ",");
        CFDataAppendFloat(dataRef, colorComps[i], 3);
    }
    CFDataAppendString(dataRef, "]");

    // Write the bounding box
    CFDataAppendString(dataRef, ",\"MinX\":");
    CFDataAppendFloat(dataRef, stroke->minX, 2);
    CFDataAppendString(dataRef, ",\"MinY\":");
    CFDataAppendFloat(dataRef, stroke->minY, 2);
    CFDataAppendString(dataRef, ",\"MaxX\":");
    CFDataAppendFloat(dataRef, stroke->maxX, 2);
    CFDataAppendString(dataRef, ",\"MaxY\":");
    CFDataAppendFloat(dataRef, stroke->maxY, 2);

    // Write the points for each stroke now
    CFDataAppendString(dataRef, ",\"Points\":");
    CFDataAppendString(dataRef, "[");
    LinkedListIterate(stroke->points, ^(void *obj, NSUInteger idx, BOOL *stop) {
        StrokePoint *point = obj;
        if (idx > 0)
            CFDataAppendString(dataRef, ",");
        StrokePointSerialize(point, dataRef);
    });
    CFDataAppendString(dataRef, "]");
    CFDataAppendString(dataRef, "}");
}

void StrokePointSerialize(StrokePoint *point, CFMutableDataRef dataRef)
{
    CFDataAppendString(dataRef, "{");
    CFDataAppendString(dataRef, "\"X\":");
    CFDataAppendFloat(dataRef, point->location.x, 2);
    CFDataAppendString(dataRef, ",\"Y\":");
    CFDataAppendFloat(dataRef, point->location.y, 2);
    if (point->startNewSubpath)
        CFDataAppendString(dataRef, ",\"StartNew\":true");
   CFDataAppendString(dataRef, "}");
}

/**
 * Deserialize a stroke list from a list object.
 */
CFErrorRef StrokeListDeserialize(CFDictionaryRef dict, StrokeList *strokeList)
{
    if (dict != NULL)
    {
        CFArrayRef strokesObj = CFDictionaryGetValue(dict, KeyStrokes());
        CFIndex count = CFArrayGetCount(strokesObj);
        for (int i = 0;i < count;i++)
        {
            StrokeListStartNewStroke(strokeList, 0, 0);

            CFDictionaryRef strokeDict = CFArrayGetValueAtIndex(strokesObj, i);
            StrokeDeserialize(strokeDict, strokeList->currentStroke);
        }
    }
    return NULL;
}

/**
 * Deserialize a stroke from a dictionary of its attribute values.
 */
CFErrorRef StrokeDeserialize(CFDictionaryRef dict, Stroke *stroke)
{
    if (dict != NULL)
    {
        CFNumberRef lineWidthObj = CFDictionaryGetValue(dict, KeyLineWidth());
        CFArrayRef lineColorObj = CFDictionaryGetValue(dict, KeyLineColor());
        CFNumberRef minXObj = CFDictionaryGetValue(dict, KeyMinX());
        CFNumberRef minYObj = CFDictionaryGetValue(dict, KeyMinY());
        CFNumberRef maxXObj = CFDictionaryGetValue(dict, KeyMaxX());
        CFNumberRef maxYObj = CFDictionaryGetValue(dict, KeyMaxY());
        CFArrayRef pointsObj = CFDictionaryGetValue(dict, KeyPoints());

		stroke->lineWidth = CFNumberToFloat(lineWidthObj, DEFAULT_LINE_WIDTH);
		stroke->minX = CFNumberToFloat(minXObj, INT_MAX);
		stroke->minY = CFNumberToFloat(minYObj, INT_MAX);
		stroke->maxX = CFNumberToFloat(maxXObj, -INT_MAX);
		stroke->maxY = CFNumberToFloat(maxYObj, -INT_MAX);

        CFIndex numColors = CFArrayGetCount(lineColorObj);
		if (numColors == 2)
		{
			CFNumberRef color = CFArrayGetValueAtIndex(lineColorObj, 0);
			CFNumberRef alpha = CFArrayGetValueAtIndex(lineColorObj, 1);
			CGFloat colorValue = CFNumberToFloat(color, 0);
			CGFloat alphaValue = CFNumberToFloat(alpha, 1);
			UIColor *uiColor = [UIColor colorWithRed:colorValue green:colorValue blue:colorValue alpha:alphaValue];
			StrokeSetLineColor(stroke, uiColor.CGColor);
		} else if (numColors == 4)
		{
			CFNumberRef red = CFArrayGetValueAtIndex(lineColorObj, 0);
			CFNumberRef green = CFArrayGetValueAtIndex(lineColorObj, 1);
			CFNumberRef blue = CFArrayGetValueAtIndex(lineColorObj, 2);
			CFNumberRef alpha = CFArrayGetValueAtIndex(lineColorObj, 3);

			CGFloat redValue = CFNumberToFloat(red, 0);
			CGFloat greenValue = CFNumberToFloat(green, 0);
			CGFloat blueValue = CFNumberToFloat(blue, 0);
			CGFloat alphaValue = CFNumberToFloat(alpha, 1);

			UIColor *uiColor = [UIColor colorWithRed:redValue green:greenValue blue:blueValue alpha:alphaValue];
			StrokeSetLineColor(stroke, uiColor.CGColor);
		}

        CFIndex numPoints = CFArrayGetCount(pointsObj);
        for (int i = 0;i < numPoints;i++)
        {
            CFDictionaryRef pointDict = CFArrayGetValueAtIndex(pointsObj, i);
			StrokePoint point;

			StrokePointDeserialize(pointDict, &point);
			StrokeAddPoint(stroke, point.location, point.timestamp, point.startNewSubpath);
        }
    }
    return NULL;
}

/**
 * Deserialize a stroke point from a dictionary of its attribute values.
 */
CFErrorRef StrokePointDeserialize(CFDictionaryRef dict, StrokePoint *point)
{
    if (dict != NULL)
    {
        CFNumberRef xObj = CFDictionaryGetValue(dict, KeyX());
        CFNumberRef yObj = CFDictionaryGetValue(dict, KeyY());
        CFNumberRef startNewObj = CFDictionaryGetValue(dict, KeyStartNew());
		point->location.x = CFNumberToFloat(xObj, 0);
		point->location.y = CFNumberToFloat(yObj, 0);
		point->startNewSubpath = NO;

		if (startNewObj)
		{
			CFNumberGetValue(startNewObj, CFNumberGetType(startNewObj), &point->startNewSubpath);
		}
    }
    return NULL;
}
