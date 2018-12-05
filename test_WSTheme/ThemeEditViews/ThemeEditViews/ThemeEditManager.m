//
//  ThemeEditManager.m
//  Created on 2018/6/29.

#import "ThemeEditManager.h"

#import "WSTheme.h"

static NSArray *systemThemeList;
static NSDictionary *templateJsonDict;
static NSURL *templateJsonDictUrl;

@implementation ThemeEditManager
{
    WSThemeFile *fileUtil;
}
+(void)setFixedThemeNames:(NSArray<NSString *> *)themeNameList
{
    systemThemeList = themeNameList;
}

+(void)setThemeTemplateDefault:(NSDictionary *)theTemplate
{
    templateJsonDict = theTemplate;
}

+(void)setThemeTemplateDefaultFileUrl:(NSURL *)theUrl
{
    templateJsonDictUrl = theUrl;
}

    // theme主题列表(namelist)
+(NSArray *)themeNameListFixed
{
    return systemThemeList;
}

+(NSArray *)themeNameList
{
    NSArray *allNames = [[WSTheme sharedObject] themeNameList];
    return allNames;
}

    // 当前主题的名称.
+(NSString *)currentThemeName
{
    return [WSTheme sharedObject].currentThemeName;
}

+(BOOL)startThemeWithName:(NSString *)themeName
{
    return [[WSTheme sharedObject] startTheme:themeName];
}

+(BOOL)removeThemeWithName:(NSString *)themeName
{
    if (themeName) {
        return [[WSTheme sharedObject] removeThemes:@[themeName]];
    }
    return NO;
}

+(NSString *)getThemePathWithThemeName:(NSString *)themeName
{
    return [WSThemeFile themeMainPath:themeName];
}










- (instancetype)init
{
    self = [super init];
    if (self) {
        fileUtil = [WSThemeFile new];
    }
    return self;
}


-(NSString *)createThemeCopyFromTheme:(NSString *)themeName
{
    [fileUtil setThemePackagePathWithName:themeName];
    NSString *tempPath = [ThemeEditManager newThemeMainPath:YES];
    BOOL hasCopy = [fileUtil copyThemeToPackagePath:tempPath];
    if (hasCopy) {
        [fileUtil setThemePackagePath:tempPath];
        return tempPath;
    }
    return nil;
}

-(BOOL)newThemeSaveResource:(NSData *)theData forFileName:(NSString *)fileName
{
    return [fileUtil saveThemeResourceData:theData withName:fileName];
}

-(BOOL)newThemeRemoveResourceWithFileName:(NSString *)fileName
{
    return [fileUtil saveThemeResourceData:nil withName:fileName];
}

-(NSData *)newThemeGetResourceWithFileName:(NSString *)fileName
{
    return [fileUtil loadThemeResourceWithName:fileName];
}


    // 解析指定名称(themeName)theme的jsonDict内容.返回 ThemeEditItemModel的二级数组.
/**
 返回数据以json定义为主,theme模板未定义的字段,ThemeEditItemModel type=ThemeEditItemTypeNone 原生值的形式返回.

 @itemList 二维数组: NSArray<NSArray<ThemeEditItemModel *> *> 每个section内容.
 @titleList 数组: NSArray<ThemeEditItemModel *> 标题数组 上面数组的section名称;
 @return 是否解析成功.
 */
