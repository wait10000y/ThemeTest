//
//  ThemeEditManager.h
//  Created on 2018/6/29.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class ThemeEditItemModel;
@interface ThemeEditManager : NSObject

+(void)setFixedThemeNames:(NSArray<NSString *> *)themeNameList; // 设置不可修改删除的主题列表.
+(void)setThemeTemplateDefault:(NSDictionary *)theTemplate; //设置默认的主题编辑模板.
+(void)setThemeTemplateDefaultFileUrl:(NSURL *)theUrl;

// --- 主题管理部分 ---
+(NSArray *)themeNameListFixed; // theme主题列表(设置的不可编辑的主题列表)
+(NSArray *)themeNameList; // 所有主题(包括 themeNameListFixed )
+(NSString *)currentThemeName; // 当前主题的名称.

+(BOOL)startThemeWithName:(NSString *)themeName; // 切换到指定的主题
+(BOOL)removeThemeWithName:(NSString *)themeName; // 删除一个主题

+(NSString *)getThemePathWithThemeName:(NSString *)themeName; // 获取 指定主题的目录地址.

// --- 主题编辑部分 ---
-(NSString *)createThemeCopyFromTheme:(NSString *)themeName; // 返回新路径.

// 解析themeDict成 ThemeEditItemModel对象列表.
-(BOOL)parseThemeEditItemList:(NSArray<NSArray<ThemeEditItemModel *> *> **)itemList titleList:(NSArray<ThemeEditItemModel *> **)titleList;

-(BOOL)newThemeSaveResource:(NSData *)theData forFileName:(NSString *)fileName; // 添加资源
-(BOOL)newThemeRemoveResourceWithFileName:(NSString *)fileName; // 删除资源
-(NSData *)newThemeGetResourceWithFileName:(NSString *)fileName; // 获取资源

-(BOOL)saveNewTheme:(NSArray<NSArray<ThemeEditItemModel *> *> *)editItemList withName:(NSString *)newName hasPackage:(BOOL)hasPackage;

+(NSString *)newThemeMainPath:(BOOL)needClear; // 复制目录到此时,需要删除原目录.

@end















/*

 key字段描述dict定义:
 name,desc,order,type,default,enums,attachs
 model类定义:
 除了上述属性外还有 keypath,value,mType 等属性.
 type类型:none之外的类型,如果有enums字段,编辑时可枚举选项;
 type类型:none时,没有内容,有下一级内容或者仅描述时;第一级如果有第二级内容时,type应该为none属性;
 type类型:dict时,value值为dict.第一级时,等同none,第二级时,编辑时转换成json字符串,保存时转成dict对象.
 字段 default 是模板设定的值,如果主题有值优先主题值.
 字段 attachs 图片的size设置,其他未做定义. {... ,"attachs":"{45,45}"}

 必须定义字段:type,如果没有type值:默认type==none,内容全部文本编辑形式;
"global":{"name":"全局设置","desc":"描述信息","keypath":"global","order":101,"type":6,"default":"","enums":{"描述1":"value1","描述2":"value2"}},

 type: color,text,image,font,data,num,dict,node,none 字符显示.
 value: nsstring,nsnumber,nsdictionary

 */

typedef enum : NSUInteger {
    ThemeEditItemTypeNone=0, // 未定义类型等.
    ThemeEditItemTypeNode, // 第一级,有下级目录
    ThemeEditItemTypeColor, // "#ffddffdd"
    ThemeEditItemTypeText, // text类型, 或者无法识别的类型.
    ThemeEditItemTypeFont, // 数字:表示系统字体;{"name":"","size":20}:表示定义字体名称.
    ThemeEditItemTypeImage, // 图片名称,本地路径,url地址等.
    ThemeEditItemTypeData, // data类型的资源内容. 配置名称和image类型相同.
    ThemeEditItemTypeNumber, //
    ThemeEditItemTypeDict, //
//    ThemeEditItemTypeEnum, // 枚举类型 模板里有枚举数据. 可以是上面所有类型的枚举.
} ThemeEditItemType;

// 和上面枚举定义一一对应.注意顺序.
#define ThemeEditItemModelTypeList  (@[@"none", @"node", @"color", @"text", @"font", @"image",@"data", @"num", @"dict"])
#define ThemeEditItemModelTypeDescList  (@[@"未定义", @"节点", @"颜色", @"文字", @"字体", @"图片",@"数据", @"数字", @"字典"])

@interface ThemeEditItemModel : NSObject

@property(nonatomic) NSString *name; // 显示名称,默认值是 key,keypath的最后一段.
@property(nonatomic) NSString *desc; // 描述信息
@property(nonatomic) NSNumber *order; // 显示顺序,排序权值.
@property(nonatomic) NSString *type; // 数据类型.
@property(nonatomic) id defalut; // 默认值.
@property(nonatomic) NSDictionary *enums; // enum类型的选项,有该字段表示值只可选择此列表; key:name , value:原始值的对象包装 string,number
@property(nonatomic) id attachs; // 其他附加值,自定义附加值.

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
+(NSString *)getItemTypeDescStr:(ThemeEditItemType)type;

// utils
-(UIColor *)createColor;
-(UIFont *)createFont;
-(NSString *)createJsonText;
-(UIImage *)createImage;
-(NSData *)createData;
-(NSDictionary *)createAttributes;

    // 反向转换数据. image,data数据保存到对应主题资源目录下,返回值为name名称.
-(NSString *)parseColor:(UIColor *)theColor;
-(NSString *)parseFont:(UIFont *)theFont;
-(NSString *)parseImage:(UIImage *)theImage withName:(NSString *)theName; // name:保存是value值,文件名称,url地址等.
-(NSString *)parseData:(NSData *)theData withName:(NSString *)theName;
-(NSDictionary *)parseAttributes:(NSDictionary *)theAttributes; // 转存成描述性的字典对象.
-(id)parseJsonText:(NSString *)theJsonText; // 转成json对象格式.

@end






