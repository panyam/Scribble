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
    StrokeList *recordedStrokeList;
    StrokeList *playbackStrokeList;

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
    recordedStrokeList = NULL;
    [self clear];
}

-(void)dealloc {
    [self clearPlayback];
    [self clearRecording];
}

-(void)clearRecording
{
    StrokeListRelease(recordedStrokeList);
    recordedStrokeList = NULL;
}

-(void)clearPlayback
{
    LinkedListIteratorRelease(strokeIterator);
    LinkedListIteratorRelease(pointIterator);
    strokeIterator = pointIterator = NULL;
    StrokeListRelease(playbackStrokeList);
    playbackStrokeList = NULL;
}

-(void)clear {
    [self clearPlayback];
    [self clearRecording];
    [self setNeedsDisplay];
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
        [self clearPlayback];
    }
    inPlaybackMode = YES;
    self.playerTimer = [NSTimer scheduledTimerWithTimeInterval:0.02
                                                        target:self
                                                      selector:@selector(advancePlayer)
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
        [self clearPlayback];
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
    if (recordedStrokeList == NULL)
        recordedStrokeList = StrokeListNew();
    StrokeListStartNewStroke(recordedStrokeList, self.currLineColor.CGColor, self.currLineWidth);
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    // clear rect
    [self.backgroundColor set];
    UIRectFill(rect);

    if (inPlaybackMode)
    {
        StrokeListDraw(recordedStrokeList, UIGraphicsGetCurrentContext(), 0.1);
        StrokeListDraw(playbackStrokeList, UIGraphicsGetCurrentContext(), 1);
    } else {
        StrokeListDraw(recordedStrokeList, UIGraphicsGetCurrentContext(), 1);
    }
}

#pragma mark Touch event handlers

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if (!inPlaybackMode)
    {
        if (recordedStrokeList == NULL)
        {
            [self startNewStrokeWithColor:self.currLineColor withWidth:self.currLineWidth];
        }
        UITouch *touch = touches.anyObject;
        CGPoint point  = [touch locationInView:self];
        StrokeAddPoint(recordedStrokeList->currentStroke, point, touch.timestamp, YES);
        [self touchesMoved:touches withEvent:event];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if (!inPlaybackMode)
    {
        UITouch *touch = [touches anyObject];
        CGPoint point = [touch locationInView:self];
        // add the point to the current stroke
        StrokeAddPoint(recordedStrokeList->currentStroke, point, touch.timestamp, NO);
        [self setNeedsDisplay];
    }
}

-(BOOL)advancePlayer
{
    if (recordedStrokeList == NULL)
        return NO;

    NSLog(@"Incrementing Position");
    if (strokeIterator == NULL)
        strokeIterator = LinkedListIteratorNew(recordedStrokeList->strokes);
    if (strokeIterator == NULL)
        return NO;

    Stroke *currStroke = (Stroke *)LinkedListIteratorValue(strokeIterator);
    if (pointIterator == NULL)
        pointIterator = LinkedListIteratorNew(currStroke->points);
    if (pointIterator == NULL)
        return NO;

    if (playbackStrokeList == NULL)
    {
        playbackStrokeList = StrokeListNew();
        StrokeListStartNewStroke(playbackStrokeList, currStroke->lineColor, currStroke->lineWidth);
    }

    // add this point to the playback strokes
    StrokePoint *currPoint = (StrokePoint *)LinkedListIteratorValue(pointIterator);
    StrokeAddPoint(playbackStrokeList->currentStroke, currPoint->location, currPoint->timestamp, currPoint->startNewSubpath);

    // now go forward
    if (!LinkedListIteratorForward(pointIterator))
    {
        if (!LinkedListIteratorForward(strokeIterator))
        {
            [self clearPlayback];
            // no more points AND no more strokes so quit
            return NO;
        } else {
            // next iteration will set the pointIterator again but
            // just start a new stroke
            Stroke *currStroke = (Stroke *)LinkedListIteratorValue(strokeIterator);
            StrokeListStartNewStroke(playbackStrokeList, currStroke->lineColor, currStroke->lineWidth);
            LinkedListIteratorRelease(pointIterator);
            pointIterator = NULL;
        }
    } else {
        // all good
    }

    [self setNeedsDisplay];
    return YES;
}

-(NSArray *)strokeData
{
    CFMutableDataRef dataRef = CFDataCreateMutable(NULL, 0);
    StrokeListSerialize(recordedStrokeList, dataRef);
    NSMutableData *data = (__bridge NSMutableData *)(dataRef);
    NSError *error = nil;
    NSArray *out = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (error)
    {
        NSLog(@"Error: %@", error);
    }
    return out;
}

-(void)setStrokeData:(NSArray *)strokesArray
{
    [self clear];
    if (recordedStrokeList == NULL)
        recordedStrokeList = StrokeListNew();
    StrokeListDeserialize((__bridge CFArrayRef)(strokesArray), recordedStrokeList);
}

@end
