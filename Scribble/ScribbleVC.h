//
//  ScribbleVC.h
//  Salmon
//
//  Created by Sri Panyam on 5/06/2015.
//  Copyright (c) 2015 osb. All rights reserved.
//

#import "Scribble.h"
#import <Color-Picker-for-iOS/HRColorPickerView.h>

@protocol ScribbleVCDelegate;

@interface ScribbleVC : UIViewController

@property (nonatomic, weak) id<ScribbleVCDelegate>  scribbleDelegate;
@property (nonatomic, weak) IBOutlet CanvasView *canvasView;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *cancelButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *acceptButton;
@property (nonatomic, weak) IBOutlet UIButton *playButton;
@property (nonatomic, weak) IBOutlet UIButton *toClipboardButton;

@end

@protocol ScribbleVCDelegate <NSObject>

@optional
-(void)scribbleVCDismissed:(ScribbleVC *)scribbleVC;
-(void)scribbleVCAccepted:(ScribbleVC *)scribbleVC withStrokes:(NSDictionary *)strokes;
-(void)scribbleVCCleared:(ScribbleVC *)scribbleVC;
-(void)scribbleVC:(ScribbleVC *)scribbleVC dataCopied:(NSDictionary *)strokes;

@end
