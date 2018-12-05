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




//    NSString *path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
//    path = [path stringByAppendingPathComponent:@"/test2.plist"];



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

    // 指定加载默认主题.
    NSString *lastName = [WSTheme sharedObject].currentThemeName?:@"默认主题";
    [[WSTheme sharedObject] startTheme:lastName];

    
    // 编辑时,不可删除,修改的主题.
    [ThemeEditManager setFixedThemeNames:@[@"默认主题",@"yivian主题"]];
    // 编辑时,加载样式描述模板.
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
