//
//  ScribbleVC.m
//  Salmon
//
//  Created by Sri Panyam on 5/06/2015.
//  Copyright (c) 2015 osb. All rights reserved.
//

#import "Scribble.h"

@interface ScribbleVC ()

@property (nonatomic, weak) IBOutlet UIButton *clearButton;
@property (nonatomic, weak) IBOutlet UIButton *colorPickerButton;
@property (nonatomic, weak) IBOutlet HRColorPickerView *colorPickerView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *colorPickerLeftConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *colorPickerTopConstraint;

@end

@implementation ScribbleVC

-(void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Scribble!";
    self.navigationItem.leftBarButtonItem = self.cancelButton;
    self.navigationItem.rightBarButtonItem = self.acceptButton;
    [self.colorPickerView addTarget:self
                             action:@selector(colorPickerViewValueChanged:)
                   forControlEvents:UIControlEventValueChanged];
    [self.colorPickerView setColor:[UIColor redColor]];
}

-(IBAction)colorPickerButtonClicked
{
    self.colorPickerView.hidden = !self.colorPickerView.hidden;
    self.acceptButton.enabled = self.colorPickerView.hidden;
    self.cancelButton.enabled = self.colorPickerView.hidden;
    self.clearButton.enabled = self.colorPickerView.hidden;
    self.pasteButton.enabled = self.colorPickerView.hidden;
}

-(IBAction)barButtonItemClicked:(id)sender
{
    if (sender == self.cancelButton)
    {
        if ([self.scribbleDelegate respondsToSelector:@selector(scribbleVCDismissed:)])
            [self.scribbleDelegate scribbleVCDismissed:self];
        else
            [self dismissViewControllerAnimated:YES completion:nil];
    } else if (sender == self.acceptButton)
    {
		if ([self.scribbleDelegate respondsToSelector:@selector(scribbleVCAccepted:withStrokes:)])
			[self.scribbleDelegate scribbleVCAccepted:self withStrokes:self.canvasView.strokeData];
    }
}

-(IBAction)clearButtonClicked
{
    [self.canvasView clear];
    if ([self.scribbleDelegate respondsToSelector:@selector(scribbleVCCleared:)])
        [self.scribbleDelegate scribbleVCCleared:self];
}

-(IBAction)pasteButtonClicked
{
    NSLog(@"Paste not yet implemented");
}

-(IBAction)colorPickerViewValueChanged:(id)sender
{
    self.colorPickerButton.backgroundColor = self.colorPickerView.color;
    [self.canvasView startNewStrokeWithColor:self.colorPickerView.color withWidth:-1];
}

#pragma CanvasViewDelegate methods

-(void)canvasView:(CanvasView *)canvasView startedAnimationLoop:(NSInteger)loopIndex resumed:(BOOL)resumed
{
    self.clearButton.enabled = NO;
    self.pasteButton.enabled = NO;
    self.colorPickerButton.enabled = NO;
}

-(void)canvasViewAnimationStopped:(CanvasView *)canvasView
{
    self.clearButton.enabled = YES;
    self.pasteButton.enabled = YES;
    self.colorPickerButton.enabled = YES;
}

@end
