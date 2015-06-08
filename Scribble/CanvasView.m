//
//  CanvasView.m
//  Salmon
//
//  Created by Sri Panyam on 4/06/2015.
//  Copyright (c) 2015 osb. All rights reserved.
//

#import "CanvasView.h"
#import "Strokes.h"
#import <QuartzCore/QuartzCore.h>

#pragma mark Private Helper function

static const CGFloat kPointMinDistance = 5.0f;
static const CGFloat kPointMinDistanceSquared = kPointMinDistance * kPointMinDistance;

#pragma mark private Helper function

CGPoint midPoint(CGPoint p1, CGPoint p2) {
    return CGPointMake((p1.x + p2.x) * 0.5, (p1.y + p2.y) * 0.5);
}

@interface CanvasView()

@property (nonatomic, strong) UIColor *currLineColor;
@property (nonatomic) CGFloat currLineWidth;
@property (nonatomic, strong) NSTimer *playerTimer;
@end

@implementation CanvasView {
@private
    CGPoint currentPoint;
    CGPoint previousPoint;
    CGPoint previousPreviousPoint;
    StrokeList *currStrokeList;

    BOOL inPlaybackMode;            // Whether we are in playback mode
    BOOL playbackPaused;            // If in playback mode, whether we are paused
    StrokeList *playbackStrokeList;
    LinkedListNode *currPlaybackStrokeNode;     // The current stroke which is being played back
    LinkedListNode *currPlaybackPointNode;      // The current point within the stroke being played back
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];

    if (self) {
        // NOTE: do not change the backgroundColor here, so it can be set in IB.
        [self initCommon];
    }

    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        [self initCommon];
    }

    return self;
}

-(void)initCommon
{
    self.currLineColor = DEFAULT_LINE_COLOR;
    self.currLineWidth = DEFAULT_LINE_WIDTH;
    currStrokeList = StrokeListNew();
    [self clear];
}

-(void)dealloc {
    StrokeListRelease(currStrokeList);
    StrokeListRelease(playbackStrokeList);
}

-(void)clear {
    StrokeListClear(currStrokeList);
    StrokeListClear(playbackStrokeList);
    [self startNewStrokeWithColor:self.currLineColor withWidth:self.currLineWidth];
}

-(void)removeFromSuperview
{
    [self stopPlaying:NO];
    [super removeFromSuperview];
}

-(void)startPlaying:(BOOL)restart {
    NSLog(@"Starting Playback, Restarting: %@", restart ? @"YES" : @"NO");
    [self.playerTimer invalidate];
    self.playerTimer = nil;
    if (restart)
    {
        currPlaybackStrokeNode = LinkedListHead(currStrokeList->strokes);
        Stroke *currPlaybackStroke = (Stroke *)LinkedListNodeData(currPlaybackStrokeNode);
        currPlaybackPointNode = LinkedListHead(currPlaybackStroke->points);
    }
    inPlaybackMode = YES;
    self.playerTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                        target:self
                                                      selector:@selector(incrementPlaybackPosition)
                                                      userInfo:nil
                                                       repeats:YES];
}

-(void)stopPlaying:(BOOL)finish {
    NSLog(@"Stopping Playback, Finishing: %@", finish ? @"YES" : @"NO");
    [self.playerTimer invalidate];
    self.playerTimer = nil;
    if (finish)
    {
        inPlaybackMode = NO;
        StrokeListClear(playbackStrokeList);
    } else {
        playbackPaused = YES;
    }
    [self setNeedsDisplay];
}

