//
//  CanvasView.h
//  Salmon
//
//  Created by Sri Panyam on 4/06/2015.
//  Copyright (c) 2015 osb. All rights reserved.
//

#import "ScribbleFwds.h"

@interface CanvasView : UIView

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
