//
//  ThemeCreateHeaderView.h
//  TestTheme_sakura
//
//  Created by wsliang on 2018/7/2.
//  Copyright © 2018年 wsliang. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^ThemeCreateHeaderBlock)(UILabel *textTitle);
@interface ThemeCreateHeaderView : UIView

@property (weak, nonatomic) IBOutlet UILabel *textTitle;
@property(nonatomic) ThemeCreateHeaderBlock callBlack;

- (IBAction)actionSelect:(UIButton *)sender;

+(ThemeCreateHeaderView *)ceateHeaderView;

@end
