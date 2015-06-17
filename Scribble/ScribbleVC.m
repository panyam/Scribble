//
//  ScribbleVC.m
//  Salmon
//
//  Created by Sri Panyam on 5/06/2015.
//  Copyright (c) 2015 osb. All rights reserved.
//

#import "Scribble.h"
#import <NeoveraColorPicker/NEOColorPickerViewController.h>
#import <NeoveraColorPicker/NEOColorPickerHSLViewController.h>

@interface ScribbleVC ()<NEOColorPickerViewControllerDelegate>

@property (nonatomic) BOOL lineColorPickerSelected;
@property (nonatomic, weak) IBOutlet UIButton *clearButton;
@property (nonatomic, weak) IBOutlet UIButton *lineColorPickerButton;
@property (nonatomic, weak) IBOutlet UIButton *bgColorPickerButton;
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
}

-(IBAction)colorPickerButtonClicked:(id)sender
{
    self.lineColorPickerSelected = (sender == self.lineColorPickerButton);
    NEOColorPickerHSLViewController *controller = [[NEOColorPickerHSLViewController alloc] init];
    controller.delegate = self;
    controller.selectedColor = ((UIButton *)sender).backgroundColor;
    controller.title = sender == self.lineColorPickerButton ? @"Line Color": @"Background Color";
    UINavigationController* navVC = [[UINavigationController alloc] initWithRootViewController:controller];
    [self presentViewController:navVC animated:YES completion:nil];
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

#pragma CanvasViewDelegate methods

-(void)canvasView:(CanvasView *)canvasView startedAnimationLoop:(NSInteger)loopIndex resumed:(BOOL)resumed
{
    self.clearButton.enabled = NO;
    self.pasteButton.enabled = NO;
    self.lineColorPickerButton.enabled = NO;
    self.bgColorPickerButton.enabled = NO;
}

-(void)canvasViewAnimationStopped:(CanvasView *)canvasView
{
    self.clearButton.enabled = YES;
    self.pasteButton.enabled = YES;
    self.lineColorPickerButton.enabled = YES;
    self.bgColorPickerButton.enabled = YES;
}

- (void) colorPickerViewController:(NEOColorPickerBaseViewController *)controller didSelectColor:(UIColor *)color {
    if (self.lineColorPickerSelected)
    {
        self.lineColorPickerButton.backgroundColor = color;
        [self.canvasView startNewStrokeWithColor:color withWidth:-1];
    }
    else
    {
        self.bgColorPickerButton.backgroundColor = color;
        self.canvasView.backgroundColor = color;
    }
    [controller dismissViewControllerAnimated:YES completion:nil];
}

- (void) colorPickerViewControllerDidCancel:(NEOColorPickerBaseViewController *)controller {
    [controller dismissViewControllerAnimated:YES completion:nil];
}

@end