-(void)startNewStrokeWithColor:(UIColor *)lineColor withWidth:(CGFloat)lineWidth
{
    if (lineWidth > 0)
        self.currLineWidth = lineWidth;
    if (self.currLineWidth < 0)
        self.currLineWidth = DEFAULT_LINE_WIDTH;
    if (self.currLineColor == nil)
        self.currLineColor = DEFAULT_LINE_COLOR;
    if (lineColor != nil)
        self.currLineColor = lineColor;
    StrokeListStartNewStroke(currStrokeList, self.currLineColor, self.currLineWidth);
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    // clear rect
    [self.backgroundColor set];
    UIRectFill(rect);

    // get the graphics context and draw the path
    CGContextRef context = UIGraphicsGetCurrentContext();
    LinkedListIterate(currStrokeList->strokes, ^(void *obj, NSUInteger idx, BOOL *stop) {
        Stroke *stroke = obj;
        CGContextSetLineWidth(context, stroke->lineWidth);
        CGContextSetStrokeColorWithColor(context, stroke->lineColor);
        CGContextSetLineCap(context, kCGLineCapRound);
        CGContextAddPath(context, stroke->pathRef);
        CGContextStrokePath(context);
    });
}

#pragma mark Touch event handlers

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if (inPlaybackMode)
        return ;
    UITouch *touch = [touches anyObject];

    // initializes our point records to current location
    previousPoint = [touch previousLocationInView:self];
    previousPreviousPoint = [touch previousLocationInView:self];
    currentPoint = [touch locationInView:self];

    StrokeAddPoint(currStrokeList->currentStroke, currentPoint, touch.timestamp);

    // call touchesMoved:withEvent:, to possibly draw on zero movement
    [self touchesMoved:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if (inPlaybackMode)
        return ;
    UITouch *touch = [touches anyObject];

    CGPoint point = [touch locationInView:self];

    // if the finger has moved less than the min dist ...
    CGFloat dx = point.x - currentPoint.x;
    CGFloat dy = point.y - currentPoint.y;

    if ((dx * dx + dy * dy) < kPointMinDistanceSquared) {
        // ... then ignore this movement
        return;
    }

    // add the point to the current stroke
    StrokeAddPoint(currStrokeList->currentStroke, point, touch.timestamp);

    // update points: previousPrevious -> mid1 -> previous -> mid2 -> current
    previousPreviousPoint = previousPoint;
    previousPoint = [touch previousLocationInView:self];
    currentPoint = [touch locationInView:self];

    CGPoint mid1 = midPoint(previousPoint, previousPreviousPoint);
    CGPoint mid2 = midPoint(currentPoint, previousPoint);

    // to represent the finger movement, create a new path segment,
    // a quadratic bezier path from mid1 to mid2, using previous as a control point
    CGMutablePathRef subpath = CGPathCreateMutable();
    CGPathMoveToPoint(subpath, NULL, mid1.x, mid1.y);
    CGPathAddQuadCurveToPoint(subpath, NULL, previousPoint.x, previousPoint.y, mid2.x, mid2.y);

    // compute the rect containing the new segment plus padding for drawn line
    CGRect bounds = CGPathGetBoundingBox(subpath);
    CGRect drawBox = CGRectInset(bounds,
                                 -2.0 * currStrokeList->currentStroke->lineWidth,
                                 -2.0 * currStrokeList->currentStroke->lineWidth);

    // append the quad curve to the accumulated path so far.
    CGPathAddPath(currStrokeList->currentStroke->pathRef, NULL, subpath);
    CGPathRelease(subpath);
    
    [self setNeedsDisplayInRect:drawBox];
}

-(void)incrementPlaybackPosition
{
    NSLog(@"Incrementing Position");
    if (currPlaybackStrokeNode == NULL)
    {
        currPlaybackStrokeNode = LinkedListHead(currStrokeList->strokes);
    } else {
        currPlaybackPointNode = LinkedListNodeNext(currPlaybackPointNode);
        if (currPlaybackPointNode != NULL)
        {
            [self setNeedsDisplay];
            return ;
        }

        // next point is NULL so start the next path
        currPlaybackStrokeNode = LinkedListNodeNext(currPlaybackStrokeNode);
        if (currPlaybackStrokeNode == NULL)
        {
            // we have reached the end so stop
            [self stopPlaying:YES];
            return ;
        }
    }

    // Start of the current stroke/path so set the head as the first point
    Stroke *currPlaybackStroke = (Stroke *)LinkedListNodeData(currPlaybackStrokeNode);
    currPlaybackPointNode = LinkedListHead(currPlaybackStroke->points);

    // TODO: add the point to the accumulating path

    [self setNeedsDisplay];
}

@end
