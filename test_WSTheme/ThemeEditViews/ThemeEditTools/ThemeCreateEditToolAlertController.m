//
//  ThemeCreateEditToolAlertController.m
//  TestTheme_sakura
//
//  Created by wsliang on 2018/7/2.
//  Copyright © 2018年 wsliang. All rights reserved.
//

#import "ThemeCreateEditToolAlertController.h"
#import "ThemeCreateEditColorView.h"
#import "ThemeCreateEditTextView.h"
#import "ThemeCreateEditFontView.h"
#import "ThemeCreateEditEnumView.h"

#define alertControllerFindTitle @" "
#define alertControllerFindSubTitle @"  "

@interface ThemeCreateEditToolAlertController ()

@property(nonatomic) ThemeCreateEditToolAlertBlock callBack;
@property(nonatomic) UIView<ThemeCreateEditViewProtocol> *mCustomView;

@end

@implementation ThemeCreateEditToolAlertController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)setTipTitle:(NSString *)title
{
    _mCustomView.textTitle.text = title;
}

+(ThemeCreateEditToolAlertController *)createColorAlertWithColor:(UIColor *)theColor complete:(ThemeCreateEditToolAlertBlock)completeBlock
{
    ThemeCreateEditColorView *customView = [ThemeCreateEditColorView createView];
    customView.currentColor = theColor;
    ThemeCreateEditToolAlertController *alertVC = [ThemeCreateEditToolAlertController createAlertControllerForCustomView:customView];
    if (completeBlock) {
        alertVC.callBack = [completeBlock copy];
    }
    return alertVC;
}

+(ThemeCreateEditToolAlertController *)createTextAlertWithText:(NSString *)theText complete:(ThemeCreateEditToolAlertBlock)completeBlock
{
    ThemeCreateEditTextView *customView = [ThemeCreateEditTextView createView];
    customView.textView.text = theText;
    ThemeCreateEditToolAlertController *alertVC = [ThemeCreateEditToolAlertController createAlertControllerForCustomView:customView];
    if (completeBlock) {
        alertVC.callBack = [completeBlock copy];
    }
    return alertVC;
}

+(ThemeCreateEditToolAlertController *)createFontAlertWithFont:(UIFont *)theFont complete:(ThemeCreateEditToolAlertBlock)completeBlock
{
    ThemeCreateEditFontView *customView = [ThemeCreateEditFontView createView];
    customView.currentFont = theFont;
    ThemeCreateEditToolAlertController *alertVC = [ThemeCreateEditToolAlertController createAlertControllerForCustomView:customView];
    if (completeBlock) {
        alertVC.callBack = [completeBlock copy];
    }
    return alertVC;
}

+(ThemeCreateEditToolAlertController *)createEnumAlertWithDataDict:(NSDictionary *)theDict defaultValue:(id)value complete:(ThemeCreateEditToolAlertBlock)completeBlock
{
    ThemeCreateEditEnumView *customView = [ThemeCreateEditEnumView createView];
    [customView setEnumDict:theDict defaultValue:value];
    ThemeCreateEditToolAlertController *alertVC = [ThemeCreateEditToolAlertController createAlertControllerForCustomView:customView];
    if (completeBlock) {
        alertVC.callBack = [completeBlock copy];
    }
    return alertVC;
}

+(ThemeCreateEditToolAlertController *)createAlertControllerForCustomView:(UIView<ThemeCreateEditViewProtocol> *)customView
{
    ThemeCreateEditToolAlertController *alertVC = [ThemeCreateEditToolAlertController alertControllerWithTitle:alertControllerFindTitle message:alertControllerFindSubTitle preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"确  认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        if (alertVC.callBack) {
            alertVC.callBack(YES,[customView getCurrentValue]);
        }
    }];
    [alertVC addAction:action2];

    UIAlertAction *action3 = [UIAlertAction actionWithTitle:@"取  消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
        if (alertVC.callBack) {
            alertVC.callBack(NO,[customView getCurrentValue]);
        }
    }];
    [alertVC addAction:action3];

// 约束 自定义的view
    if (!customView) {
        return alertVC;
    }

    UIView *titleView,*subTitleView;
    [alertVC findViewsFromView:alertVC.view titleView:&titleView subTitleView:&subTitleView];
    titleView = titleView?:alertVC.view;
    subTitleView = subTitleView?:alertVC.view;

    [alertVC.view addSubview:customView];
    customView.translatesAutoresizingMaskIntoConstraints=NO;
    CGFloat viewHeight = customView.frame.size.height;

    NSLayoutConstraint *constraint1 = [NSLayoutConstraint constraintWithItem:customView
                                                                   attribute:NSLayoutAttributeTop
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:titleView
                                                                   attribute:NSLayoutAttributeTop
                                                                  multiplier:1
                                                                    constant:0];
    NSLayoutConstraint *constraint2 = [NSLayoutConstraint constraintWithItem:customView
                                                                   attribute:NSLayoutAttributeLeft
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:titleView
                                                                   attribute:NSLayoutAttributeLeft
                                                                  multiplier:1
                                                                    constant:0];
    NSLayoutConstraint *constraint3 = [NSLayoutConstraint constraintWithItem:customView
                                                                   attribute:NSLayoutAttributeRight
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:titleView
                                                                   attribute:NSLayoutAttributeRight
                                                                  multiplier:1
                                                                    constant:0];
    NSLayoutConstraint *constraint4 = [NSLayoutConstraint constraintWithItem:customView
                                                                   attribute:NSLayoutAttributeBottom
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:subTitleView
                                                                   attribute:NSLayoutAttributeBottom
                                                                  multiplier:1
                                                                    constant:0];
    NSLayoutConstraint *constraint5 = [NSLayoutConstraint constraintWithItem:customView
                                                                   attribute:NSLayoutAttributeHeight
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:nil
                                                                   attribute:NSLayoutAttributeNotAnAttribute
                                                                  multiplier:1
                                                                    constant:viewHeight];

//    NSLayoutConstraint *constraint6 = [NSLayoutConstraint constraintWithItem:customView
//                                                                   attribute:NSLayoutAttributeHeight
//                                                                   relatedBy:NSLayoutRelationGreaterThanOrEqual
//                                                                      toItem:nil
//                                                                   attribute:NSLayoutAttributeNotAnAttribute
//                                                                  multiplier:1
//                                                                    constant:98];

    // 48
    [alertVC.view addConstraints:@[constraint1,constraint2,constraint3,constraint4,constraint5]];

    return alertVC;
}

-(void)findViewsFromView:(UIView *)theView titleView:(UIView **)titleView subTitleView:(UIView **)subTitleView
{
    NSArray *subviews = [theView subviews];
        // 如果没有子视图就直接返回
    if ([subviews count] == 0) return;

    for (UIView *subview in subviews) {
            // 根据层级决定前面空格个数，来缩进显示
        if ([subview isKindOfClass:[UILabel class]]) {
            NSString *tempText = ((UILabel*)subview).text;
            if ([alertControllerFindTitle isEqualToString:tempText]) {
                subview.tag = 1;
                *titleView = subview;
            }else if ([alertControllerFindSubTitle isEqualToString:tempText]){
                subview.tag = 2;
                *subTitleView = subview;
            }
            if (*titleView !=nil && *subTitleView != nil) {
                return;
            }
        }
            // 递归获取此视图的子视图
        [self findViewsFromView:subview titleView:titleView subTitleView:subTitleView];

    }

}

-(void)addContrantsForCustomView:(UIView *)theCustomView
{

}

@end
