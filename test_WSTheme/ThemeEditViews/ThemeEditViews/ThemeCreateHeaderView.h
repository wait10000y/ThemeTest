//
//  ThemeCreateHeaderView.h
//  Created on 2018/7/2.

#import <UIKit/UIKit.h>

typedef void(^ThemeCreateHeaderBlock)(UILabel *textTitle);
@interface ThemeCreateHeaderView : UIView

@property (nonatomic) UILabel *textTitle;
@property(nonatomic) ThemeCreateHeaderBlock callBlack;

- (IBAction)actionSelect:(UIButton *)sender;

+(ThemeCreateHeaderView *)ceateHeaderView;

@end
