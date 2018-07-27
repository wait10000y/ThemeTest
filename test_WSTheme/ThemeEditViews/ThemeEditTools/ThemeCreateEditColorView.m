//
//  ThemeCreateEditColorView.m
//  TestTheme_sakura
//
//  Created by 王士良 on 2018/7/2.
//  Copyright © 2018年 王士良. All rights reserved.
//

#import "ThemeCreateEditColorView.h"

@interface ThemeCreateEditColorView()<UITextFieldDelegate>

@end

@implementation ThemeCreateEditColorView

- (void)awakeFromNib
{
    [super awakeFromNib];
//    UIView *contentView = self.textFieldColor.superview.superview;
//    contentView.layer.cornerRadius = 8;
//    contentView.layer.masksToBounds = YES;
    self.textTitle.superview.layer.cornerRadius = 5;
    self.textTitle.superview.layer.masksToBounds = YES;
}

+(ThemeCreateEditColorView *)createView
{
ThemeCreateEditColorView *editView = [[[NSBundle mainBundle] loadNibNamed:@"ThemeCreateEditColorView" owner:nil options:nil] firstObject];
//    editView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    editView.textTitle.text = @"颜色选择器:";
    return editView;
}

-(void)synSliderValueWithColor:(UIColor *)currentColor
{
    CGFloat r,g,b,a;
    [currentColor getRed:&r green:&g blue:&b alpha:&a];
    self.redSlider.value = r;
    self.greenSlider.value = g;
    self.blueSlider.value = b;
    self.alphaSlider.value = a;
    self.textTitle.superview.backgroundColor = currentColor;
    UIColor *osColor = [UIColor colorWithRed:1-r green:1-g blue:1-b alpha:1];
    self.textFieldColor.textColor = osColor;

    NSString *colorStr = [ThemeCreateEditColorView color2RGBString:currentColor];
    self.textFieldColor.text = colorStr;

}

//- (void)textFieldDidEndEditing:(UITextField *)textField
//{
//    [self synSliderValueWithColor:nil];
//}

-(void)setCurrentColor:(UIColor *)currentColor
{
    _currentColor = currentColor;
    if (currentColor) {
        [self synSliderValueWithColor:currentColor];
    }
}
-(id)getCurrentValue
{
    return _textFieldColor.text;
}

- (IBAction)sliderEvent:(UISlider *)sender {

    CGFloat r = self.redSlider.value;
    CGFloat g = self.greenSlider.value;
    CGFloat b = self.blueSlider.value;
    CGFloat a = self.alphaSlider.value;

    UIColor *curColor = [UIColor colorWithRed:r green:g blue:b alpha:a];
    self.textTitle.superview.backgroundColor = curColor;
    _currentColor = curColor;
    UIColor *osColor = [UIColor colorWithRed:1-r green:1-g blue:1-b alpha:1];
    self.textFieldColor.textColor = osColor;;

    NSString *colorStr = [ThemeCreateEditColorView color2RGBString:curColor];
    self.textFieldColor.text = colorStr;
}

    // 返回格式 #FFFFFF 或者 ##FFFFFFFF
+(NSString *)color2RGBString:(UIColor *)theColor
{
    NSString *tempStr;
    if (theColor) {
        CGFloat r,g,b,a;
        [theColor getRed:&r green:&g blue:&b alpha:&a];
        int R,G,B,A;
        R = roundf(r*255);G= roundf(g*255);B= roundf(b*255);A= roundf(a*255);
        if (A < 255) {
            tempStr =[NSString stringWithFormat:@"#%.2X%.2X%.2X%.2X",A,R,G,B];
        }else{
            tempStr =[NSString stringWithFormat:@"#%.2X%.2X%.2X",R,G,B];
        }
    }
    return tempStr;
}

-(void)hideSelf
{
    [UIView animateWithDuration:0.3f animations:^{
        self.alpha = 0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
        self.alpha = 1;
    }];

}
@end
