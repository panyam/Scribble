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
    Stroke *out = malloc(sizeof(Stroke));
    bzero(out, sizeof(Stroke));
    out->points = LinkedListNew();
    out->pathRef = CGPathCreateMutable();
    out->lineWidth = DEFAULT_LINE_WIDTH;
    out->lineColor = DEFAULT_LINE_COLOR.CGColor;
    return out;
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

void StrokeRelease(Stroke *stroke)
{
    if (stroke)
    {
        LinkedListRelease(stroke->points, NULL);
        CGPathRelease(stroke->pathRef);
        free(stroke);
    }
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
        sl->currentStroke = NULL;
    }
}

void StrokeListRelease(StrokeList *sl)
{
    StrokeListClear(sl);
    free(sl);
}

void StrokeListStartNewStroke(StrokeList *strokes, UIColor *lineColor, CGFloat lineWidth)
{
    if (lineWidth <= 0)
        lineWidth = DEFAULT_LINE_WIDTH;
    if (lineColor == nil)
        lineColor = DEFAULT_LINE_COLOR;
    // only add a new stroke if the current stroke is *not* empty
    if (strokes->currentStroke == NULL || !StrokeIsEmpty(strokes->currentStroke))
    {
        strokes->currentStroke = LinkedListAddObject(strokes->strokes, sizeof(Stroke));
        strokes->currentStroke->points = LinkedListNew();
        strokes->currentStroke->pathRef = CGPathCreateMutable();
    }
    strokes->currentStroke->lineWidth = lineWidth;
    StrokeSetLineColor(strokes->currentStroke, lineColor.CGColor);
}
