//
//  Strokes.m
//  Salmon
//
//  Created by Sri Panyam on 4/06/2015.
//  Copyright (c) 2015 osb. All rights reserved.
//

#import "Strokes.h"

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

StrokePoint *StrokeAddPoint(Stroke *stroke, CGPoint location, CGFloat createdAt)
{
    StrokePoint *newPoint = LinkedListAddObject(stroke->points, sizeof(StrokePoint));
    newPoint->location = location;
    newPoint->createdAt = createdAt;
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
