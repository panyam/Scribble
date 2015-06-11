//
//  ScribbleVC.m
//  Salmon
//
//  Created by Sri Panyam on 5/06/2015.
//  Copyright (c) 2015 osb. All rights reserved.
//

#import "Scribble.h"

@interface ScribbleVC ()

@property (nonatomic, weak) IBOutlet UIButton *playButton;
@property (nonatomic, weak) IBOutlet UIButton *clearButton;
@property (nonatomic, weak) IBOutlet UIButton *colorPickerButton;
@property (nonatomic, weak) IBOutlet CanvasView *canvasView;
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
}

-(IBAction)barButtonItemClicked:(id)sender
{
    if (sender == self.cancelButton)
    {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else if (sender == self.acceptButton)
    {
    }
}

-(IBAction)clearButtonClicked
{
    [self.canvasView clear];
}

-(IBAction)playButtonClicked:(id)sender
{
    NSArray *strokes = self.canvasView.strokeData;
    NSLog(@"Strokes: ", strokes);

    if ([((UIButton *)sender).titleLabel.text isEqualToString:@"Play"])
    {
        [self.canvasView startPlaying:YES];
        self.clearButton.enabled = NO;
        self.colorPickerButton.enabled = NO;
        [self.playButton setTitle:@"Stop" forState:UIControlStateNormal];
    } else {
        [self.canvasView stopPlaying:YES];
        self.clearButton.enabled = YES;
        self.colorPickerButton.enabled = YES;
        [self.playButton setTitle:@"Play" forState:UIControlStateNormal];
    }
}

-(IBAction)colorPickerViewValueChanged:(id)sender
{
    self.colorPickerButton.backgroundColor = self.colorPickerView.color;
    [self.canvasView startNewStrokeWithColor:self.colorPickerView.color withWidth:-1];
}

@end
