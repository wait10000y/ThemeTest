//
//  AppDelegate.m
//  test_WSTheme
//
//  Created by wsliang on 2018/7/18.
//  Copyright © 2018年 wsliang. All rights reserved.
//

#import "AppDelegate.h"

#import "WSTheme.h"
#import "TransDataUtils.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    UIFont *temp = [UIFont systemFontOfSize:20 weight:UIFontWeightBold];

 NSNumber *num1 = [TransDataUtils parseNumberWithValue:@"12345"];
    NSNumber *num2 = [TransDataUtils performSelector:@selector(parseNumberWithValue:) withObject:@"56789"];

    NSLog(@"==== num1:%@ , num2:%@ ====",num1,num2);


        // TODO:test
    NSLog(@"==== 默认字体:%@ , name:%@ ,fName:%@ ====",temp,temp.fontName,temp.familyName);

    [self loadWSThemeTestData];

    return YES;
}


-(void)loadWSThemeTestData
{
    // 添加 默认主题
    NSString *defaultName = WSThemeDefaultThemeName;
    NSDictionary *jsonObject = [self loadResourceTheme:defaultName];
    if (jsonObject) {
        [[WSTheme sharedObject] addThemeJsonDictList:@[jsonObject] withNameList:@[defaultName]];
    }

// 添加其他主题.
    NSMutableArray *themeJsonList = [NSMutableArray new];
    NSMutableArray *themeNameList = [NSMutableArray new];
    for (int it=0; it<3; it++) {
        NSDictionary *themeJson = @{
                                    @"color":@{
                                            @"textColor":@(arc4random())
                                            }
                                    };

        NSString *tName = [NSString stringWithFormat:@"测试model%d",it+1];

        [themeJsonList addObject:themeJson];
        [themeNameList addObject:tName];
    }
    [[WSTheme sharedObject] addThemeJsonDictList:themeJsonList withNameList:themeNameList];

// 添加其他主题.
    NSDictionary *yivianObject = [self loadResourceTheme:@"yivian"];
    if (yivianObject) {
        [[WSTheme sharedObject] addThemeJsonDictList:@[yivianObject] withNameList:@[@"yivian"]];
    }

    // 指定加载默认主题.
    NSString *lastName = [WSTheme sharedObject].currentThemeName?:WSThemeDefaultThemeName;
    [[WSTheme sharedObject] startTheme:lastName];

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
