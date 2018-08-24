//
//  WSTheme.h
//  Test_LEETheme
//
//  Created by wsliang on 2018/7/13.
//  Copyright © 2018年 wsliang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


extern NSNotificationName const WSThemeUpdateNotificaiton;

typedef enum : NSUInteger {
    WSThemeValueTypeJson=0, // json格式字符串.
    WSThemeValueTypeColor=1,
    WSThemeValueTypeFont=2,
    WSThemeValueTypeAttribute=3,// 属性字典.
    WSThemeValueTypeOriginal=4, // jsonDict对象直接读值.
    WSThemeValueTypeImage, // 远程或主题目录内名称.
    WSThemeValueTypeData, // 远程或主题目录内名称
} WSThemeValueType;


@class WSTheme,WSThemeModel;
@protocol WSThemeChangeDelegate<NSObject>
@required
-(void)wsThemeHasChanged:(NSString *)themeName themeModel:(WSThemeModel *)themeModel;
@end

// 主程序.
@interface WSTheme : NSObject
    // 可使用kvo监听该属性变化. 注意数据同步问题:在切换主题后,注册属性监听时,需自主更新一次.
@property(nonatomic,readonly) NSArray<NSString *> *themeNameList; // 所有主题
@property(nonatomic,readonly) NSString *currentThemeName; // 当前主题名称.
@property(nonatomic,readonly) WSThemeModel *currentThemeModel; // 当前主题对应的model. 当主题列表为空时,返回一个临时的WSThemeModel.

// 单例模式 未处理其他形式创建对象.
+(WSTheme *)sharedObject;

// 切换新主题.
-(BOOL)startTheme:(NSString *)theName;

    // 同名称的主题会被新主题覆盖更新;不同名称的主题执行添加主题更新. override,返回更新或添加的个数.
-(int)addThemeWithJsonDictList:(NSArray<NSDictionary *> *)dictList withNameList:(NSArray<NSString *> *)nameList;
//-(int)addThemeWithJsonDictList:(NSArray<NSDictionary *> *)dictList withResourcePath:(NSArray<NSString *> *)pathList withNameList:(NSArray<NSString *> *)nameList;
// 同名称的主题会被新主题覆盖更新;
-(int)addThemeWithPackageList:(NSArray<NSString *> *)packagePathList withThemeNamList:(NSArray<NSString *> *)themeNameList;

//删除一个主题,主题文件夹一并删除.不可删除正在使用的主题.
-(BOOL)removeThemes:(NSArray<NSString *> *)nameList;

// ====== delegate 委托模式 ======
@property(nonatomic,readonly) NSArray<WSThemeChangeDelegate> *delegateList; // 添加的delegate列表.
// 注意数据同步问题:在切换主题后,添加委托对象时,需自主更新一次.
-(void)addDelegate:(id<WSThemeChangeDelegate>)theDelegate;
-(void)removeDelegate:(id<WSThemeChangeDelegate>)theDelegate;

// === utils ===
-(WSThemeModel *)themeModelForName:(NSString *)themeName; // themeName是已添加的主题,其他值返回没有jsonDict等资源的model对象;

@end


/**
 完整资源包目录结构:
 WSTheme/themeList/[thmename]/  //  主题目录.
 WSTheme/themeList/[thmename]/[themeJsonName]  //  主题json主文件.
 WSTheme/themeList/[thmename]/[files]/[fileName]  //  主题资源文件位置.
 WSTheme/themeList/[thmename]/[cacheFiles]/[fileName]  // 缓存目录
 WSTheme/themeList/[themeNameListName]  // 当前主题名称地址
 WSTheme/themeList/[themeNameCurrentName]  //  主题名称列表地址
 
 */

#define WSThemeFileManager_themeThemeListMainPath @"WSTheme/themeList"
#define WSThemeFileManager_themeResourcePath @"files"
#define WSThemeFileManager_themeCacheFilesPath @"cacheFiles"

#define WSThemeFileManager_themeJsonName @"theme.json"
#define WSThemeFileManager_themeNameListName @"_themeNameList.plist"
#define WSThemeFileManager_themeNameCurrentName @"_themeNameCurrent.txt"

@interface WSThemeFile:NSObject
@property(nonatomic,readonly) NSString *themePath;

-(instancetype)initWithThemePackagePath:(NSString *)thePath;
-(instancetype)initWithThemeName:(NSString *)theThemeName;
-(void)setThemePackagePath:(NSString *)thePath;
-(void)setThemePackagePathWithName:(NSString *)theThemeName;


-(NSDictionary *)loadThemeDict;
-(NSData *)loadThemeResourceWithName:(NSString *)fileName;
-(NSData *)loadThemeCacheFileWithName:(NSString *)fileName;

