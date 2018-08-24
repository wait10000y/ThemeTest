//
//  TestNormalViewController.m
//  test_WSTheme
//
//  Created by wsliang on 2018/7/20.
//  Copyright © 2018年 wsliang. All rights reserved.
//

#import "TestNormalViewController.h"
#import "WSTheme.h"

#define NSLog(format, ...) do {(NSLog)((format), ##__VA_ARGS__);} while (0)

@interface TestNormalViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imgView;
@property (weak, nonatomic) IBOutlet UILabel *textLabel;
@property (weak, nonatomic) IBOutlet UIButton *btnNext;
- (IBAction)actionNext:(UIButton *)sender;

@property(nonatomic) UIStatusBarStyle statusBarColorType;

@property(nonatomic) int testIndex;

@property(nonatomic) BOOL startLoop;

@end

@implementation TestNormalViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    _startLoop = YES;
    _statusBarColorType = UIStatusBarStyleDefault;

    NSArray *themeNamelist = [WSTheme sharedObject].themeNameList;
    _testIndex = (int)[themeNamelist indexOfObject:[WSTheme sharedObject].currentThemeName];
    if (_testIndex == NSNotFound) {
        _testIndex = 0;
    }

    [self addWSThemeControl];

}

-(void)dealloc
{
    NSLog(@"==== TestNormalViewController 垃圾回收 ====");
    _startLoop = NO;
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    NSLog(@"==== TestNormalViewController viewDidDisappear ====");
    _startLoop = NO;
}

-(void)addWSThemeControl
{
    __weak typeof(self) weakSelf = self;
        // 跟随主题切换更新一次.不需要返回的内容
    self.btnNext.wsTheme.custom(nil, 0, ^(UIButton *item, id value) {
        NSString *title = [NSString stringWithFormat:@"切换主题(%d)",weakSelf.testIndex];
        [item setTitle:title forState:UIControlStateNormal];
        weakSelf.title = [WSTheme sharedObject].currentThemeName;
        
        WSThemeModel *cModel = [WSTheme sharedObject].currentThemeModel;
        [cModel getDataWithIdentifier:@"statusBarStyle" backType:WSThemeValueTypeOriginal complete:^(NSNumber *style) {
            weakSelf.statusBarColorType = style.intValue;
            dispatch_async(dispatch_get_main_queue(), ^{
//                [self setNeedsStatusBarAppearanceUpdate];
                [UIApplication sharedApplication].statusBarStyle = style.intValue;
            });
        }];

    });


    self.view.wsTheme.color(@"normal_backgroundColor", ^(UIView *item, UIColor *value) {
        item.backgroundColor = value?:[UIColor whiteColor];
    });

    self.navigationController.navigationBar.wsTheme.custom(@"navBarDefine.barTinColor",WSThemeValueTypeColor, ^(UINavigationBar *item, UIColor *value) {
        item.barTintColor = value;

        WSThemeModel *cModel = [WSTheme sharedObject].currentThemeModel;
        [cModel getDataWithIdentifier:@"navBarDefine.title" backType:WSThemeValueTypeJson complete:^(NSString *title) {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                self.title = title;
//            });
        }];

        [cModel getDataWithIdentifier:@"navBarDefine.tinColor" backType:WSThemeValueTypeColor complete:^(UIColor *tinColor) {
            [item performSelectorOnMainThread:@selector(setTintColor:) withObject:tinColor waitUntilDone:NO];
        }];

        [cModel getDataWithIdentifier:@"navBarDefine.barTitleAttrs" backType:WSThemeValueTypeAttribute complete:^(NSDictionary *attrs) {
            dispatch_async(dispatch_get_main_queue(), ^{
                item.titleTextAttributes = attrs;
            });
        }];

    });

    self.textLabel.wsTheme.custom(@"textView.textFont", WSThemeValueTypeFont, ^(UILabel *item, UIFont *value) {
        item.font = value;
    }).color(@"textView.textColor", ^(UILabel *item, UIColor *value) {
        item.textColor = value;
        item.text = [NSString stringWithFormat:@"主题:%@,颜色:%@",[WSTheme sharedObject].currentThemeName?:@"没有主题",value?:@"默认颜色"];
    });


    self.imgView.wsTheme.custom(@"imageView.orginImage",WSThemeValueTypeImage, ^(UIImageView *item, UIImage *value) {
            // TODO:test
        NSLog(@"==== 获取远程图片回调:%@ ====",value);
        if(value){
            item.image = value;
        }
    }).custom(@"imageView.background", WSThemeValueTypeColor, ^(UIImageView *item, UIColor *backColor) {
        item.backgroundColor = backColor;
    }).custom(@"imageView.defaultImage", WSThemeValueTypeImage, ^(UIImageView *item, UIImage *orginImage) {
        item.image = orginImage;
    });


    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int addNum = 100;
        for (int it=0; it<addNum; it++) {
            self.textLabel.wsTheme.custom(@"color.textColor", WSThemeValueTypeOriginal, ^(UILabel *item, NSString *value) {
                NSString *nowStr = [NSString stringWithFormat:@"%@\t - %d\t",value,it];
                NSLog(@"-- 更新调用:%@ --",nowStr);
                item.text = nowStr;
            });
        }
        NSLog(@"==== 注册完成 %d 个 ====",addNum);
    });

}


-(void)testChangeThemeModel
{
    NSArray *themeList = [[WSTheme sharedObject] themeNameList];
        //    int index = arc4random_uniform(themeList.count);
    if (themeList.count>0) {
        _testIndex ++;
        NSString *themeName = themeList[_testIndex%themeList.count];
        [[WSTheme sharedObject] startTheme:themeName];
    }

}
- (IBAction)actionNext:(UIButton *)sender
{
    [self testChangeThemeModel];
}

- (IBAction)actionNextLoop:(UIButton *)sender
{

        // TODO:test
    NSLog(@"==== 开始循环 调用切换  ====");
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        do {
            NSLog(@"==== 执行一次 主题切换  ====");
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf actionNext:nil];
            });
            sleep(1);
        } while (weakSelf.startLoop);
            // TODO:test
        NSLog(@"==== 已停止循环 切换theme 调用 ====");
    });

}



- (UIStatusBarStyle)preferredStatusBarStyle
{
    return self.statusBarColorType;
}

- (BOOL)prefersStatusBarHidden
{
    return NO;
}


@end






