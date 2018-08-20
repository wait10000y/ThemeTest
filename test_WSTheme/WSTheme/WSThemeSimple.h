//
//  WSThemeSimple.h
//  test_WSTheme
//
//  Created by wsliang on 2018/7/31.
//  Copyright © 2018年 wsliang. All rights reserved.
//

/**
 使用说明:
自定义样式方式如下,可以多层连接下去.
 每次调用 custom() 都会注册一个新的block,每个block都是独立执行.

 void(^WSThemeSimpleConfigValueBlock)(id item , NSString *themeName)
 传回值 item是注册的对象,弱引用不会影响item原对象生命周期;
themeName 是传回当前切换的主题(名称).

#define openUpdateThreadQueue 16 // 数值是可并行执行的线程数.
 默认开启线程池批量更新. 注意回调线程为线程池分配的线程,而非主线程或同一个线程.
 未使用线程池 回调线程为触发推送通知所在线程,即调用 [WSThemeSimple startTheme:] 所在的线程.




 示例:
 __weak typeof(self) weakSelf = self;
 self.textShow.wsThemeSimple.custom(^(UILabel *item, NSString *themeName) {
  NSString *tempStr = [NSString stringWithFormat:@"当前主题:%@",themeName];
 dispatch_async(dispatch_get_main_queue(), ^{
    item.text = tempStr;
 });
 // [item performSelectorOnMainThread:@selector(setText:) withObject:tempStr waitUntilDone:NO];
 }).custom(^(UILabel *item, NSString *themeName) {
 dispatch_async(dispatch_get_main_queue(), ^{
    item.textColor = [weakSelf getThemeColor:themeName];
 });
 });

// 如果未使用线程池,没必要使用链式方式在同一对象上多次注册block回调.

 */
#import <Foundation/Foundation.h>

@class WSThemeSimpleConfig;

typedef void(^WSThemeSimpleConfigValueBlock)(id item , NSString *themeName);
typedef WSThemeSimpleConfig *(^WSThemeSimpleConfigCustomBlock)(WSThemeSimpleConfigValueBlock);

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

// 自定义配置:返回当前注册对象和当前theme对应的model或theme名称.
@property(nonatomic,copy,readonly) WSThemeSimpleConfigCustomBlock custom;

@end


@interface NSObject(WSThemeSimple)
    // 获取 监听文件.
-(WSThemeSimpleConfig *)wsThemeSimple;

@end