-(BOOL)parseThemeEditItemList:(NSArray<NSArray<ThemeEditItemModel *> *> **)itemList titleList:(NSArray<ThemeEditItemModel *> **)titleList
{
    NSDictionary *jsonDict = [fileUtil loadThemeDict];
    if (!jsonDict || jsonDict.count==0) {
        return NO;
    }

    NSDictionary *templateDict = templateJsonDict;
    if (!templateDict && templateJsonDictUrl) {
        NSData *defaultData = [NSData dataWithContentsOfURL:templateJsonDictUrl];
        templateDict = [NSJSONSerialization JSONObjectWithData:defaultData options:0 error:nil];
    }
    // 解析数据. 按照 二级模板 解析.

    // 解析 第一层 title列表.
    NSMutableArray *titleItemModelList = [NSMutableArray new];
    NSArray *titleKeyList = jsonDict.allKeys;
    for (NSString *titleKey in titleKeyList) {
        NSDictionary *titleTlDict = [templateDict objectForKey:titleKey];
        ThemeEditItemModel *titleModel;
        if(titleTlDict){
            titleModel = [ThemeEditItemModel createWithModelDict:titleTlDict withKeypath:titleKey];
        }else{
            titleModel = [ThemeEditItemModel createWithValue:nil withKeypath:titleKey];
            NSDictionary *tempValue = [jsonDict objectForKey:titleKey];
            BOOL hasSub = [tempValue isKindOfClass:[NSDictionary class]] && (tempValue.count > 0);
            if (hasSub) {
                titleModel.type = [ThemeEditItemModel getItemTypeStr:ThemeEditItemTypeNode];
                titleModel.mType = ThemeEditItemTypeNode;
            }
        }
        [titleItemModelList addObject:titleModel];
    }

    // 排序.
    [titleItemModelList sortUsingComparator:^NSComparisonResult(ThemeEditItemModel *info1, ThemeEditItemModel *info2) {
        return [info1.order compare:info2.order];
    }];


    // 解析第二层数据.
    NSMutableArray *subItemModelList = [NSMutableArray new];
    for (int it=0; it<titleItemModelList.count; it++) {

        NSMutableArray *tempModelList = [NSMutableArray new];
        ThemeEditItemModel *titleModel = titleItemModelList[it]; // 如果有第二级内容,第一级属性默认node.
        NSString *titleKey = titleModel.keypath;
        NSDictionary *level1Dict = [jsonDict objectForKey:titleKey];
        if(titleModel.mType != ThemeEditItemTypeNode){ // 第一级不是 Node 配置.
            titleModel.defalut = titleModel.value = level1Dict;
            [tempModelList addObject:titleModel];
        }else{
                // 解析 第二层数据
            [level1Dict enumerateKeysAndObjectsUsingBlock:^(NSString *key,id obj, BOOL * stop) {
                NSString *keypath = [titleKey stringByAppendingFormat:@".%@",key];
                NSDictionary *tlModel = [templateDict objectForKey:keypath];
                ThemeEditItemModel *subModel;
                if (tlModel) {
                    subModel = [ThemeEditItemModel createWithModelDict:tlModel withKeypath:keypath];
                }else{
                    subModel = [ThemeEditItemModel createWithValue:obj withKeypath:keypath];
                    subModel.name = key;
                }
                subModel.defalut = subModel.value = obj;
                [tempModelList addObject:subModel];
            }];

            [tempModelList sortUsingComparator:^NSComparisonResult(ThemeEditItemModel *info1, ThemeEditItemModel *info2) {
                return [info1.order compare:info2.order];
            }];

        }

        [subItemModelList addObject:tempModelList];
    }

    *titleList = titleItemModelList;
    *itemList = subItemModelList;

    return YES;
}


-(NSDictionary *)parseThemeJsonDictFromEditItemList:(NSArray<NSArray<ThemeEditItemModel *> *> *)editItemList
{
        // 生成jsonDict
    NSMutableDictionary *tempJsonDict = [[NSMutableDictionary alloc] initWithCapacity:editItemList.count];

    for (NSArray *itemList in editItemList) {
        ThemeEditItemModel *firstModel = [itemList firstObject];
        NSArray *keyAll = [firstModel.keypath componentsSeparatedByString:@"."];
        if (keyAll.count > 1) { // 判断是不是一级改编的.
                                // find 第一级key.
            NSString *key1 = [keyAll firstObject];
            NSMutableDictionary *subDict = [[NSMutableDictionary alloc] initWithCapacity:itemList.count];
            [tempJsonDict setObject:subDict forKey:key1];
        }

        for (ThemeEditItemModel *itemModel in itemList) {
            [tempJsonDict setValue:itemModel.value?:@"" forKeyPath:itemModel.keypath];
        }
    }
    return tempJsonDict;
}


    // 保存 新theme主题. hasPackage 是否有资源文件(文件夹的形式保存)
-(BOOL)saveNewTheme:(NSArray<NSArray<ThemeEditItemModel *> *> *)editItemList withName:(NSString *)newName hasPackage:(BOOL)hasPackage
{
    // 判断默认值 // 不可覆盖 themeNameListFixed 列表中的主题.
    if(newName ==nil || editItemList.count==0 || [[ThemeEditManager themeNameListFixed] containsObject:newName]){
        return NO;
    }
        // 保存
    NSDictionary *tempJsonDict = [self parseThemeJsonDictFromEditItemList:editItemList];
    if (!tempJsonDict) { return NO; }

    if(hasPackage && fileUtil.themePath){
        BOOL isOK = [fileUtil saveThemeDict:tempJsonDict]; // 保存到缓存目录.
        if (isOK) {
            // 添加到theme主题列表中.
            return [[WSTheme sharedObject] addThemeWithPackageList:@[[fileUtil themePath]] withThemeNamList:@[newName]];
        }
        return NO;
    }
    return [[WSTheme sharedObject] addThemeWithJsonDictList:@[tempJsonDict] withNameList:@[newName]];
}






    // 复制目录到此时,需要删除原目录.
+(NSString *)newThemeMainPath:(BOOL)needClear
{
    NSString *tempPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"tempNewTheme"];
    if(needClear){
        NSFileManager *fm = [NSFileManager defaultManager];
        if ([fm fileExistsAtPath:tempPath]) {
            [fm removeItemAtPath:tempPath error:nil];
        }
    }
        //    [fm createDirectoryAtPath:tempPath withIntermediateDirectories:YES attributes:nil error:nil];
    return tempPath;
}


@end




















