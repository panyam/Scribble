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

-(IBAction)copyToClipboardClicked
{
    NSArray *strokes = self.canvasView.strokeData;
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
    [[[UIAlertView alloc] initWithTitle:@"Copied" message:@"The strokelist definition has been copied to the simulator's clipboard.  To paste it in the system, press Cmd+C in the simulator (to copy) and then Cmd+V in the mac (to paste)" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
}

@end
