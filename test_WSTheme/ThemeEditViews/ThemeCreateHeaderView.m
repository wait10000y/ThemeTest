//
//  ThemeCreateHeaderView.m
//  TestTheme_sakura
//
//  Created on 2018/7/2.
//  wsliang.
//

#import "ThemeCreateHeaderView.h"

@implementation ThemeCreateHeaderView

+(ThemeCreateHeaderView *)ceateHeaderView
{
    ThemeCreateHeaderView *headerView = [[[NSBundle mainBundle] loadNibNamed:@"ThemeCreateHeaderView" owner:nil options:nil] firstObject];
    headerView.textTitle.superview.layer.borderWidth = 1.0f/[UIScreen mainScreen].scale;
    headerView.textTitle.superview.layer.borderColor = [UIColor lightGrayColor].CGColor;
    headerView.textTitle.minimumScaleFactor = 0.25f;
    headerView.textTitle.numberOfLines = 2;
    return headerView;

//    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 38)];
//    headerView.backgroundColor = [UIColor groupTableViewBackgroundColor];
//    UILabel *tempLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, 290, 38)];
//    tempLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
//    [headerView addSubview:tempLabel];
//        //        tempLabel.userInteractionEnabled = YES;
//    tempLabel.adjustsFontSizeToFitWidth = YES;
//    tempLabel.text = theTitle;
//    tempLabel.textColor = [UIColor grayColor];
}

- (IBAction)actionSelect:(UIButton *)sender {
    if (self.callBlack) {
        self.callBlack(self.textTitle);
    }
}

@end
