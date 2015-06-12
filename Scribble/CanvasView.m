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
@property (nonatomic) NSInteger currAnimationLoop;
@property (nonatomic) BOOL inPlaybackMode;                // Whether we are in playback mode
@property (nonatomic) BOOL playbackPaused;                // If in playback mode, whether we are paused

@end

@implementation CanvasView {
@private
    StrokeList *recordedStrokeList;
    StrokeList *playbackStrokeList;

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
    self.animationCount = 5;
    self.playbackStrokeAlpha = 0.08;
    self.delayBetweenAnimationLoops = 0.5;
    self.delayBetweenAnimationFrames = 0.025;
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
    CGFloat red, green, blue, alpha;
    [self.currLineColor getRed:&red green:&green blue:&blue alpha:&alpha];
    StrokeListStartNewStroke(recordedStrokeList, self.currLineWidth, red, green, blue, alpha);
    [self setNeedsDisplay];
}

-(void)setTranslateBy:(CGPoint)translateBy_
{
    _translateBy = translateBy_;
    [self setNeedsDisplay];
}

-(NSDictionary *)strokeData
{
    CFMutableDataRef dataRef = CFDataCreateMutable(NULL, 0);
    StrokeListSerialize(recordedStrokeList, dataRef);
    NSMutableData *data = (__bridge NSMutableData *)(dataRef);
    NSError *error = nil;
    NSDictionary *out = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (error)
    {
        NSLog(@"Error: %@", error);
    }
    return out;
}

-(void)setStrokeData:(NSDictionary *)strokesDict
{
    [self clear];
    if (recordedStrokeList == NULL)
        recordedStrokeList = StrokeListNew();
    StrokeListDeserialize((__bridge CFDictionaryRef)(strokesDict), recordedStrokeList);
    StrokeListDetectBounds(recordedStrokeList);
}

#pragma Stroke Animations

-(void)togglePlaying
{
	[self playButtonClicked:self.playButton];
}

-(void)startPlaying:(BOOL)restart {
    [self.playerTimer invalidate];
    self.playerTimer = nil;
    if (restart)
    {
        self.currAnimationLoop = 0;
        [self clearPlayback];
    }
    [self.playButton setTitle:@"Stop" forState:UIControlStateNormal];
    self.inPlaybackMode = YES;
    self.playerTimer = [NSTimer scheduledTimerWithTimeInterval:self.delayBetweenAnimationFrames
                                                        target:self
                                                      selector:@selector(strokeAnimationFrame)
                                                      userInfo:nil
                                                       repeats:YES];
}

-(void)stopPlaying:(BOOL)finish {
    [self.playerTimer invalidate];
    self.playerTimer = nil;
    if (finish)
    {
        self.inPlaybackMode = NO;
        [self clearPlayback];
    } else {
        self.playbackPaused = YES;
    }
    [self.playButton setTitle:@"Play" forState:UIControlStateNormal];
    [self setNeedsDisplay];
}

-(void)strokeAnimationFrame
{
    if (![self advanceStrokeFrame])
    {
        // loop has finished
        [self.playerTimer invalidate];
        self.playerTimer = nil;
        self.currAnimationLoop++;

        if (self.animationCount < 0 || self.currAnimationLoop < self.animationCount)
        {
            // start again
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.delayBetweenAnimationLoops * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self startPlaying:NO];
            });
        } else {
            // animation finished
            [self stopPlaying:YES];
            [self setNeedsDisplay];
        }
    } else {
        // nothing to do
    }
}

-(BOOL)advanceStrokeFrame
{
    if (recordedStrokeList == NULL)
        return NO;

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
        StrokeListStartNewStroke(playbackStrokeList, currStroke->lineWidth,
                                 currStroke->red, currStroke->green, currStroke->blue, currStroke->alpha);
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
            StrokeListStartNewStroke(playbackStrokeList, currStroke->lineWidth,
                                     currStroke>red, currStroke->green, currStroke->blue, currStroke->alpha);
            LinkedListIteratorRelease(pointIterator);
            pointIterator = NULL;
        }
    } else {
        // all good
    }

    [self setNeedsDisplay];
    return YES;
}

