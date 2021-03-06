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

static const CGFloat kPointMinDistance = 5.0f;
static const CGFloat kPointMinDistanceSquared = kPointMinDistance * kPointMinDistance;


/**
 * Each stroke point contains the location where the a point was registered
 * and the time at which it was registered.
 */
typedef struct StrokePoint {
    CGPoint location;
    CGFloat timestamp;
    BOOL startNewSubpath;
} StrokePoint;

/**
 * A stroke consists of a set of points along with the color, width and other attributes of the stroke.
 */
typedef struct Stroke {
    LinkedList *points;
    CGMutablePathRef pathRef;
    CGFloat lineWidth;
    CGFloat red, green, blue, alpha;
    CGFloat minX, minY, maxX, maxY;
} Stroke;

extern StrokePoint StrokePointMake(CGPoint location, CGFloat createdAt);

extern Stroke *StrokeNew();
extern void StrokeInit(Stroke *stroke);
extern BOOL StrokeIsEmpty(Stroke *stroke);
extern StrokePoint *StrokeAddPoint(Stroke *stroke, CGPoint location, CGFloat createdAt, BOOL newSubpath);
extern void StrokeRelease(Stroke *head);
extern void StrokeSetLineColor(Stroke *stroke, CGFloat red, CGFloat green, CGFloat blue, CGFloat alpha);
extern void StrokeClear(Stroke *stroke);
//extern void StrokeRefresh(Stroke *stroke);

typedef struct StrokeList {
    LinkedList *strokes;
    Stroke *currentStroke;
    CGFloat minX, minY, maxX, maxY;
	CGFloat maxLineWidth;
    CGFloat bgRed, bgGreen, bgBlue, bgAlpha;
} StrokeList;

extern StrokeList *StrokeListNew();
extern NSInteger StrokeListSize(StrokeList *strokes);
extern void StrokeListClear(StrokeList *strokes);
extern void StrokeListRelease(StrokeList *strokes);
extern void StrokeListStartNewStroke(StrokeList *strokeList, CGFloat lineWidth,
                                     CGFloat red, CGFloat green, CGFloat blue, CGFloat alpha);
extern void StrokeListDraw(StrokeList *list, CGContextRef context, CGFloat alpha, CGPoint translateBy);
extern void StrokeListDetectBounds(StrokeList *strokes);
extern void StrokeListTranslate(StrokeList *strokes, CGFloat deltaX, CGFloat deltaY);
//extern void StrokeListRefresh(StrokeList *strokes);

/**
 * Serialize a stroke list into a given data buffer.
 */
extern void StrokeListSerialize(StrokeList *strokeList, CFMutableDataRef dataRef);
extern void StrokeSerialize(Stroke *stroke, CFMutableDataRef dataRef);
extern void StrokePointSerialize(StrokePoint *point, CFMutableDataRef dataRef);
//
//extern CFArrayRef StrokeListToArray(StrokeList *strokeList);
//extern CFDictionaryRef StrokeToDict(Stroke *stroke);
//extern CFDictionaryRef StrokePointToDict(StrokePoint *point);

/**
 * Deserialize a stroke list from a list object.
 */
extern CFErrorRef StrokeListDeserialize(CFDictionaryRef dict, StrokeList *strokeList);
/**
 * Deserialize a stroke from a dictionary of its attribute values.
 */
extern CFErrorRef StrokeDeserialize(CFDictionaryRef dict, Stroke *stroke);
/**
 * Deserialize a stroke point from a dictionary of its attribute values.
 */
extern CFErrorRef StrokePointDeserialize(CFDictionaryRef dict, StrokePoint *point);

/**
 * Deserialize a color from components.
 */
extern CFErrorRef ColorDeserialize(CFArrayRef components, CGFloat *red, CGFloat *green, CGFloat *blue, CGFloat *alpha);

#endif
