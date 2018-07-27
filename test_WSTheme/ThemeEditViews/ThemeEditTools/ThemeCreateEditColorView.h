//
//  ThemeCreateEditColorView.h
//  TestTheme_sakura
//
//  Created by 王士良 on 2018/7/2.
//  Copyright © 2018年 王士良. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ThemeCreateEditViewProtocol.h"

@interface ThemeCreateEditColorView : UIView<ThemeCreateEditViewProtocol>
@property (weak, nonatomic) IBOutlet UITextField *textFieldColor;
@property (weak, nonatomic) IBOutlet UISlider *redSlider;
@property (weak, nonatomic) IBOutlet UISlider *greenSlider;
@property (weak, nonatomic) IBOutlet UISlider *blueSlider;
@property (weak, nonatomic) IBOutlet UISlider *alphaSlider;

@property (weak, nonatomic) IBOutlet UILabel *textTitle;

@property(nonatomic) UIColor *currentColor; // 设置的color

- (IBAction)sliderEvent:(UISlider *)sender;

    // 返回格式 #FFFFFF 或者 ##FFFFFFFF
+(NSString *)color2RGBString:(UIColor *)theColor;

+(ThemeCreateEditColorView *)createView;
-(id)getCurrentValue;

@end