@implementation ThemeEditItemModel

-(void)setValue:(id)value forUndefinedKey:(NSString *)key
{

}

//-(void)setType:(NSString *)type
//{
//    _type = type;
//    _mType = [ThemeEditItemModel parseItemType:type];
//}

+(ThemeEditItemModel*)createWithValue:(id)value withKeypath:(NSString *)keypath
{
    return [self createWithName:keypath type:ThemeEditItemTypeNone order:nil value:value withKeypath:keypath];
}

+(ThemeEditItemModel*)createWithName:(NSString *)theName type:(ThemeEditItemType)type order:(NSNumber*)order value:(id)value withKeypath:(NSString *)keypath
{
    if (!keypath) { return nil; }
    ThemeEditItemModel *item = [[ThemeEditItemModel alloc] init];
    item.value = item.defalut = value;
    item.order = order?:@(NSIntegerMax);
    item.mType = type;
    item.name = theName?:keypath;
    item.keypath = keypath;

    /**
        if (value) {
            if ([value isKindOfClass:[NSDictionary class]]) {
                item.mType = ThemeEditItemTypeDict;
            }else if ([value isKindOfClass:[NSString class]]){
                item.mType = ThemeEditItemTypeText;
            }else if ([value isKindOfClass:[NSNumber class]]){
                item.mType = ThemeEditItemTypeNumber;
            }else if([value isKindOfClass:[NSNull class]]){
                item.mType = ThemeEditItemTypeText;
                item.value = item.defalut = @"";
            }else{
                item.mType = ThemeEditItemTypeText;
            }
        }
     
     */


    return item;
}
+(ThemeEditItemModel*)createWithModelDict:(NSDictionary*)dict withKeypath:(NSString *)keypath
{
    if (![dict isKindOfClass:[NSDictionary class]] || (!keypath && ![dict objectForKey:@"keypath"])) {
        return nil;
    }

    ThemeEditItemModel *item = [[ThemeEditItemModel alloc] init];
    [item setValuesForKeysWithDictionary:dict];

    item.keypath = keypath;
    item.mType = [self parseItemType:item.type];
    if (item.name == nil) { item.name = keypath; }

//TODO: 如果其他类型.关键环节预加载.
//    if (item.mType == ThemeEditItemTypeNone) {
//
//    }

    return item;
}

+(ThemeEditItemType)parseItemType:(NSString *)typeStr
{
    if (typeStr) {
        // color,text,image,font,num,dict,node 字符显示
        NSInteger index = [ThemeEditItemModelTypeList indexOfObject:typeStr];
        if (index != NSNotFound) {
            return (ThemeEditItemType)index;
        }
    }
    return ThemeEditItemTypeNone;
}

+(NSString *)getItemTypeStr:(ThemeEditItemType)type
{
    NSArray *typeStrArr = ThemeEditItemModelTypeList;
    if (typeStrArr.count>type) {
        return typeStrArr[type];
    }
    return @"none";
}

+(NSString *)getItemTypeDescStr:(ThemeEditItemType)type
{
    NSArray *typeStrArr = ThemeEditItemModelTypeDescList;
    if (typeStrArr.count>type) {
        return typeStrArr[type];
    }
    return @"未知";
}

-(UIColor *)createColor
{
    return [[WSTheme sharedObject].currentThemeModel createColor:self.value];
}

-(UIFont *)createFont
{
return [[WSTheme sharedObject].currentThemeModel createFont:self.value];
}

-(NSString *)createJsonText
{
return [[WSTheme sharedObject].currentThemeModel createJsonText:self.value];
}

-(UIImage *)createImage
{
return [[WSTheme sharedObject].currentThemeModel createImage:self.value];
}

-(NSData *)createData
{
return [[WSTheme sharedObject].currentThemeModel createData:self.value];
}

-(NSDictionary *)createAttributes
{
return [[WSTheme sharedObject].currentThemeModel createAttributes:self.value];
}

// -----反向注册 ----
-(NSString *)parseColor:(UIColor *)theColor
{
    return [[WSTheme sharedObject].currentThemeModel parseColor:theColor];
}

-(NSString *)parseFont:(UIFont *)theFont
{
    return [[WSTheme sharedObject].currentThemeModel parseFont:theFont];
}

-(NSString *)parseImage:(UIImage *)theImage withName:(NSString *)theName
{
return [[WSTheme sharedObject].currentThemeModel parseImage:theImage withName:theName];
}

-(NSString *)parseData:(NSData *)theData withName:(NSString *)theName
{
return [[WSTheme sharedObject].currentThemeModel parseData:theData withName:theName];
}

-(NSDictionary *)parseAttributes:(NSDictionary *)theAttributes
{
return [[WSTheme sharedObject].currentThemeModel parseAttributes:theAttributes];
}

-(id)parseJsonText:(NSString *)theJsonText
{
    return [[WSTheme sharedObject].currentThemeModel parseJsonText:theJsonText];
}


@end





