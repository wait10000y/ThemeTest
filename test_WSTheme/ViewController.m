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


@interface ViewController ()<WSThemeChangeDelegate>

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

    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"==== 打印线程为主线程 ====");
    });
    self.title = @"测试";

    static NSObject *testObject001;
    if (!testObject001) {
        testObject001 = [NSObject new];
    }
    NSLog(@"==== 1 testObject001 的属性是:%@ ====",testObject001);

}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[WSTheme sharedObject] addObserver:self forKeyPath:@"currentThemeName" options:NSKeyValueObservingOptionNew context:nil];
    [[WSTheme sharedObject] addDelegate:self];
}

//-(void)viewWillDisappear:(BOOL)animated
//{
//    [super viewWillDisappear:animated];
//    [[WSTheme sharedObject] removeObserver:self forKeyPath:@"currentThemeName"];
//    [[WSTheme sharedObject] removeDelegate:self];
//}


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


// delegate回调方法.
-(void)wsThemeHasChanged:(NSString *)themeName themeModel:(WSThemeModel *)themeModel {
    NSLog(@"==== delegate模式 主题切换:%@ ====",themeName);

    static NSObject *testObject001;
    if (!testObject001) {
        testObject001 = [NSObject new];
    }
    NSLog(@"==== 2 testObject001 的属性是:%@ ====",testObject001);

    if ([themeName isEqualToString:[WSTheme sharedObject].currentThemeName]) {
        //TODO: 更新.
//            // 自定义 读取主题的设置.
//        [themeModel getDataWithIdentifier:@"statusBarStyple" backType:WSThemeValueTypeOriginal complete:^(NSNumber *style) {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [UIApplication sharedApplication].statusBarStyle = style.intValue; // 设定 状态条 颜色
//            });
//        }];
    }
}

//KVO 监听属性.
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    NSLog(@"监听到属性变化:obj:%@ , keyPath:%@ , change.new:%@ , context:%@", object, keyPath, change[@"new"], context);
    if(![@"currentThemeName" isEqualToString:keyPath]){
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }

        // object: WSTheme对象 change: {kind = 1,new = "theme2",old = "theme1"}
    NSString *themeName = [change objectForKey:@"new"];
    if (themeName && [themeName isEqualToString:[WSTheme sharedObject].currentThemeName]) {
            //TODO: 更新.
//            // 自定义 读取主题的设置.
//        WSThemeModel *cModel = [WSTheme sharedObject].currentThemeModel;
//        [cModel getDataWithIdentifier:@"statusBarStyple" backType:WSThemeValueTypeOriginal complete:^(NSNumber *style) {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [UIApplication sharedApplication].statusBarStyle = style.intValue; // 设定 状态条 颜色
//            });
//        }];
    }

}



// 添加 主题约束.
-(void)addWSThemeControl
{

        // 跟随主题切换更新一次.不需要返回的内容
    self.viewContent.wsTheme.custom(nil, 0, ^(UIButton *item, id value) {
            // 自定义 内容,跟随主题更新 刷新.
//        NSLog(@"=== 主题切换一次 ===");
        self.textLabel.text =[NSString stringWithFormat:@"当前主题:%@",[WSTheme sharedObject].currentThemeName?:@"测试"];

        // 自定义 读取主题的设置.
        WSThemeModel *cModel = [WSTheme sharedObject].currentThemeModel;
        [cModel getDataWithIdentifier:@"statusBarStyle" backType:WSThemeValueTypeOriginal complete:^(NSNumber *style) {
            dispatch_async(dispatch_get_main_queue(), ^{
//                [self setNeedsStatusBarAppearanceUpdate];
                [UIApplication sharedApplication].statusBarStyle = style.intValue; // 设定 状态条 颜色
            });
        }];


    });


// view 设置背景色
    self.viewContent.wsTheme.color(@"normal_backgroundColor", ^(UIView *item, UIColor *value) {
        item.backgroundColor = value;
    });


// navigationBar 设定样式.
    UINavigationBar *navBar = self.navigationController.navigationBar;

    navBar.wsTheme.custom(@"navBarDefine.tinColor", WSThemeValueTypeColor, ^(UINavigationBar *item, UIColor *value) {
        item.tintColor = value;
    });

    navBar.wsTheme.custom(@"navBarDefine.barTinColor", WSThemeValueTypeColor, ^(UINavigationBar *item, UIColor *value) {
        item.barTintColor = value;
    });

    navBar.wsTheme.custom(@"navBarDefine.barTitleAttrs",WSThemeValueTypeAttribute, ^(UINavigationBar *item, NSDictionary *attrs) {
        item.titleTextAttributes = attrs;
    });

    navBar.wsTheme.custom(@"navBarDefine.title", WSThemeValueTypeOriginal, ^(UINavigationBar *item, NSString *value) {
        self.title = [value description];
    });

        // 设置 label的样式.
    self.textLabel.wsTheme.custom(@"textView.textFont", WSThemeValueTypeFont, ^(UILabel *item, UIFont *value) {
        item.font = value;
    }).color(@"textView.textColor", ^(UILabel *item, UIColor *value) {
        item.textColor = value;
    });

// 设置图片样式.
    self.imgView.wsTheme.custom(@"imageView.orginImage",WSThemeValueTypeImage, ^(UIImageView *item, UIImage *value) {
        if(value){
            item.image = value;
        }
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
