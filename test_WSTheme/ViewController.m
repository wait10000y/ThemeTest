//
//  ViewController.m
//  test_WSTheme
//
//  Created by wsliang on 2018/7/20.
//  Copyright © 2018年 wsliang. All rights reserved.
//

#import "ViewController.h"
#import "TestNormalViewController.h"
#import "ThemeSelectViewController.h"

#import "WSTheme.h"
#import "WSThemeExtension.h"


@interface ViewController ()

@property (weak, nonatomic) IBOutlet UILabel *textLabel;
@property (weak, nonatomic) IBOutlet UIImageView *imgView;
@property (weak, nonatomic) IBOutlet UIView *viewContent;

@property (weak, nonatomic) IBOutlet UIButton *btnShowThemeList;
-(IBAction)actionShowThemeList:(id)sender;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *barItem1;
- (IBAction)actionToTestView:(UIBarButtonItem *)sender;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self addWSThemeControl];

    self.title = @"测试";

}

// 主题列表 编辑界面
-(IBAction)actionShowThemeList:(id)sender
{
    ThemeSelectViewController *selectVC = [ThemeSelectViewController new];
    [self.navigationController pushViewController:selectVC animated:YES];
    
}

// 跳测试界面
- (IBAction)actionToTestView:(UIBarButtonItem *)sender {
    TestNormalViewController *testVC = [TestNormalViewController new];
    [self.navigationController pushViewController:testVC animated:YES];
}


// 添加 主题约束.
-(void)addWSThemeControl
{

        // 跟随主题切换更新一次.不需要返回的内容
    self.viewContent.theme.custom(nil, 0, ^(UIButton *item, id value) {
            // 自定义 内容,跟随主题更新 刷新.
        NSLog(@"=== 主题切换一次 ===");
        self.textLabel.text =[NSString stringWithFormat:@"当前主题:%@",[WSTheme sharedObject].currentThemeName?:@"测试"];

        // 自定义 读取主题的设置.
        WSThemeModel *cModel = [WSTheme sharedObject].currentThemeModel;
        [cModel getDataWithIdentifier:@"statusBarStyple" backType:WSThemeValueTypeOriginal complete:^(NSNumber *style) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIApplication sharedApplication].statusBarStyle = style.intValue; // 设定 状态条 颜色
            });
        }];


    });


// view 设置背景色
    self.viewContent.theme.color(@"normal_backgroundColor", ^(UIView *item, UIColor *value) {
        item.backgroundColor = value;
    });


// navigationBar 设定样式.
    UINavigationBar *navBar = self.navigationController.navigationBar;

    navBar.theme.custom(@"navBarDefine.tinColor", WSThemeValueTypeColor, ^(UINavigationBar *item, UIColor *value) {
        item.tintColor = value;
    });

    navBar.theme.custom(@"navBarDefine.barTinColor", WSThemeValueTypeColor, ^(UINavigationBar *item, UIColor *value) {
        item.barTintColor = value;
    });

    navBar.theme.custom(@"navBarDefine.barTitleAttrs",WSThemeValueTypeAttribute, ^(UINavigationBar *item, NSDictionary *attrs) {
        item.titleTextAttributes = attrs;
    });

    navBar.theme.custom(@"navBarDefine.title", WSThemeValueTypeOriginal, ^(UINavigationBar *item, NSString *value) {
        self.title = [value description];
    });

        // 设置 label的样式.
    self.textLabel.theme.custom(@"textView.textFont", WSThemeValueTypeFont, ^(UILabel *item, UIFont *value) {
        item.font = value;
    }).color(@"textView.textColor", ^(UILabel *item, UIColor *value) {
        item.textColor = value;
    });

// 设置图片样式.
    self.imgView.theme.custom(@"imageView.orginImage",WSThemeValueTypeImage, ^(UIImageView *item, UIImage *value) {
        item.image = value;
    }).custom(@"imageView.background", WSThemeValueTypeColor, ^(UIImageView *item, UIColor *backColor) {
        item.backgroundColor = backColor;
    }).custom(@"imageView.defaultImage", WSThemeValueTypeImage, ^(UIImageView *item, UIImage *orginImage) {
        item.image = orginImage;
    });

}


- (IBAction)testThemeSimple:(UIButton *)sender {

    UIViewController *tempvc = [NSClassFromString(@"TestWSThemeSimpleViewController") new];
    if (tempvc) {
        [self.navigationController pushViewController:tempvc animated:YES];
    }

}


@end
