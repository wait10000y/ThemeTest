//
//  ThemeCreateHeaderView.m
//  TestTheme_sakura
//
//  Created by wsliang on 2018/7/2.
//  Copyright © 2018年 wsliang. All rights reserved.
//

#import "ThemeCreateHeaderView.h"

@implementation ThemeCreateHeaderView

+(ThemeCreateHeaderView *)ceateHeaderView
{
    ThemeCreateHeaderView *headerView = [[[NSBundle mainBundle] loadNibNamed:@"ThemeCreateHeaderView" owner:nil options:nil] firstObject];
    return headerView;
}

- (IBAction)actionSelect:(UIButton *)sender {
    if (self.callBlack) {
        self.callBlack(self.textTitle);
    }
}

@end
