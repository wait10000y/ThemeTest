//
//  AppDelegate.m
//  test_WSTheme
//
//  Created by wsliang on 2018/7/18.
//  Copyright © 2018年 wsliang. All rights reserved.
//

#import "AppDelegate.h"

#import "WSTheme.h"
#import "ThemeEditManager.h"
#import "TestCoderObject.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

//    UIFont *temp = [UIFont systemFontOfSize:20];
//
// NSNumber *num1 = [TransDataUtils parseNumberWithValue:@"12345"];
//    NSNumber *num2 = [TransDataUtils performSelector:@selector(parseNumberWithValue:) withObject:@"56789"];
//
//    NSLog(@"==== num1:%@ , num2:%@ ====",num1,num2);
//
//
//        // TODO:test
//    NSLog(@"==== 默认字体:%@ , name:%@ ,fName:%@ ====",temp,temp.fontName,temp.familyName);
//
//
//
//
//    TestCoderObject *tc1 = [TestCoderObject new];
//    tc1.name = @"name123";
//    tc1.titles = @[@"title123"];
//
////    TestCoderObject *tc2 = [TestCoderObject new];
////    tc2.name = @"name456";
////    tc2.titles = @[@"title456"];
//
//    NSData *arc1 = [NSKeyedArchiver archivedDataWithRootObject:tc1];
//
//    TestCoderObject *tempTc1 = [NSKeyedUnarchiver unarchiveObjectWithData:arc1];
//
//    NSLog(@"----tc1: name:%@, title:%@ ----",tempTc1.name,tempTc1.titles);



    NSString *path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    path = [path stringByAppendingPathComponent:@"/test1/test2.plist"];


    BOOL isOK = NO;
    NSData *tempData = [NSKeyedArchiver archivedDataWithRootObject:@"我是一个字符串123456"];
    isOK = [[NSFileManager defaultManager] createFileAtPath:path contents:tempData attributes:nil];
//    if(![[NSFileManager defaultManager] fileExistsAtPath:path]){
//    }

//    BOOL isOK = [NSKeyedArchiver archiveRootObject:@"我是一个字符串123456" toFile:path];

    NSLog(@"==== 写文件是否成功:%d ====",isOK);


    [self loadWSThemeTestData];

    return YES;
}


-(void)loadWSThemeTestData
{

// 添加其他主题.
    NSMutableArray *themeJsonList = [NSMutableArray new];
    NSMutableArray *themeNameList = [NSMutableArray new];

    NSArray *tempImages = @[
                            @"https://avatar.csdn.net/B/F/B/1_red_stone1.jpg",
                        @"http://cdn.cocimg.com/assets/img/logo.png?v=201510272",
                        @"http://top.cocoachina.com/uploads/20180731/63aebd0110cc696f39607b146040b0b3.png",
                        @"http://top.cocoachina.com/uploads/20180806/c62d8f3b818687a8316e115868a7fbb1.jpg",
                        @"http://top.cocoachina.com/uploads/20180713/c42d320a6df48d93130e9ee3ab1c1b97.jpg",
                        ];
    for (int it=0; it<tempImages.count; it++) {
        NSDictionary *themeJson = @{
                                    @"color":@{
                                            @"textColor":@(arc4random())
                                            },
                                    @"imageView":@{
                                        @"background":@(arc4random()),
                                        @"defaultImage":@"testpic.png",
                                        @"orginImage":tempImages[it]
                                    },
                                    @"normal_backgroundColor":@(arc4random()),
                                    };

        NSString *tName = [NSString stringWithFormat:@"测试model%d",it+1];

        [themeJsonList addObject:themeJson];
        [themeNameList addObject:tName];
    }
    [[WSTheme sharedObject] addThemeWithJsonDictList:themeJsonList withNameList:themeNameList];


// 添加其他默认主题.
    NSDictionary *defaultObject = [self loadResourceTheme:@"default"];
    NSDictionary *yivianObject = [self loadResourceTheme:@"yivian"];
    if (defaultObject && yivianObject) {
        [[WSTheme sharedObject] addThemeWithJsonDictList:@[defaultObject,yivianObject] withNameList:@[@"默认主题",@"yivian主题"]];
    }

    // 为主题添加模板定义文件.
    [[WSTheme sharedObject] setThemeTemplateDict:[self loadResourceTheme:@"default_tl"] forName:@"默认主题"];
    [[WSTheme sharedObject] setThemeTemplateDict:[self loadResourceTheme:@"yivian_tl"] forName:@"yivian主题"];
    [[WSTheme sharedObject] setThemeTemplateDict:[self loadResourceTheme:@"default_tl"] forName:nil]; // 全局默认模板

    // 指定加载默认主题.
    NSString *lastName = [WSTheme sharedObject].currentThemeName?:@"默认主题";
    [[WSTheme sharedObject] startTheme:lastName];

    // 编辑时,不可删除,修改的主题.
    [ThemeEditManager setSystemThemeNames:@[@"默认主题",@"yivian主题"]];
    // 编辑时,加载默认模板.
    [ThemeEditManager setThemeTemplateDefault:[self loadResourceTheme:@"default_tl"]];

}

-(NSDictionary *)loadResourceTheme:(NSString *)themeName
{
    NSString *jsonPath = [[NSBundle mainBundle] pathForResource:themeName ofType:@"json"];
    if (jsonPath) {
        NSData *defaultData = [NSData dataWithContentsOfFile:jsonPath];
        return [NSJSONSerialization JSONObjectWithData:defaultData options:0 error:nil];
    }
    return nil;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
