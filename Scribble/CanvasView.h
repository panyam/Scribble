//
//  CanvasView.h
//  Salmon
//
//  Created by Sri Panyam on 4/06/2015.
//  Copyright (c) 2015 osb. All rights reserved.
//

#import "ScribbleFwds.h"

@interface CanvasView : UIView

/**
 * Specifies how many times the strokes will be animated before stopping.
 * If set to -ve then animation will loop for ever.
 */
@property (nonatomic) NSInteger animationCount;

/**
 * Delay between each loop of the animation.
 */
@property (nonatomic) CGFloat delayBetweenAnimationLoops;

/**
 * Delay between each frame in the stroke animation.
 */
@property (nonatomic) CGFloat delayBetweenAnimationFrames;

/**
 * The alpha with which the playback stroke will be drawn in the background first.
 */
@property (nonatomic) CGFloat playbackStrokeAlpha;

@property (nonatomic) BOOL disableTouches;
@property (nonatomic, readonly) UIColor *currLineColor;
@property (nonatomic, readonly) CGFloat currLineWidth;
@property (nonatomic) NSDictionary *strokeData;
@property (nonatomic) CGPoint translateBy;

-(void)startNewStrokeWithColor:(UIColor *)lineColor withWidth:(CGFloat)lineWidth;
-(void)clear;
-(void)startPlaying:(BOOL)restart;
-(void)stopPlaying:(BOOL)finish;

@end
