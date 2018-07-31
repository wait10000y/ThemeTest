//
//  WSThemeExtension.h
//  test_WSTheme
//
//  Created by wsliang on 2018/7/31.
//  Copyright © 2018年 wsliang. All rights reserved.
//


#import "WSTheme.h"




typedef enum : NSUInteger {
    WSThemeValueTypeOriginal = 0, // 原始值.
    WSThemeValueTypeJson, // json格式字符串.
    WSThemeValueTypeColor,
    WSThemeValueTypeImage,
    WSThemeValueTypeFont,
    WSThemeValueTypeAttribute,// 属性字典.

    WSThemeValueTypeNone,// 保留类型
} WSThemeValueType;




//typedef void(^WSThemeConfigValueBlock)(id item , id value);

/**
 identifier:theme模板定义的key,keyPath;
 valueType:返回theme模板对应值转换类型;
 valueBlock 返回结果block回调;
 */
typedef WSThemeConfig *(^WSThemeConfigCustomBlock)(NSString *identifier,WSThemeValueType valueType,WSThemeConfigValueBlock valueBlock);

    // 直接指定返回值类型.
typedef WSThemeConfig *(^WSThemeConfigFixedTypeBlock)(NSString *identifier,WSThemeConfigValueBlock valueBlock);



@interface WSThemeExtension : NSObject

@end




@interface WSThemeModel(extension)




    // 获取原生值类型为WSThemeValueTypeOriginal; identifier 支持keyPath格式.
    // 当前线程执行;如果读取网络数据或耗时数据时,使用异步读取方法.
-(id)getDataWithIdentifier:(NSString *)identifier backType:(WSThemeValueType)type;
    // 异步读取数据. complete线程为:NSOperationQueue线程池线程.
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

@interface WSThemeConfig(extension)

    // block, WSThemeConfigValueBlock内容在主线程更新.
@property(nonatomic,copy,readonly) WSThemeConfigCustomBlock custom;

@property(nonatomic,copy,readonly) WSThemeConfigFixedTypeBlock color;


@end