#pragma mark Touch event handlers

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if (!self.inPlaybackMode && !self.disableTouches)
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
    if (!self.inPlaybackMode && !self.disableTouches)
    {
        UITouch *touch = [touches anyObject];
        CGPoint point = [touch locationInView:self];
        // add the point to the current stroke
        StrokeAddPoint(recordedStrokeList->currentStroke, point, touch.timestamp, NO);
        [self setNeedsDisplay];
    }
}

#pragma Draw It!

- (void)drawRect:(CGRect)rect {
    // clear rect
    [self.backgroundColor set];
    UIRectFill(rect);

    if (self.inPlaybackMode)
    {
        StrokeListDraw(recordedStrokeList, UIGraphicsGetCurrentContext(), self.playbackStrokeAlpha, self.translateBy);
        StrokeListDraw(playbackStrokeList, UIGraphicsGetCurrentContext(), 1, self.translateBy);
    } else {
        StrokeListDraw(recordedStrokeList, UIGraphicsGetCurrentContext(), 1, self.translateBy);
    }
}

-(IBAction)playButtonClicked:(id)sender
{
    if ([((UIButton *)sender).titleLabel.text isEqualToString:@"Play"])
    {
        [self startPlaying:YES];

        if ([self.canvasDelegate respondsToSelector:@selector(canvasView:startedAnimationLoop:resumed:)])
            [self.canvasDelegate canvasView:self startedAnimationLoop:self.currAnimationLoop resumed:NO];
    } else {
        [self stopPlaying:YES];
        if ([self.canvasDelegate respondsToSelector:@selector(canvasViewAnimationStopped:)])
            [self.canvasDelegate canvasViewAnimationStopped:self];
    }
}

-(IBAction)copyToClipboardClicked
{
    NSDictionary *strokes = [self copyToClipboard];
    if ([self.canvasDelegate respondsToSelector:@selector(canvasView:dataCopied:)])
    {
        [self.canvasDelegate canvasView:self dataCopied:strokes];
    }
    else {
        [[[UIAlertView alloc] initWithTitle:@"Copied" message:@"The strokelist definition has been copied to the simulator's clipboard.  To paste it in the system, press Cmd+C in the simulator (to copy) and then Cmd+V in the mac (to paste)" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
    }
}

-(void)layoutSubviews
{
    CGRect bounds = self.bounds;
    CGRect playButtonBounds = self.playButton.bounds;
    CGRect copyButtonBounds = self.toClipboardButton.bounds;

    CGFloat yOffset = (bounds.size.height - playButtonBounds.size.height) - 5;
    self.playButton.frame = CGRectMake((bounds.size.width - playButtonBounds.size.width) - 5, yOffset,
                                        playButtonBounds.size.width, playButtonBounds.size.height);
    self.toClipboardButton.frame = CGRectMake(bounds.origin.x + 5, yOffset,
                                               copyButtonBounds.size.width, copyButtonBounds.size.height);
}

-(UIButton *)playButton
{
    if (!_playButton)
    {
        _playButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 30)];
        [_playButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [_playButton setTitle:@"Play" forState:UIControlStateNormal];
        [_playButton addTarget:self action:@selector(playButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [_playButton.titleLabel setFont:[UIFont systemFontOfSize:12]];
        [self addSubview:_playButton];
        [self setNeedsLayout];
    }
    return _playButton;
}

-(UIButton *)toClipboardButton
{
    if (!_toClipboardButton)
    {
        _toClipboardButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 30)];
        [_toClipboardButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [_toClipboardButton setTitle:@"Copy" forState:UIControlStateNormal];
        [_toClipboardButton addTarget:self action:@selector(copyToClipboardClicked)
                      forControlEvents:UIControlEventTouchUpInside];
        [_toClipboardButton.titleLabel setFont:[UIFont systemFontOfSize:12]];
        [self addSubview:_toClipboardButton];
        [self setNeedsLayout];
    }
    return _toClipboardButton;
}

-(NSDictionary *)copyToClipboard
{
    NSDictionary *strokes = self.strokeData;
    NSString *stringToCopy = @"";
    if (strokes)
    {
        NSError *error = nil;
        NSData *data = [NSJSONSerialization dataWithJSONObject:strokes options:NSJSONWritingPrettyPrinted error:&error];
        if (error)
            NSLog(@"Copy Error: %@", error);
        stringToCopy = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    [UIPasteboard generalPasteboard].string = stringToCopy;
    return strokes;
}

@end