-(BOOL)saveThemeDict:(NSDictionary *)themeDict;
-(BOOL)saveThemeResourceData:(NSData *)theData withName:(NSString *)fileName; // theData==nil时,为删除文件.
-(BOOL)saveThemeResourceFile:(NSString *)theFilePath withName:(NSString *)fileName; // theFilePath==nil时,为删除文件.
-(BOOL)saveThemeCacheData:(NSData *)theData withName:(NSString *)fileName; // theData==nil时,为删除文件.

-(BOOL)copyThemeToPackagePath:(NSString *)thePath;
-(BOOL)removeTheme;

    // --- path utils ---
- (NSString *)getThemeDictPath;
- (NSString *)getThemeResourcePathWithName:(NSString *)fileName;
- (NSString *)getThemeCachePathWithName:(NSString *)fileName;

    // --- class method ---
+(NSArray *)themeNameList; // 主题列表
+(NSString *)themeCurrentName; // 当前主题记录
+(BOOL)themeNameListSave:(NSArray *)themeNameList;
+(BOOL)themeCurrentNameSave:(NSString *)themeName;

+(BOOL)saveNewTheme:(NSString *)themeName withPackagePath:(NSString *)thePath;
+(BOOL)saveNewTheme:(NSString *)themeName withThemeDict:(NSDictionary *)themeDict;

+(NSString *)themeMainPath:(NSString *)themeName; // theme主目录

@end


@interface WSThemeModel:NSObject
@property(nonatomic,readonly) NSString *name; // 名称 (themeName,唯一标记)
@property(nonatomic,readonly) NSDictionary *themeDict; // 定义 jsonDict

+(instancetype)createWithName:(NSString *)theName; // 创建方式. theName 主题名称;资源已存在的创建方式.
-(BOOL)loadThemeDataWithName:(NSString *)themeName; // 读取资源. 也可直接重新加载成 themeName的主题内容.

+(instancetype)createWithPackagePath:(NSString *)thePath;
-(BOOL)loadThemeDataWithPackagePath:(NSString *)thePath;

    // 获取identifier对应的值
-(id)getDataWithIdentifier:(NSString *)identifier backType:(WSThemeValueType)type;
    // 异步获取identifier对应的值
-(void)getDataWithIdentifier:(NSString *)identifier backType:(WSThemeValueType)type complete:(void(^)(id value))complete;

    // utils
-(UIColor *)createColor:(NSString *)colorValue;
-(UIFont *)createFont:(NSString *)fontValue;
-(NSString *)createJsonText:(id)value;
-(UIImage *)createImage:(NSString *)imgValue;
-(NSData *)createData:(NSString *)theDataName;
-(NSDictionary *)createAttributes:(NSDictionary *)attrsValue;

// 反向转换数据. image,data数据保存到对应主题资源目录下,返回值为name名称.
-(NSString *)parseColor:(UIColor *)theColor; // UIColor转成 #ARGB形式字符串.
-(NSString *)parseFont:(UIFont *)theFont; // UIFont 转成 name:size 的字符串形式.
-(NSString *)parseImage:(UIImage *)theImage withName:(NSString *)theName; //更新theImage到当前theme主题(self.name)的资源目录中, theName:保存是theImage值文件名称.
-(NSString *)parseData:(NSData *)theData withName:(NSString *)theName; // 保存方式同 image.
-(NSDictionary *)parseAttributes:(NSDictionary *)theAttributes; // 转存成描述性的字典对象.
-(id)parseJsonText:(NSString *)theJsonText; // 转成json对象格式.

@end



@class WSThemeConfig;
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


@interface WSThemeConfig:NSObject

@property(nonatomic,copy,readonly) WSThemeConfigCustomBlock custom; // 自定义格式,nil空调用等.

@property(nonatomic,copy,readonly) WSThemeConfigFixedTypeBlock original; // 原始值
@property(nonatomic,copy,readonly) WSThemeConfigFixedTypeBlock text; // jsonText,description
@property(nonatomic,copy,readonly) WSThemeConfigFixedTypeBlock color; // UIColor
@property(nonatomic,copy,readonly) WSThemeConfigFixedTypeBlock font; // UIFont
@property(nonatomic,copy,readonly) WSThemeConfigFixedTypeBlock image; // UIImage,nil
@property(nonatomic,copy,readonly) WSThemeConfigFixedTypeBlock data; // NSData,nil
@property(nonatomic,copy,readonly) WSThemeConfigFixedTypeBlock attribute; // dict

@end

//扩展
@interface NSObject(WSTheme)

-(WSThemeConfig *)wsTheme;

@end

