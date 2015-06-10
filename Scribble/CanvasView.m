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

    BOOL inPlaybackMode;                // Whether we are in playback mode
    BOOL playbackPaused;                // If in playback mode, whether we are paused
    LinkedListIterator *strokeIterator;
    LinkedListIterator *pointIterator;
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
    LinkedListIteratorRelease(strokeIterator);
    LinkedListIteratorRelease(pointIterator);
    StrokeListRelease(currStrokeList);
}

-(void)clear {
    LinkedListIteratorRelease(strokeIterator);
    LinkedListIteratorRelease(pointIterator);
    strokeIterator = pointIterator = NULL;

    StrokeListClear(currStrokeList);

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
        LinkedListIteratorRelease(strokeIterator);
        LinkedListIteratorRelease(pointIterator);
        strokeIterator = pointIterator = NULL;
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
//        StrokeListClear(playbackStrokeList);
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

    NSLog(@"Touch Began: PrevPrev: (%f, %f), Prev: (%f, %f), Curr: (%f, %f)", previousPreviousPoint.x
          , previousPreviousPoint.y, previousPoint.x, previousPoint.y, currentPoint.x, currentPoint.y);
    StrokeAddPoint(currStrokeList->currentStroke, currentPoint, touch.timestamp, YES);
//
//    // call touchesMoved:withEvent:, to possibly draw on zero movement
    [self touchesMoved:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if (inPlaybackMode)
        return ;
    UITouch *touch = [touches anyObject];

    CGPoint point = [touch locationInView:self];
    previousPreviousPoint = previousPoint;
    previousPoint = [touch previousLocationInView:self];
    currentPoint = [touch locationInView:self];

//    CGPoint mid1 = midPoint(previousPoint, previousPreviousPoint);
//    CGPoint mid2 = midPoint(currentPoint, previousPoint);
    // add the point to the current stroke
    StrokeAddPoint(currStrokeList->currentStroke, point, touch.timestamp, NO);
    
    [self setNeedsDisplay];
//    [self setNeedsDisplayInRect:drawBox];
}

-(void)incrementPlaybackPosition
{
    NSLog(@"Incrementing Position");
//    if (currPlaybackStrokeNode == NULL)
//    {
//        currPlaybackStrokeNode = LinkedListHead(currStrokeList->strokes);
//    }
//
//    if (currPlaybackStrokeNode == NULL)
//    {
//        return ;
//    }
//
//    if (currPlaybackStrokeNode == NULL)
//    {
//        currPlaybackStrokeNode = LinkedListHead(currPlaybackStrokeNode);
//    }
//
//    if (currPlaybackStrokeNode == NULL)
//    {
//        return ;
//    }
//
//    else {
//        currPlaybackPointNode = LinkedListNodeNext(currPlaybackPointNode);
//        if (currPlaybackPointNode != NULL)
//        {
//            [self setNeedsDisplay];
//            return ;
//        }
//
//        // next point is NULL so start the next path
//        currPlaybackStrokeNode = LinkedListNodeNext(currPlaybackStrokeNode);
//        if (currPlaybackStrokeNode == NULL)
//        {
//            // we have reached the end so stop
//            [self stopPlaying:YES];
//            return ;
//        }
//    }
//
//    // Start of the current stroke/path so set the head as the first point
//    Stroke *currPlaybackStroke = (Stroke *)LinkedListNodeData(currPlaybackStrokeNode);
//    currPlaybackPointNode = LinkedListHead(currPlaybackStroke->points);

    // TODO: add the point to the accumulating path

    [self setNeedsDisplay];
}

@end
