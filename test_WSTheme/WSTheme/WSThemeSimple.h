//
//  WSThemeSimple.h
//  test_WSTheme
//
//  Created by wsliang on 2018/7/31.
//  Copyright © 2018年 wsliang. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WSThemeSimpleConfig;

typedef void(^WSThemeSimpleConfigValueBlock)(id item , NSString *themeName);
typedef WSThemeSimpleConfig *(^WSThemeSimpleConfigConfigBlock)(WSThemeSimpleConfigValueBlock);

@interface WSThemeSimple : NSObject

+(WSThemeSimple *)sharedObject;

    // 所有主题
-(NSArray<NSString *> *)themeNameList;
-(NSString *)currentThemeName;

    // 切换新主题.
-(BOOL)startTheme:(NSString *)theName;

-(BOOL)addThemeWithNameList:(NSArray<NSString *> *)nameList;
-(BOOL)removeThemes:(NSArray<NSString *> *)nameList;


@end


@interface WSThemeSimpleConfig:NSObject
    
    // 空配置:返回当前注册对象和当前theme对应的model
@property(nonatomic,copy,readonly) WSThemeSimpleConfigConfigBlock custom;

@end


@interface NSObject(WSThemeSimple)
    // 获取 监听文件.
-(WSThemeSimpleConfig *)wsThemeSimple;

@end
