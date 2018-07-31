//
//  TestWSThemeSimpleViewController.m
//  test_WSTheme
//
//  Created by wsliang on 2018/7/31.
//  Copyright © 2018年 wsliang. All rights reserved.
//

#import "TestWSThemeSimpleViewController.h"
#import "WSThemeSimple.h"


@interface TestWSThemeSimpleViewController ()


@property (weak, nonatomic) IBOutlet UILabel *textShow;

@end

@implementation TestWSThemeSimpleViewController
{
    int testIndex;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    testIndex = 0;

    [self loadThtmeData];
    [self configTheme];

}

// 切换主题.
- (IBAction)changeTheme:(UIButton *)sender {

    NSArray *themeList = [[WSThemeSimple sharedObject] themeNameList];
        //    int index = arc4random_uniform(themeList.count);
    if (themeList.count>0) {
        testIndex ++;
        NSString *themeName = themeList[testIndex%themeList.count];
        [[WSThemeSimple sharedObject] startTheme:themeName];
    }
}

// 添加默认主题.appDelegate中加载.
-(void)loadThtmeData
{
    NSArray *testNames = @[
                           @"主题1",
                           @"主题2",
                           @"主题3",
                           ];

    [[WSThemeSimple sharedObject] addThemeWithNameList:testNames];
    [[WSThemeSimple sharedObject] startTheme:[testNames lastObject]];
}

// 添加约束.
-(void)configTheme
{
    __weak typeof(self) weakSelf = self;
    self.wsThemeSimple.custom(^(id item, NSString *themeName) {
        weakSelf.title = themeName;
    });


    self.textShow.wsThemeSimple.custom(^(UILabel *item, NSString *themeName) {
        item.text = [NSString stringWithFormat:@"当前主题:%@",themeName];
    }).custom(^(UILabel *item, NSString *themeName) {
        item.textColor = [self getIndexColor];
    });

}

-(UIColor *)getIndexColor
{
    if (testIndex%3==0) {
        return [UIColor greenColor];
    }else if (testIndex%3==1){
        return [UIColor blueColor];
    }else if (testIndex%3==2){
        return [UIColor redColor];
    }else{
        return [UIColor cyanColor];
    }
    return nil;
}

@end





