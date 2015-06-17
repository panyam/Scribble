//
//  ColorPickerVC.h
//  RSColorPicker
//
//  Created by Ryan Sullivan on 7/14/13.
//

#import <UIKit/UIKit.h>

@interface ColorPickerVC : UIViewController {
    BOOL isSmallSize;
}
@property (nonatomic) UIView *colorPatch;

@property UILabel *rgbLabel;

@end
