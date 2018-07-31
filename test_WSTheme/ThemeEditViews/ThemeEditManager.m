//
//  ThemeEditManager.m
//  TestTheme_sakura
//
//  Created by wsliang on 2018/6/29.
//  Copyright © 2018年 wsliang. All rights reserved.
//

#import "ThemeEditManager.h"

#import "WSTheme.h"

@implementation ThemeEditManager


    // theme主题列表(namelist)
+(NSArray *)themeNameListSystem
{
    return @[WSThemeDefaultThemeName];
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

// 获取 对应theme的json定义dict
+(NSDictionary *)definedDictForTheme:(NSString *)themeName
{
    return [[WSTheme sharedObject] themeJsonDictForName:themeName];
}

    // 获取 对应theme的定义模板. themeName==nil,或者对应的模板不存在, 读取默认模板 defaultTemplate;
    // 模板定义 key:keypath形式 直接定义指定字段意义. (可以无限级别,目前解析到二级)
+(NSDictionary *)templateDictForTheme:(NSString *)themeName
{
    NSString *jsonPath;
    if (themeName) {
        jsonPath = [[NSBundle mainBundle] pathForResource:[themeName stringByAppendingString:@"_tl"] ofType:@"json"];
    }
    if (!jsonPath) {
        jsonPath = [[NSBundle mainBundle] pathForResource:@"default_tl" ofType:@"json"];
    }
    if (jsonPath) {
        NSData *defaultData = [NSData dataWithContentsOfFile:jsonPath];
        return [NSJSONSerialization JSONObjectWithData:defaultData options:0 error:nil];
    }
    return nil;
}



    // 解析指定名称(themeName)theme的jsonDict内容.返回 ThemeEditItemModel的二级数组.
/**
 返回数据以json定义为主,theme模板未定义的字段,ThemeEditItemModel type=ThemeEditItemTypeNone 原生值的形式返回.

 @itemList 二维数组: NSArray<NSArray<ThemeEditItemModel *> *> 每个section内容.
 @titleList 数组: NSArray<ThemeEditItemModel *> 标题数组 上面数组的section名称;
 @return 是否解析成功.
 */
+(BOOL)parseThemeEditItemList:(NSArray<NSArray<ThemeEditItemModel *> *> **)itemList titleList:(NSArray<ThemeEditItemModel *> **)titleList forTheme:(NSString *)themeName;
{
    NSDictionary *jsonDict = [self definedDictForTheme:themeName];
    if (!jsonDict || jsonDict.count==0) {
        return NO;
    }

    NSDictionary *templateDict = [self templateDictForTheme:themeName];

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


    // 保存 新theme主题.
+(BOOL)saveNewTheme:(NSArray<NSArray<ThemeEditItemModel *> *> *)editItemList withName:(NSString *)newName
{
    // 判断默认值
    if(newName ==nil || editItemList.count==0){
        return NO;
    }

        // 检查name是否重复.
    BOOL hasName = [[[WSTheme sharedObject] themeNameList] containsObject:newName];
    if (hasName) {
        return NO;
    }

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

    // 保存
    return [[WSTheme sharedObject] addThemeJsonDictList:@[tempJsonDict] withNameList:@[newName]];

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
    if (!keypath) { return nil; }
    ThemeEditItemModel *item = [[ThemeEditItemModel alloc] init];
    item.value = item.defalut = value;
    item.order =@(NSIntegerMax);
    item.mType = ThemeEditItemTypeNone;
    item.name = item.keypath = keypath;
//    if ([value isKindOfClass:[NSNumber class]] || [value isKindOfClass:[NSString class]]) {
//
//    }
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
        static NSArray *typeStrArr;
        if (!typeStrArr) {
            typeStrArr = @[@"none", @"node", @"color", @"text", @"font", @"image", @"num", @"dict"];
        }
        NSInteger index = [typeStrArr indexOfObject:typeStr];
        if (index != NSNotFound) {
            return (ThemeEditItemType)index;
        }
    }
    return ThemeEditItemTypeNone;
}

+(NSString *)getItemTypeStr:(ThemeEditItemType)type
{
        static NSArray *typeStrArr;
        if (!typeStrArr) {
            typeStrArr = @[@"none", @"node", @"color", @"text", @"font", @"image", @"num", @"dict"];
        }
    if (typeStrArr.count>type) {
        return typeStrArr[type];
    }
    return nil;
}

@end





