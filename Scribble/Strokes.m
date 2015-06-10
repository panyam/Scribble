//
//  Strokes.m
//  Salmon
//
//  Created by Sri Panyam on 4/06/2015.
//  Copyright (c) 2015 osb. All rights reserved.
//

#import "Strokes.h"

CGPoint midPoint(CGPoint p1, CGPoint p2) {
    return CGPointMake((p1.x + p2.x) * 0.5, (p1.y + p2.y) * 0.5);
}

StrokePoint StrokePointMake(CGPoint location, CGFloat createdAt)
{
    StrokePoint out;
    out.location = location;
    out.createdAt = createdAt;
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

StrokePoint *StrokeAddPoint(Stroke *stroke, CGPoint point, CGFloat createdAt, BOOL newSubpath)
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
    newPoint->createdAt = createdAt;
    newPoint->startNewSubpath = newSubpath;

    // to represent the finger movement, create a new path segment,
    // a quadratic bezier path from mid1 to mid2, using previous as a control point
    CGMutablePathRef subpath = CGPathCreateMutable();
    CGPathMoveToPoint(subpath, NULL, mid1.x, mid1.y);
    CGPathAddQuadCurveToPoint(subpath, NULL, previousPoint.x, previousPoint.y, mid2.x, mid2.y);

    // compute the rect containing the new segment plus padding for drawn line
//    CGRect bounds = CGPathGetBoundingBox(subpath);

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

void StrokeListStartNewStroke(StrokeList *strokeList, UIColor *lineColor, CGFloat lineWidth)
{
    if (lineWidth <= 0)
        lineWidth = DEFAULT_LINE_WIDTH;
    if (lineColor == nil)
        lineColor = DEFAULT_LINE_COLOR;
    // only add a new stroke if the current stroke is *not* empty
    if (strokeList->currentStroke == NULL || !StrokeIsEmpty(strokeList->currentStroke))
    {
        strokeList->currentStroke = LinkedListAddObject(strokeList->strokes, sizeof(Stroke));
        strokeList->currentStroke->points = LinkedListNew();
        strokeList->currentStroke->pathRef = CGPathCreateMutable();
    }
    strokeList->currentStroke->lineWidth = lineWidth;
    StrokeSetLineColor(strokeList->currentStroke, lineColor.CGColor);
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