//
//  ThemeCreateHeaderView.h
//  TestTheme_sakura
//
//  Created by 王士良 on 2018/7/2.
//  Copyright © 2018年 王士良. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^ThemeCreateHeaderBlock)(UILabel *textTitle);
@interface ThemeCreateHeaderView : UIView

@property (weak, nonatomic) IBOutlet UILabel *textTitle;
@property(nonatomic) ThemeCreateHeaderBlock callBlack;

- (IBAction)actionSelect:(UIButton *)sender;

+(ThemeCreateHeaderView *)ceateHeaderView;

@end
