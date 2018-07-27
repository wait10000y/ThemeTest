//
//  ThemeEditManager.h
//  TestTheme_sakura
//
//  Created by 王士良 on 2018/6/29.
//  Copyright © 2018年 王士良. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ThemeEditItemModel;
@interface ThemeEditManager : NSObject

// theme主题列表(namelist)
+(NSArray *)themeNameListSystem;
// 所有主题
+(NSArray *)themeNameList;
// 当前主题的名称.
+(NSString *)currentThemeName;

// 切换到指定的主题
+(BOOL)startThemeWithName:(NSString *)themeName;

+(BOOL)removeThemeWithName:(NSString *)themeName;
    // 保存 新theme主题.
+(BOOL)saveNewTheme:(NSArray<NSArray<ThemeEditItemModel *> *> *)editItemList withName:(NSString *)newName;



// 获取 对应theme的定义模板.
+(NSDictionary *)templateDictForTheme:(NSString *)themeName;
    // 获取 对应theme的json定义dict
+(NSDictionary *)definedDictForTheme:(NSString *)themeName;


// 解析指定名称(themeName)theme的jsonDict内容.返回 ThemeEditItemModel的二级数组.
/**
 返回数据以json定义为主,theme模板未定义的字段,ThemeEditItemModel type=ThemeEditItemTypeNone 原生值的形式返回.
 itemList与titleList 数组内容是一一对应关系.

 @itemList 二维数组: NSArray<NSArray<ThemeEditItemModel *> *> 每个section内容.
 @titleList 数组: NSArray<ThemeEditItemModel *> 标题数组 上面数组的section名称;
 @return 是否解析成功.
 */
+(BOOL)parseThemeEditItemList:(NSArray<NSArray<ThemeEditItemModel *> *> **)itemList titleList:(NSArray<ThemeEditItemModel *> **)titleList forTheme:(NSString *)themeName;






@end















/*

 key字段描述dict定义:
 name,desc,order,type,default,enums
 model类定义:
 除了上述属性外还有 keypath,value,mType 等属性.
 type类型:none之外的类型,如果有enums字段,编辑时可枚举选项;
 type类型:none时,没有内容,有下一级内容或者仅描述时;第一级如果有第二级内容时,type应该为none属性;
 type类型:dict时,value值为dict.第一级时,等同none,第二级时,编辑时转换成json字符串,保存时转成dict对象.
字段 default 是模板设定的值,如果主题有值优先主题值.
 必须定义字段:type,如果没有type值:默认type==none,内容全部文本编辑形式;
"global":{"name":"全局设置","desc":"描述信息","keypath":"global","order":101,"type":6,"default":"","enums":{"描述1":"value1","描述2":"value2"}},

 type: color,text,image,font,num,dict,node 字符显示.
 value: nsstring,nsnumber,nsdictionary

 */

typedef enum : NSUInteger { // 排序不可混乱.
    ThemeEditItemTypeNone=0, // 未定义类型等.
    ThemeEditItemTypeNode, // 第一级,有下级目录
    ThemeEditItemTypeColor, // "#ffddffdd"
    ThemeEditItemTypeText, // text类型, 或者无法识别的类型.
    ThemeEditItemTypeFont, // 数字:表示系统字体;{"name":"","size":20}:表示定义字体名称.
    ThemeEditItemTypeImage, // 图片名称,本地路径,url地址等.
    ThemeEditItemTypeNumber, //
    ThemeEditItemTypeDict, //
//    ThemeEditItemTypeEnum, // 枚举类型 模板里有枚举数据.
} ThemeEditItemType;


@interface ThemeEditItemModel : NSObject

@property(nonatomic) NSString *name; // 显示名称,默认值是 key,keypath的最后一段.
@property(nonatomic) NSString *desc; // 描述信息
@property(nonatomic) NSNumber *order; // 显示顺序,排序权值.
@property(nonatomic) NSString *type; // 数据类型.
@property(nonatomic) id defalut; // 默认值.
@property(nonatomic) NSDictionary *enums; // enum类型的选项,有该字段表示值只可选择此列表; key:name , value:原始值的对象包装 string,number

// 编辑时附加字段
@property(nonatomic) id value; // 值,修改时改这里.保存时,保存该值.
@property(nonatomic) NSString *keypath; // keypath
@property(nonatomic) ThemeEditItemType mType; // 转换后的数据类型值.


    // keypath格式 全局位置, 未定义模板. none类型 创建;
+(ThemeEditItemModel*)createWithValue:(id)value withKeypath:(NSString *)keypath;

    // keypath格式 全局位置;
// dict 是keypath对应模板内容.
+(ThemeEditItemModel*)createWithModelDict:(NSDictionary*)dict withKeypath:(NSString *)keypath;


+(ThemeEditItemType)parseItemType:(NSString *)typeStr;
+(NSString *)getItemTypeStr:(ThemeEditItemType)type;


@end






