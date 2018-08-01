//
//  WSTheme.h
//  Test_LEETheme
//
//  Created by wsliang on 2018/7/13.
//  Copyright © 2018年 wsliang. All rights reserved.
//



/**
 json 格式定义.
1. 支持多层嵌套取值,取值方式为 keypath多层嵌套定义.(数组不支持keypath.)
2. model对象 支持原值,UIColor,UIFont,UIImage,Attributes类型取值. (attributes定义key 参考 NSAttributedString.h)
3. 方法说明里分别指出 对象类型支持转换的格式. 用户可以取原值,自定义转换其他类型.

{
    "defalut":{
        "示例key":"示例value,支持keypath多层嵌套定义."
    },

    "navBarDefine":{
        "title":"我是标题"
        "tinColor":"0x00ff00",
        "barTinColor":"#66DD2134",
        "barTitleAttrs":{
            "NSForegroundColorAttributeName":"2233FF",
            "NSFontAttributeName":22,
            "NSUnderlineStyleAttributeName":2
        }
    },

    "normalImageView":{
        "background":"#EECCCC",
        "defaultImage":"default.jpg",
        "orginImage":"https://www.baidu.com/img/bd_logo.png",
    }


    "_info": {
        "name": "默认主题(唯一)",
        "desc": "主题描述",
        "author": "作者",
        "date":"2018.06"
    }
}

**/

/**
 使用说明
 

 */


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@class WSThemeModel,WSThemeConfig;


/**
 item:注册对象;
 value:数据结果值.
 */
typedef void(^WSThemeConfigValueBlock)(id item , id value);

//TODO: 简洁调用,仅随着theme切换而调用. value = WSThemeModel.
typedef WSThemeConfig *(^WSThemeConfigConfigBlock)(WSThemeConfigValueBlock);

#define WSThemeDefaultThemeName @"default"

// 主程序.
@interface WSTheme : NSObject

+(WSTheme *)sharedObject;

// 所有主题
-(NSArray<NSString *> *)themeNameList;

-(NSString *)currentThemeName;

// 当主题列表为空时,返回一个临时的WSThemeModel.
-(WSThemeModel *)currentThemeModel;
-(WSThemeModel *)themeModelForName:(NSString *)themeName; // themeName是已添加的主题,其他值返回nil;
-(NSDictionary *)themeJsonDictForName:(NSString *)themeName; // 返回 定义json的object对象.

// 切换新主题.
-(BOOL)startTheme:(NSString *)theName;

    // 同名称的主题会被新主题覆盖更新;不同名称的主题执行添加主题更新. override
-(BOOL)addThemeJsonDictList:(NSArray<NSDictionary *> *)dictList withNameList:(NSArray<NSString *> *)nameList;
-(BOOL)removeThemes:(NSArray<NSString *> *)nameList;

@end


// 模板对象 唯一标记 name
@interface WSThemeModel:NSObject
@property(readonly, copy) NSString *name; // 名称 (theme name)

// 快捷创建 model
+(WSThemeModel *)getThemeModelWithDict:(NSDictionary *)themeDict withName:(NSString *)theName;

// 直接赋值json对象格式.
-(BOOL)setThemeDict:(NSDictionary *)themeDict withName:(NSString *)theName;

// 获取指定id对应原始值. identifier使用keypath格式定义.
// TODO: 扩展实现该方法,可以使用数据库等返回对应的数据.
-(id)getValueWithIdentifier:(NSString *)identifier;


@end


@interface WSThemeConfig:NSObject
    // 关联的更新对象.
@property(nonatomic,weak) NSObject *currentObject;

    // 空配置:返回当前注册对象和当前theme对应的model
@property(nonatomic,copy,readonly) WSThemeConfigConfigBlock config;


@end


@interface NSObject(WSTheme)
// 获取 监听文件.
-(WSThemeConfig *)wsTheme;

@end
