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


typedef enum : NSUInteger {
    WSThemeValueTypeOriginal = 0, // 原始值.
    WSThemeValueTypeJson, // json格式字符串.
    WSThemeValueTypeColor,
    WSThemeValueTypeImage,
    WSThemeValueTypeFont,
    WSThemeValueTypeAttribute,// 属性字典.

    WSThemeValueTypeNone,// 保留类型
} WSThemeValueType;


/**
 item:注册对象;
 value:根据identifier,valueType查找转换的数据结果值.
 */

typedef void(^WSThemeConfigValueBlock)(id item , id value);

/**
 identifier:theme模板定义的key,keyPath;
 valueType:返回theme模板对应值转换类型;
 valueBlock 返回结果block回调;
 */
typedef WSThemeConfig *(^WSThemeConfigCustomBlock)(NSString *identifier,WSThemeValueType valueType,WSThemeConfigValueBlock valueBlock);

    // 直接指定返回值类型.
typedef WSThemeConfig *(^WSThemeConfigFixedTypeBlock)(NSString *identifier,WSThemeConfigValueBlock valueBlock);


//TODO: 简洁调用,仅随着theme切换而调用.
typedef WSThemeConfig *(^WSThemeConfigMarkBlock)(void(^)(id item));





#define WSThemeDefaultThemeName @"default" // 对应 default.json 配置.

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

-(BOOL)clearCacheData;

@end


// 模板对象 唯一标记 name
@interface WSThemeModel:NSObject
@property(readonly, copy) NSString *name; // 名称 (theme name)

// 创建方式.
+(instancetype)createWithJsonDict:(NSDictionary *)jsonDict withName:(NSString *)theName;
// 已转换的json对象类型.
-(BOOL)loadJsonDict:(NSDictionary *)jsonDict withName:(NSString *)theName;
// json对象定义文件地址.
-(BOOL)loadJsonFile:(NSString *)filePath withName:(NSString *)theName;



    // 获取原生值类型为WSThemeValueTypeOriginal; identifier 支持keyPath格式.
    // 当前线程执行;如果读取网络数据或耗时数据时,使用异步读取方法.
-(id)getDataWithIdentifier:(NSString *)identifier backType:(WSThemeValueType)type;
    // 异步读取数据. complete线程为:NSOperationQueue线程池线程. model是当前对象(可能为空).
-(void)getDataWithIdentifier:(NSString *)identifier backType:(WSThemeValueType)type complete:(void(^)(id value))complete;


// utils
/**
 默认匹配转换. 支持 0x,#或者直接写的三种格式十六进制的字符串. [0xffddffdd,#ffddffdd,ffddffdd], 八位时格式ARGB.六位时RGB.
 支持 NSNumber 类型, 该类型没有alpha项.
 */
-(UIColor *)createColor:(NSString *)colorValue;

/**
 NSNumber,NSSting:默认字体指定字号大小值;
 "fontName:20":指定字体名称和字号大小,:分隔符;
 */
-(UIFont *)createFont:(NSString *)fontValue;

// 内容 转换成 json格式的字符串.
-(NSString *)createJsonText:(id)value;
/**
  支持的文件名类型:
  "imgName" "imgName.jpg" "https://www.test.com/imgName.png"
 */
-(UIImage *)createImage:(NSString *)imgValue;

/**
 支持 NSAttributedString.h 定义的 attributeName字符串转换的key.
 对应的value值font,color类型自动转换,number,string使用原值,其他的属性暂不支持.
 */
-(NSDictionary *)createAttributes:(NSDictionary *)attrsValue;


@end


@interface WSThemeConfig:NSObject

// block, WSThemeConfigValueBlock内容在主线程更新.
@property(nonatomic,copy,readonly) WSThemeConfigCustomBlock custom;

@property(nonatomic,copy,readonly) WSThemeConfigFixedTypeBlock color;

@end

@interface NSObject(WSTheme)

-(WSThemeConfig *)wsTheme;

@end
