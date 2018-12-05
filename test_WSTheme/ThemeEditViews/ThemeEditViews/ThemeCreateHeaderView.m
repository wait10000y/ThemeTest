//
//  ThemeCreateHeaderView.m
//  Created on 2018/7/2.

#import "ThemeCreateHeaderView.h"

#define isIpad (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

@implementation ThemeCreateHeaderView

+(ThemeCreateHeaderView *)ceateHeaderView
{
//    ThemeCreateHeaderView *headerView = [[[NSBundle mainBundle] loadNibNamed:@"ThemeCreateHeaderView" owner:nil options:nil] firstObject];
//    headerView.textTitle.superview.layer.borderWidth = 1.0f/[UIScreen mainScreen].scale;
//    headerView.textTitle.superview.layer.borderColor = [UIColor lightGrayColor].CGColor;
//    headerView.textTitle.minimumScaleFactor = 0.25f;
//    headerView.textTitle.numberOfLines = 2;
//    return headerView;

    CGFloat sectionHieght = (isIpad?58:48);
    CGFloat cellHeight = (isIpad?72:56);
    CGFloat marginX = (isIpad?25:15);

    ThemeCreateHeaderView *headerView = [[ThemeCreateHeaderView alloc] initWithFrame:CGRectMake(0, 0, 320, cellHeight+sectionHieght)];
    headerView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    headerView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;

    // section标题
    UILabel *tempLabel = [[UILabel alloc] initWithFrame:CGRectMake(marginX, 0, 320-marginX, sectionHieght)];
    tempLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleLeftMargin;
//    tempLabel.font = [UIFont systemFontOfSize:isIpad?20:16];
    tempLabel.textColor = [UIColor grayColor];
    tempLabel.adjustsFontSizeToFitWidth = YES;
    tempLabel.text = @"主题名称";
    [headerView addSubview:tempLabel];


    //点击事件
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.backgroundColor = [UIColor whiteColor];
    [button setTitle:nil forState:UIControlStateNormal];
    button.frame = CGRectMake(0, sectionHieght, 320, cellHeight);
    button.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleLeftMargin;
    [button addTarget:headerView action:@selector(actionSelect:) forControlEvents:UIControlEventTouchUpInside];
    [headerView addSubview:button];

        // cell标题
    UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(marginX, sectionHieght, 320-marginX, cellHeight)];
    textLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleLeftMargin;
        //    textLabel.font = [UIFont systemFontOfSize:isIpad?21:18];
    textLabel.textColor = [UIColor blackColor];
    textLabel.adjustsFontSizeToFitWidth = YES;
    textLabel.text = @"主题";
    headerView.textTitle = textLabel;
    [headerView addSubview:textLabel];

    return headerView;
}

- (IBAction)actionSelect:(UIButton *)sender {
    if (self.callBlack) {
        self.callBlack(self.textTitle);
    }
}

@end
