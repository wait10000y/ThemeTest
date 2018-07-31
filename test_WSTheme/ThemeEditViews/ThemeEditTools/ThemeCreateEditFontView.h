//
//  ThemeCreateEditFontView.h
//  TestTheme_sakura
//
//  Created by wsliang on 2018/7/4.
//  Copyright © 2018年 wsliang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ThemeCreateEditViewProtocol.h"


@interface ThemeCreateEditFontView : UIView<ThemeCreateEditViewProtocol>

@property (weak, nonatomic) IBOutlet UILabel *textTitle;

@property(nonatomic) UIFont *currentFont;



+(instancetype)createView;
-(id)getCurrentValue;

@end
