//
//  Strokes.h
//  Salmon
//
//  Created by Sri Panyam on 4/06/2015.
//  Copyright (c) 2015 osb. All rights reserved.
//

#ifndef __STROKES_H__
#define __STROKES_H__

#import "LinkedList.h"
#import <UIKit/UIKit.h>

#define DEFAULT_LINE_WIDTH  5.0
#define DEFAULT_LINE_COLOR  UIColor.blackColor


/**
 * Each stroke point contains the location where the a point was registered
 * and the time at which it was registered.
 */
typedef struct StrokePoint {
    CGPoint location;
    CGFloat createdAt;
    BOOL restartsStroke;
} StrokePoint;

/**
 * A stroke consists of a set of points along with the color, width and other attributes of the stroke.
 */
typedef struct Stroke {
    LinkedList *points;
    CGMutablePathRef pathRef;
    CGColorRef lineColor;
    CGFloat lineWidth;
} Stroke;

extern StrokePoint StrokePointMake(CGPoint location, CGFloat createdAt);

extern Stroke *StrokeNew();
extern void StrokeInit(Stroke *stroke);
extern BOOL StrokeIsEmpty(Stroke *stroke);
extern StrokePoint *StrokeAddPoint(Stroke *stroke, CGPoint location, CGFloat createdAt);
extern void StrokeRelease(Stroke *head);
extern void StrokeSetLineColor(Stroke *stroke, CGColorRef newColor);
extern void StrokeClear(Stroke *stroke);


typedef struct StrokeList {
    LinkedList *strokes;
    Stroke *currentStroke;
} StrokeList;

extern StrokeList *StrokeListNew();
extern void StrokeListClear(StrokeList *strokes);
extern void StrokeListRelease(StrokeList *strokes);
extern void StrokeListStartNewStroke(StrokeList *strokes, UIColor *lineColor, CGFloat lineWidth);

#endif