//
//  WSTheme.m
//  Test_LEETheme
//
//  Created by wsliang on 2018/7/13.
//  Copyright © 2018年 wsliang. All rights reserved.
//

#import "WSTheme.h"


#define NSLog(format, ...) do {(NSLog)((format), ##__VA_ARGS__);} while (0)

#define isNull(_obj) (_obj==nil || _obj == (id)[NSNull null])

#define WSThemeUpdateMaxThreadNumber 16 // 线程池大小

NSNotificationName const WSThemeUpdateNotificaiton = @"WSThemeUpdateNotificaiton";
/**
 主题目录.
 WSTheme/themeList/[thmename]/

 WSTheme/themeList/[thmename]/theme.json
 WSTheme/themeList/[thmename]/theme_tl.json
 WSTheme/themeList/[thmename]/files/...

 缓存目录
 WSTheme/cacheFiles/[thmename]/files/[keypath]

archive数据目录
 WSTheme/archiveData/fileName
当前主题名称地址
 WSTheme/archiveData/_themeNameCurrent
 主题列表地址
 WSTheme/archiveData/_themeNameList
 */

#define WSThemeFileManager_themeThemeListMainPath @"WSTheme/themeList"
#define WSThemeFileManager_themeCacheFileMainPath @"WSTheme/cacheFiles"
#define WSThemeFileManager_themeArchiveDataMainPath @"WSTheme/archiveFiles"

#define WSThemeFileManager_themeJsonName @"theme.json"
#define WSThemeFileManager_themeTemplateJsonName @"theme_tl.json"
#define WSThemeFileManager_themeResourceName @"files"

#define WSThemeFileManager_themeNameListName @"_themeNameList.plist"
#define WSThemeFileManager_themeNameCurrentName @"_themeNameCurrent.txt"

@interface WSThemeFileManager:NSObject

    // +======+ tools +======+
    // object为nil时,删除操作 通用操作.
-(BOOL)saveObject:(id)object withKey:(NSString *)key;
-(id)getObjectForKey:(NSString*)key;

    // 主题列表和当前主题记录.
-(NSArray *)themeNameList;
-(NSString *)themeCurrentName;
-(BOOL)themeNameListSave:(NSArray *)themeNameList;
-(BOOL)themeCurrentNameSave:(NSString *)themeName;

    // 保存jsonDict
-(BOOL)themeSaveJsonDict:(NSDictionary *)jsonDict forTheme:(NSString *)themeName;
    // 保存TemplateDict,如果themeName为空,表示保存全局模板Template.
-(BOOL)themeSaveTemplateDict:(NSDictionary *)jsonDict forTheme:(NSString *)themeName;
    // 保存一个主题目录到主题列表中,使用[themeName]命名.
-(BOOL)themeSaveFilePackage:(NSString *)filePackagePath forTheme:(NSString *)themeName;
    //读取theme定义TemplateDict
-(NSDictionary *)themeGetTemplateDict:(NSString *)themeName;
    // 读取theme定义jsonDict
-(NSDictionary *)themeGetJsonDict:(NSString *)themeName;

    // 保存缓存或资源文件.
-(BOOL)themeSaveCacheFile:(NSData *)theFile themeName:(NSString *)themeName fileName:(NSString *)fileName;
-(BOOL)themeSaveResourceFile:(NSData *)theFile themeName:(NSString *)themeName fileName:(NSString *)fileName;
    // 读取缓存的数据,不存在时返回nil.
-(NSData *)themeCachedFile:(NSString *)themeName fileName:(NSString *)fileName;
-(NSData *)themeResource:(NSString *)themeName fileName:(NSString *)fileName;

    // 删除一个主题的所有文件和目录.
-(BOOL)themeRemove:(NSString *)themeName;
    // 复制一份新theme.
-(BOOL)themeCopyFrom:(NSString *)theThemeName withNewThemeName:(NSString *)newThemeName;

    // 清理缓存cacheData目录和archiveData目录中所有缓存内容.
-(BOOL)clearAllCacheData;
    // 删除所有theme的资源文件.
-(BOOL)clearThemes;

    // +======+ 目录工具 +======+

    // 主题列表保存路径
- (NSString *)themeNameListPath;
    // 当前主题保存路径
- (NSString *)themeCurrentNamePath;

    // 主题 cache文件路径
- (NSString *)themeCacheFilePath:(NSString *)themeName fileName:(NSString *)fileName;
    // 主题 资源文件路径
- (NSString *)themeResourcePath:(NSString *)themeName fileName:(NSString *)fileName;

    // 主题 Template路径
- (NSString *)themeTemplateDictPath:(NSString *)themeName;
    // 主题 json路径
- (NSString *)themeJsonDictPath:(NSString *)themeName;

    // 返回theme主目录,如果不存在自动创建.
- (NSString *)themeMainPath:(NSString *)themeName;

    // 主题主目录+themeName目录,传值nil返回主目录.
    // isCreate 是否自动创建不存在的目录.
    // isClear 是否清空已存在的文件.
- (NSString *)themeMainPath:(NSString *)themeName isAutoCreate:(BOOL)isCreate isClear:(BOOL)isClear;

@end

@implementation WSThemeFileManager



    // ================= tools =================

-(BOOL)themeNameListSave:(NSArray *)themeNameList
{
    return [themeNameList writeToFile:[self themeNameListPath] atomically:YES];
}

-(BOOL)themeCurrentNameSave:(NSString *)themeName
{
    return [themeName writeToFile:[self themeCurrentNamePath] atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

-(NSArray *)themeNameList
{
    NSArray *tempArr = [NSArray arrayWithContentsOfFile:[self themeNameListPath]];
    if (tempArr.count==0) {
        // 遍历所有theme目录.
        NSArray *themeNameItems = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self themeMainPath:nil] error:nil];
        tempArr = themeNameItems;
        if (tempArr.count>0) {
            [self themeNameListSave:tempArr];
        }
    }
    return tempArr;
}

-(NSString *)themeCurrentName
{
    return [NSString stringWithContentsOfFile:[self themeCurrentNamePath] encoding:NSUTF8StringEncoding error:nil];
}


    // 保存jsonDict
-(BOOL)themeSaveJsonDict:(NSDictionary *)jsonDict forTheme:(NSString *)themeName
{
    if ([jsonDict isKindOfClass:[NSDictionary class]]) {
        NSData *fileData = [NSJSONSerialization dataWithJSONObject:jsonDict options:0 error:nil];
        if (fileData) {
            return [fileData writeToFile:[self themeJsonDictPath:themeName] atomically:YES];
        }
    }
    return NO;
}

    // 保存TemplateDict,如果themeName为空,表示保存全局模板Template.
-(BOOL)themeSaveTemplateDict:(NSDictionary *)jsonDict forTheme:(NSString *)themeName
{
    if ([jsonDict isKindOfClass:[NSDictionary class]]) { 
        NSData *fileData = [NSJSONSerialization dataWithJSONObject:jsonDict options:0 error:nil];
        if (fileData) {
            return [fileData writeToFile:[self themeTemplateDictPath:themeName] atomically:YES];
        }
    }
    return NO;
}

// 保存一个主题目录到主题列表中,使用[themeName]命名.
-(BOOL)themeSaveFilePackage:(NSString *)filePackagePath forTheme:(NSString *)themeName
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *jsonDictPath = [filePackagePath stringByAppendingPathComponent:WSThemeFileManager_themeJsonName];
    if ([fm fileExistsAtPath:jsonDictPath]) { // 存在必要文件的主题.
        return [fm copyItemAtPath:filePackagePath toPath:[self themeMainPath:themeName isAutoCreate:NO isClear:YES] error:nil];
    }
    return NO;
}

    //读取theme定义TemplateDict
-(NSDictionary *)themeGetTemplateDict:(NSString *)themeName
{
    NSData *tempData = [NSData dataWithContentsOfFile:[self themeTemplateDictPath:themeName]];
    if (!tempData) {
        tempData = [NSData dataWithContentsOfFile:[self themeTemplateDictPath:nil]];
    }
    if (tempData) {
        return [NSJSONSerialization JSONObjectWithData:tempData options:0 error:nil];
    }
    return nil;
}

    // 读取theme定义jsonDict
-(NSDictionary *)themeGetJsonDict:(NSString *)themeName
{
    NSData *tempData = [NSData dataWithContentsOfFile:[self themeJsonDictPath:themeName]];
    if (tempData) {
        return [NSJSONSerialization JSONObjectWithData:tempData options:0 error:nil];
    }
    return nil;
}


    // 保存缓存或资源文件.
-(BOOL)themeSaveCacheFile:(NSData *)theFile themeName:(NSString *)themeName fileName:(NSString *)fileName
{
    if (theFile) {
        return [theFile writeToFile:[self themeCacheFilePath:themeName fileName:fileName] atomically:YES];
    }
    return NO;
}

-(BOOL)themeSaveResourceFile:(NSData *)theFile themeName:(NSString *)themeName fileName:(NSString *)fileName
{
    if (theFile) {
        return [theFile writeToFile:[self themeResourcePath:themeName fileName:fileName] atomically:YES];
    }
    return NO;
}

    // 读取缓存的数据,不存在时返回nil.
-(NSData *)themeCachedFile:(NSString *)themeName fileName:(NSString *)fileName
{
    NSString *filePath = [self themeCacheFilePath:themeName fileName:fileName];
    BOOL isDir = NO;
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDir] && !isDir) {
        return [NSData dataWithContentsOfFile:filePath];
    }
    return nil;
}

-(NSData *)themeResource:(NSString *)themeName fileName:(NSString *)fileName
{
    NSString *filePath = [self themeResourcePath:themeName fileName:fileName];
    BOOL isDir = NO;
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDir] && !isDir) {
        return [NSData dataWithContentsOfFile:filePath];
    }
    return nil;
}


    // 删除一个主题的所有文件和目录.
-(BOOL)themeRemove:(NSString *)themeName
{
    [self themeMainPath:themeName isAutoCreate:NO isClear:YES];
    return YES;
}

    // 复制一份新theme.
-(BOOL)themeCopyFrom:(NSString *)theThemeName withNewThemeName:(NSString *)newThemeName
{
    NSFileManager *fm = [NSFileManager defaultManager];
    return [fm copyItemAtPath:[self themeMainPath:theThemeName] toPath:[self themeMainPath:newThemeName isAutoCreate:NO isClear:YES] error:nil];
}

    // object为nil时,删除操作
-(BOOL)saveObject:(id)object withKey:(NSString *)key
{
    if (key==nil) {return NO;}
    NSString *dataPath = [[self themeArchiveObjectMainPath:nil isClear:NO] stringByAppendingPathComponent:key];
    NSFileManager *fm = [NSFileManager defaultManager];
    if (object) { // 添加或覆盖
        return [NSKeyedArchiver archiveRootObject:object toFile:dataPath];
    }else{ // 删除
        if ([fm fileExistsAtPath:dataPath]) {
            return [fm removeItemAtPath:dataPath error:nil];
        }
    }
    return NO;
}

// 删除所有theme的资源文件.
-(BOOL)clearThemes
{
    [self themeMainPath:nil isAutoCreate:NO isClear:YES];
    return YES;
}

// 清理缓存cacheData目录和archiveData目录.
-(BOOL)clearAllCacheData
{
//    [self themeArchiveObjectMainPath:nil isClear:YES];
    [self themeCacheMainPath:nil isClear:YES];
    return YES;
}

-(id)getObjectForKey:(NSString*)key
{
    if (key==nil) {return nil;}
    NSString *dataPath = [[self themeArchiveObjectMainPath:nil isClear:NO] stringByAppendingPathComponent:key];
    return [NSKeyedUnarchiver unarchiveObjectWithFile:dataPath];
}
    // =================== 目录工具 ===================
    // 主题列表保存路径
- (NSString *)themeNameListPath
{
    NSString *basePath = [self themeMainPath:nil];
    return [basePath stringByAppendingPathComponent:WSThemeFileManager_themeNameListName];
}

    // 当前主题保存路径
- (NSString *)themeCurrentNamePath
{
    NSString *basePath = [self themeMainPath:nil];
    return [basePath stringByAppendingPathComponent:WSThemeFileManager_themeNameCurrentName];
}

    // 主题 cache路径(大文件等)
    // themeName 主题名称. 指定主题. 如果名称为nil 返回全局cache/
    // fileName 缓存文件的名称.
    // 主题 cache文件路径
- (NSString *)themeCacheFilePath:(NSString *)themeName fileName:(NSString *)fileName
{
    NSString *basePath = [self themeCacheMainPath:themeName?[NSString stringWithFormat:@"%@",themeName]:nil isClear:NO];
    return fileName?[basePath stringByAppendingPathComponent:fileName]:basePath;
}

    // 主题 资源文件路径
- (NSString *)themeResourcePath:(NSString *)themeName fileName:(NSString *)fileName
{
    NSString *basePath = [self themeMainPath:[NSString stringWithFormat:@"%@/%@",themeName,WSThemeFileManager_themeResourceName]];
    return fileName?[basePath stringByAppendingPathComponent:fileName]:basePath;
}

    // 主题 模板路径
- (NSString *)themeTemplateDictPath:(NSString *)themeName
{
    NSString *basePath = [self themeMainPath:themeName];
    return [basePath stringByAppendingPathComponent:WSThemeFileManager_themeTemplateJsonName];
}

    // 主题 json路径
- (NSString *)themeJsonDictPath:(NSString *)themeName
{
    NSString *basePath = [self themeMainPath:themeName];
    return [basePath stringByAppendingPathComponent:WSThemeFileManager_themeJsonName];
}

// 返回theme主目录,如果不存在自动创建.
- (NSString *)themeMainPath:(NSString *)themeName
{
    return [self themeMainPath:themeName isAutoCreate:YES isClear:NO];
}


    // 主题主目录+themeName目录,传值nil返回主目录.
    // isCreate 是否自动创建不存在的目录.
    // isClear 是否清空已存在的文件.
- (NSString *)themeMainPath:(NSString *)themeName isAutoCreate:(BOOL)isCreate isClear:(BOOL)isClear
{
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]; // NSDocumentDirectory
    path = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/%@",WSThemeFileManager_themeThemeListMainPath,themeName?:@""]];
    if (isCreate) {
        NSFileManager *fm = [NSFileManager defaultManager];
        if (![fm fileExistsAtPath:path]) {
            [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
        }else if(isClear){
            [fm removeItemAtPath:path error:nil];
            if(![fm fileExistsAtPath:path]){
                [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
            }
        }
    }else if (isClear){
        NSFileManager *fm = [NSFileManager defaultManager];
        if ([fm fileExistsAtPath:path]) {
            [fm removeItemAtPath:path error:nil];
        }
    }
    return path;
}

// 缓存等 主路径
-(NSString *)themeCacheMainPath:(NSString *)themeName isClear:(BOOL)isClear
{
    NSString *path = NSTemporaryDirectory();
    path = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/%@",WSThemeFileManager_themeCacheFileMainPath,themeName?:@""]];
    NSFileManager *fm = [NSFileManager defaultManager];
    if(![fm fileExistsAtPath:path]){
        if (!isClear) {
            [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
        }
    }else if(isClear){
        [fm removeItemAtPath:path error:nil];
    }
    return path;
}
// archive文件等 主路径
-(NSString *)themeArchiveObjectMainPath:(NSString *)themeName isClear:(BOOL)isClear
{
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    path = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/%@",WSThemeFileManager_themeArchiveDataMainPath,themeName?:@""]];
    NSFileManager *fm = [NSFileManager defaultManager];
    if(![fm fileExistsAtPath:path]){
        if (!isClear) {
            [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
        }
    } if(isClear){
        [fm removeItemAtPath:path error:nil];
    }
    return path;
}
@end


@interface WSTheme()
@property(nonatomic) NSOperationQueue *updateQueue; // 线程队列(读取json配置数据,转化类型)
@property(nonatomic) WSThemeFileManager *themeFileUtil; // 文件处理工具.
@property(nonatomic) NSHashTable *delegateTable; // delegate列表.
@property(nonatomic) NSHashTable *callBlockTable; // 事件队列.
@end

@implementation WSTheme
{
    NSMutableArray *mThemeNameList; // 创建的主题列表
    NSString *currentName;
    WSThemeModel *currentModel; // theme 数据处理层.
    NSLock *opLock;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self loadDefaultThemeData];
    }
    return self;
}

+(instancetype)sharedObject
{
    static dispatch_once_t onceTag;
    static id staticObject = nil;
    dispatch_once(&onceTag, ^{
        staticObject = [self new];
//        [staticObject loadDefaultThemeData];
    });
    return staticObject;
}

// 加载默认的theme数据.
-(void)loadDefaultThemeData
{
        _updateQueue = [[NSOperationQueue alloc] init];
        _updateQueue.maxConcurrentOperationCount = WSThemeUpdateMaxThreadNumber;
        _themeFileUtil = [WSThemeFileManager new];

    // 读取 记录的themeModel模板数据.
    mThemeNameList = [NSMutableArray arrayWithArray:[_themeFileUtil themeNameList]];
    currentName = [_themeFileUtil themeCurrentName];
//    currentModel = [self themeModelForName:currentName];
}

// json 转换成的object.
-(WSThemeModel *)currentThemeModel
{
    if (!currentModel) {
        currentModel = [self themeModelForName:currentName];
    }
    return currentModel;
}

-(NSString *)currentThemeName
{
    return currentName;
}
-(NSArray *)themeNameList
{
    return [NSArray arrayWithArray:mThemeNameList];
}

// 委托协议注册列表.
-(NSArray<WSThemeChangeDelegate> *)delegateList
{
    NSArray *tempArr;
    @synchronized (_delegateTable) {
        tempArr = [_delegateTable allObjects];
    }
    return (id)tempArr;
}


-(NSHashTable *)delegateTable
{
    if (!_delegateTable) {
        _delegateTable = [NSHashTable weakObjectsHashTable];
        _callBlockTable = [NSHashTable weakObjectsHashTable];
        opLock = [NSLock new];
    }
    return _delegateTable;
}

    // 添加主题切换监听,弱引用,id对象消失时,列表中会自动删除该对象.
    // 注意数据同步问题:在切换主题后,添加委托对象时,需自主更新一次.
-(void)addDelegate:(id<WSThemeChangeDelegate>)theDelegate
{
    if ([theDelegate conformsToProtocol:@protocol(WSThemeChangeDelegate)]) {
        @synchronized (_delegateTable) {
            [self.delegateTable addObject:theDelegate];
        }
        [theDelegate wsThemeHasChanged:currentName themeModel:currentModel];
    }
}

-(void)removeDelegate:(id<WSThemeChangeDelegate>)theDelegate
{
    @synchronized (_delegateTable) {
        if ([_delegateTable containsObject:theDelegate]) {
            [_delegateTable removeObject:theDelegate];
        }
    }

}

-(BOOL)startTheme:(NSString *)theName
{
    if (theName == nil || [currentName isEqual:theName]) {
        return NO;
    }

    NSInteger index = [mThemeNameList indexOfObject:theName];
    if (index == NSNotFound) {
        return NO;
    }

//    [_updateQueue cancelAllOperations];
    if (_callBlockTable.count>0) {
        [opLock lock];
        NSArray *tempOpList = [_callBlockTable allObjects];
        [_callBlockTable removeAllObjects];
        [opLock unlock];
        for (NSOperation *tempOp in tempOpList) {
            [tempOp cancel];
        }
    }

    NSLog(@"主题切换:%@ -> %@",currentName,theName);
    [_updateQueue setSuspended:YES];

    [self willChangeValueForKey:@"currentThemeName"];
    currentName = [theName copy];
    currentModel = [self themeModelForName:currentName];
    [_themeFileUtil themeCurrentNameSave:currentName];
    [self didChangeValueForKey:@"currentThemeName"];// KVO消息

        // 消息推送
    [[NSNotificationCenter defaultCenter] postNotificationName:WSThemeUpdateNotificaiton object:nil userInfo:nil];

    // delegate回调. 注意阻塞
    NSArray *tempList;
    @synchronized (_delegateTable) {
        tempList = [_delegateTable allObjects];
    }
    if (tempList.count>0) {
        NSString *tempName = currentName;
        WSThemeModel *tempModel = currentModel;
        for (id<WSThemeChangeDelegate> tempDelegate in tempList) {
            NSOperation *newOp2 = [NSBlockOperation blockOperationWithBlock:^{
                [tempDelegate wsThemeHasChanged:tempName themeModel:tempModel];
            }];
            [opLock lock];
            [_callBlockTable addObject:newOp2];
            [opLock unlock];
            [[NSOperationQueue mainQueue] addOperation:newOp2];
        }
    }
    [_updateQueue setSuspended:NO];
    return YES;
}

-(int)addThemeWithJsonDictList:(NSArray<NSDictionary *> *)dictList withNameList:(NSArray<NSString *> *)nameList
{
    BOOL addNum = 0;
    BOOL updateNum = 0;
    for (int it=0; it<nameList.count; it++) {
        NSString *tempName = nameList[it];
        NSDictionary *tempDict;
        if(dictList.count>it){ // 是否一一对应.
            tempDict = dictList[it];
            BOOL hasSaved = [_themeFileUtil themeSaveJsonDict:tempDict forTheme:tempName];
            if (hasSaved) {
                if ([mThemeNameList containsObject:tempName]) { // 更新
                    updateNum ++;
                }else{ // 添加
                    [mThemeNameList addObject:tempName];
                    addNum ++;
                }
            }
        }
    }

    NSLog(@"主题添加:%d 个,更新:%d 个,共有:%lu 个主题",addNum,updateNum,(unsigned long)mThemeNameList.count);
    if (addNum>0) {
        [_themeFileUtil themeNameListSave:mThemeNameList];
    }
    return (addNum+updateNum);
}

-(BOOL)removeThemes:(NSArray<NSString *> *)nameList
{
    BOOL subNum = 0;
    for (NSString *tempName in nameList) {
        if ([tempName isEqualToString:currentName]) { // 当前主题使用的不可删除.
            continue;
        }
        NSUInteger index = [mThemeNameList indexOfObject:tempName];
        if (index != NSNotFound) {
            if ([_themeFileUtil themeRemove:tempName]) {
                [_themeFileUtil themeCacheMainPath:tempName isClear:YES];
                [mThemeNameList removeObjectAtIndex:index];
                subNum ++;
            }
        }
    }
    NSLog(@"主题删除:%d 个,剩余:%lu 个",subNum,(unsigned long)mThemeNameList.count);
    if (subNum>0) {
        [_themeFileUtil themeNameListSave:mThemeNameList];
        return YES;
    }
    return NO;

}




    // =========== 其他编辑扩展工具 ===========

/**
 按主题目录结构添加主题(文件夹形式添加);如果添加成功,copy整个文件目录到主题配置目录中.
 @packagePathList 主题目录地址列表.
 @themeNameList 对应主题命名列表;(同名的主题被更新)
 @BOOL 返回是否添加成功,至少添加或更新成功一个主题.

 1.目录中:包含资源文件和标准格式命名的主题目录.
 2.至少包含 ./themeName/default.json 资源配置文件.
 3.其他资源文件在目录: ./themeName/resource/ ,资源文件命名在default.json中对应value值.
 4.编辑时,需要在模板文件中标记对应的资源分类.
 */
-(int)addThemeWithPackageList:(NSArray<NSString *> *)packagePathList withThemeNamList:(NSArray<NSString *> *)themeNameList
{

    int addNum = 0,updateNum=0;
    for (int it=0; it<packagePathList.count; it++) {
        if (themeNameList.count <= it) { // 没有对应主题命名.
            break;
        }
        NSString *tempName = themeNameList[it];
        NSString *tempPath = packagePathList[it];
        BOOL hasAdd = [_themeFileUtil themeSaveFilePackage:tempPath forTheme:tempName];
        if (hasAdd) {
            if ([mThemeNameList containsObject:tempName]) { // 更新
                updateNum ++;
            }else{ // 添加
                [mThemeNameList addObject:tempName];
                addNum ++;
            }
        }
    }
    NSLog(@"Package主题添加:%d 个,更新:%d 个,共有:%lu 个主题",addNum,updateNum,(unsigned long)mThemeNameList.count);
    if (addNum>0) {
        [_themeFileUtil themeNameListSave:mThemeNameList];
    }
    return addNum+updateNum;
}

    // TODO: 修改成 新的model
-(WSThemeModel *)themeModelForName:(NSString *)themeName
{
    if ([currentModel.name isEqualToString:themeName]) {
        return currentModel;
    }
    WSThemeModel *tempModel = [WSThemeModel createWithName:themeName];
        //    [tempModel loadThemeDataWithName:themeName];
    return tempModel;
}

-(BOOL)setThemeTemplateDict:(NSDictionary *)theDict forName:(NSString *)themeName
{
    return [_themeFileUtil themeSaveTemplateDict:theDict forTheme:themeName];
}

// 传空值时清理全部缓存,只清理大文件缓存目录内容(image,data等).
-(BOOL)clearCacheData:(NSArray *)themeNameList
{
    if(themeNameList.count>0){
        for (NSString *tempName in themeNameList) {
            if ([mThemeNameList containsObject:tempName]) {
                [_themeFileUtil themeCacheMainPath:tempName isClear:YES];
            }
        }
        return YES;
    }else{
        return [_themeFileUtil clearAllCacheData];
    }
    return NO;
}



@end



@interface WSThemeModel()
@property(nonatomic) NSDictionary *mThemeDict; // json配置对象.

    // 缓存 已经转换后的对象,下次重复读取时,从这里加载;key: identifier; value: 已经转换后的内容
@property(nonatomic) NSMutableArray *cacheDictList; // 位置与 WSThemeValueType数值一一对应.

@end

@implementation WSThemeModel


-(NSOperationQueue *)updateQueue
{
    return [WSTheme sharedObject].updateQueue;
}

-(WSThemeFileManager *)themeFileUtil
{
    return [WSTheme sharedObject].themeFileUtil;
}

-(void)createDefaultData
{
    NSString *cachePath = [self.themeFileUtil themeCacheFilePath:_name fileName:[NSString stringWithFormat:@"%@.modelcache",_name]];
    NSArray *tempArray = [NSKeyedUnarchiver unarchiveObjectWithFile:cachePath];

    _cacheDictList = [[NSMutableArray alloc] initWithCapacity:WSThemeValueTypeNone];
    for (int it=0; it<WSThemeValueTypeNone; it++) {
        NSDictionary *tempDict = (tempArray.count>it)?tempArray[it]:nil;
        [_cacheDictList addObject:[[NSMutableDictionary alloc] initWithDictionary:tempDict]];
    }
}

+(instancetype)createWithName:(NSString *)theName
{
    WSThemeModel *tempModel = [WSThemeModel new];
    BOOL isOK = [tempModel loadThemeDataWithName:theName];
    NSLog(@"创建model:%@%@",tempModel,isOK?@"":@" 没有jsonDict定义.");
    return tempModel; // 未定义json 也可以返回空.
}
-(BOOL)loadThemeDataWithName:(NSString *)themeName
{
    _name = themeName;
    NSDictionary *jsonDict = [self.themeFileUtil themeGetJsonDict:themeName];
    _mThemeDict = jsonDict;
    [self createDefaultData];
    return YES;
}

    // 返回当前theme定义的jsonDict内容.
-(NSDictionary *)themeJsonDict
{
    return _mThemeDict;
}

-(NSDictionary *)themeTemplateDict
{
    return [self.themeFileUtil themeGetTemplateDict:_name];
}

-(NSString *)themePackagePath
{
    return [self.themeFileUtil themeMainPath:_name];
}

    // block 形式加载. 回调线程是 updateQueue 线程;
    // 结果回调不受theme切换影响.
    // 异步读取数据. complete线程已切换到主线程. model是当前对象(可能为空).
-(void)getDataWithIdentifier:(NSString *)identifier backType:(WSThemeValueType)type complete:(void(^)(id value))complete
{
    if (isNull(identifier) || _mThemeDict.count ==0 ) {if(complete)complete(nil);return;}
    if(complete){
        __weak typeof(self) weakSelf = self;
        [self.updateQueue addOperationWithBlock:^{
            id value = [weakSelf getDataWithIdentifier:identifier backType:type];
            if(weakSelf){
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    complete(value);
                }];
            }
        }];
    }
}

    // 获取原生值类型为WSThemeValueTypeOriginal; identifier 支持keyPath格式.
    // 当前线程执行;如果读取网络数据或耗时数据时,使用异步读取方法.
-(id)getDataWithIdentifier:(NSString *)identifier backType:(WSThemeValueType)type
{
    if (isNull(identifier) || _mThemeDict.count ==0) {return nil;}

    SEL callSel = NULL;
    if (type == WSThemeValueTypeOriginal) {
        return [_mThemeDict valueForKeyPath:identifier];
    }else if (type == WSThemeValueTypeJson) {
        callSel = @selector(createJsonText:);
    }else if (type == WSThemeValueTypeColor) {
        callSel = @selector(createColor:);
    }else if (type ==WSThemeValueTypeData){
        id tempValue = [_mThemeDict valueForKeyPath:identifier];
        return [self createData:tempValue withIdentifier:identifier];
    }else if (type ==WSThemeValueTypeImage){
            //        callSel = @selector(createImage:);
        id tempValue = [_mThemeDict valueForKeyPath:identifier];
        return [self createImage:tempValue withIdentifier:identifier];
    }else if (type ==WSThemeValueTypeFont){
        callSel = @selector(createFont:);
    }else if (type ==WSThemeValueTypeAttribute){
        callSel = @selector(createAttributes:);
    }else{
            // 默认情况.
        return [_mThemeDict valueForKeyPath:identifier];
    }

    NSMutableDictionary *typeDict = [_cacheDictList objectAtIndex:type];
    if (typeDict) {
        id backValue;
        @synchronized (typeDict) {
            backValue = [typeDict objectForKey:identifier];
        }
        if (backValue) {
            return isNull(backValue)?nil:backValue;
        }else{
            id tempValue = [_mThemeDict valueForKeyPath:identifier];
            if(tempValue){
                IMP imp = [self methodForSelector:callSel];
                id (*func)(id, SEL, id) = (void *)imp;
                tempValue = func(self, callSel, tempValue);
                    //            tempValue = [weakSelf performSelector:callSel withObject:tempValue];
            }
            @synchronized (typeDict) {
                [typeDict setObject:tempValue?:[NSNull null] forKey:identifier];
            }
            return tempValue;
        }
    }
    return nil;
}


    // ================ utils  ================
    // 内容 转换成 json格式的字符串形式.
-(NSString *)createJsonText:(id)value
{
    if ([value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSDictionary class]]) {
        NSData *tempData = [NSJSONSerialization dataWithJSONObject:value options:0 error:nil];
        if (tempData.length>0) {
            return [[NSString alloc] initWithData:tempData encoding:NSUTF8StringEncoding];
        }
    }
    return [value description];
}

/**
 默认匹配转换. 支持 0x,#或者直接写的三种格式十六进制的字符串. [0xffddffdd,#ffddffdd,ffddffdd], 八位时格式ARGB.六位时RGB.
 支持 NSNumber 类型, 该类型没有alpha项.
 */
-(UIColor *)createColor:(NSString *)value
{
    unsigned long hex = 0;
    BOOL hasAlpha = NO; // 只有 字符串 强制定义alpha数值.
    if ([value isKindOfClass:[NSString class]]) {
        value = [[value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
        if([value hasPrefix:@"0X"]){
            value = [value substringFromIndex:2];
        }else if ([value hasPrefix:@"#"]){
            value = [value substringFromIndex:1];
        }
        hasAlpha = (value.length>6);
        hex = strtoul([value UTF8String],0,16);
    }else if ([value isKindOfClass:[NSNumber class]]){
        hex = [(NSNumber*)value unsignedLongValue];
    }else{
        return nil;
    }

    CGFloat alpha = (hasAlpha)?(((float)((hex & 0xFF000000) >> 24))/255.0):1.0f;
    UIColor *color = [UIColor colorWithRed:((float)((hex & 0xFF0000) >> 16))/255.0 green:((float)((hex & 0xFF00) >> 8))/255.0 blue:((float)(hex & 0xFF))/255.0 alpha:alpha];
    return color;
}

/**
 NSNumber,NSSting:默认字体指定字号大小值;
 "fontName:20":指定字体名称和字号大小,:分隔符;
 */
-(UIFont *)createFont:(NSString *)fontSize
{
    if ([fontSize isKindOfClass:[NSString class]] && [fontSize containsString:@":"]){
        NSArray *fonts = [fontSize componentsSeparatedByString:@":"];
        int size = [[fonts lastObject] intValue];
        if (size>0) {
            return [UIFont fontWithName:[fonts firstObject] size:size];
        }
    }else{
        int size = [fontSize intValue];
        if (size>0) {
            return [UIFont systemFontOfSize:[fontSize intValue]];
        }
    }
    return nil;
}

/**
 支持的文件名类型:
 "imgName" "imgName.jpg" "https://www.test.com/imgName.png"
 */
-(UIImage *)createImage:(NSString *)imgName
{
    return [self createImage:imgName withIdentifier:nil];
}

/**
 支持的文件名类型:
 "imgName" "imgName.jpg" "https://www.test.com/imgName.png"
 */
-(UIImage *)createImage:(NSString *)imgName withIdentifier:(NSString *)identifier
{
    UIImage *tempImg;

    if([imgName containsString:@"/"]){ // 可能需要延时加载.
        if (identifier) {
            tempImg = [UIImage imageWithContentsOfFile:[[self themeFileUtil] themeCacheFilePath:_name fileName:identifier]];
            if (tempImg) { return tempImg; }
        }
        NSString *tempName = [imgName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSURL *tempUrl = [NSURL URLWithString:tempName];
        if(tempUrl){
            NSData *tempData = [NSData dataWithContentsOfURL:tempUrl];
            tempImg = [UIImage imageWithData:tempData];
            if (identifier && tempImg) {
                NSString *cachePath = [[self themeFileUtil] themeCacheFilePath:_name fileName:identifier];
                [tempData writeToFile:cachePath atomically:YES];
            }
        }
    }else{
        tempImg = [UIImage imageWithContentsOfFile:[[self themeFileUtil] themeResourcePath:_name fileName:imgName]];
    }

    if (!tempImg) {
        tempImg = [UIImage imageNamed:imgName];
    }
    return tempImg;
}

// 读取data对象,数据类型同image.
-(NSData *)createData:(NSString *)theDataName
{
    return [self createData:theDataName withIdentifier:nil];
}
// 读取data对象,数据类型同image.
-(NSData *)createData:(NSString *)theDataName withIdentifier:(NSString *)identifier
{
    NSData *tempData;

    if([theDataName containsString:@"/"]){ // 可能需要延时加载.
        if (identifier) {
            tempData = [NSData dataWithContentsOfFile:[[self themeFileUtil] themeCacheFilePath:_name fileName:identifier]];
            if (tempData) { return tempData; }
        }
        NSString *tempName = [theDataName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSURL *tempUrl = [NSURL URLWithString:tempName];
        if(tempUrl){
            tempData = [NSData dataWithContentsOfURL:tempUrl];
            if (identifier && tempData) {
                NSString *cachePath = [[self themeFileUtil] themeCacheFilePath:_name fileName:identifier];
                [tempData writeToFile:cachePath atomically:YES];
            }
        }
    }else{
        NSString *tempPath = [[self themeFileUtil] themeResourcePath:_name fileName:theDataName];
        tempData = [NSData dataWithContentsOfFile:tempPath];
    }

    if (!tempData) {
        NSString *tempPath = [[NSBundle mainBundle] pathForResource:theDataName ofType:nil];
        if (tempPath) {
            tempData = [NSData dataWithContentsOfFile:tempPath];
        }
    }

    return tempData;
}


/**
 支持 NSAttributedString.h 定义的 attributeName字符串转换的key.
 对应的value值font,color类型自动转换,number,string使用原值,其他的属性暂不支持.
 */
-(NSDictionary *)createAttributes:(NSDictionary *)value
{
    if ([value isKindOfClass:[NSDictionary class]] && value.count>0) {

        NSMutableDictionary *attrs = [[NSMutableDictionary alloc] initWithCapacity:value.count];
            // 判断支持转换的属性.

            // 是否有font属性
        NSString *tempAttrName = @"NSFontAttributeName";
        NSString *fontName = [value objectForKey:tempAttrName];
        if (fontName) {
            UIFont *font = [self createFont:fontName];
            if (font) {
                [attrs setObject:font forKey:NSFontAttributeName];
            }
        }

            // 是否有color属性
        NSDictionary *attrColorNames = @{
                                         @"NSForegroundColorAttributeName":NSForegroundColorAttributeName,
                                         @"NSStrokeColorAttributeName":NSStrokeColorAttributeName,
                                         @"NSBackgroundColorAttributeName":NSBackgroundColorAttributeName,
                                         @"NSUnderlineColorAttributeName":NSUnderlineColorAttributeName,
                                         @"NSStrikethroughColorAttributeName":NSStrikethroughColorAttributeName,
                                         };
        [attrColorNames enumerateKeysAndObjectsUsingBlock:^(NSString *tempName, NSAttributedStringKey obj, BOOL * stop) {
            NSString *colorHex = [value objectForKey:tempName];
            if (colorHex) {
                UIColor *tempColor = [self createColor:colorHex];
                if (tempColor) {
                    [attrs setObject:tempColor forKey:obj];
                }
            }
        }];

            // 清理的属性.
            //        NSArray *clearAttrsName = @[@"NSShadowAttributeName",@"NSAttachmentAttributeName",@"NSParagraphStyleAttributeName"];

            // 判断其他number,string,array<number> 类型数据.直接复制
        NSDictionary *othersNames = @{
                                      @"NSLigatureAttributeName":NSLigatureAttributeName,
                                      @"NSKernAttributeName":NSKernAttributeName,
                                      @"NSStrikethroughStyleAttributeName":NSStrikethroughStyleAttributeName,
                                      @"NSUnderlineStyleAttributeName":NSUnderlineStyleAttributeName,
                                      @"NSStrokeWidthAttributeName":NSStrokeWidthAttributeName,
                                      @"NSObliquenessAttributeName":NSObliquenessAttributeName,
                                      @"NSExpansionAttributeName":NSExpansionAttributeName,
                                      @"NSVerticalGlyphFormAttributeName":NSVerticalGlyphFormAttributeName,

                                      @"NSWritingDirectionAttributeName":NSWritingDirectionAttributeName,

                                      @"NSTextEffectAttributeName":NSTextEffectAttributeName,
                                      @"NSLinkAttributeName":NSLinkAttributeName,
                                      };
        [othersNames enumerateKeysAndObjectsUsingBlock:^(NSString *tempName, NSAttributedStringKey obj, BOOL * stop) {
            NSString *tempStr = [value objectForKey:tempName];
            if (tempStr) {
                if ([tempStr isKindOfClass:[NSNumber class]] || [tempStr isKindOfClass:[NSString class]] || [tempStr isKindOfClass:[NSArray class]]) {
                    [attrs setObject:tempStr forKey:obj];
                }
            }
        }];

        if (attrs.count>0) {
            return [NSDictionary dictionaryWithDictionary:attrs];
        }
    }

    return nil;
}

-(NSString *)parseColor:(UIColor *)theColor
{
    NSString *tempStr;
    if (theColor) {
        CGFloat r,g,b,a;
        [theColor getRed:&r green:&g blue:&b alpha:&a];
        int R,G,B,A;
        R = roundf(r*255);G= roundf(g*255);B= roundf(b*255);A= roundf(a*255);
        if (A < 255) {
            tempStr =[NSString stringWithFormat:@"#%.2X%.2X%.2X%.2X",A,R,G,B];
        }else{
            tempStr =[NSString stringWithFormat:@"#%.2X%.2X%.2X",R,G,B];
        }
    }
    return tempStr;
}

-(NSString *)parseFont:(UIFont *)theFont
{
    static UIFont *tempSystemFont=nil;
    if (!tempSystemFont) {
        tempSystemFont = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    }
    if ([tempSystemFont.fontName isEqualToString:theFont.fontName]) {
        return (id)@(theFont.pointSize);
    }
    return [NSString stringWithFormat:@"%@:%.0f",theFont.fontName,theFont.pointSize];
}

-(NSString *)parseImage:(UIImage *)theImage withName:(NSString *)theName
{
    NSString *resPath = [[self themeFileUtil] themeResourcePath:_name fileName:theName];
    [UIImagePNGRepresentation(theImage) writeToFile:resPath atomically:YES];
    return theName;
}

-(NSString *)parseData:(NSData *)theData withName:(NSString *)theName
{
    NSString *resPath = [[self themeFileUtil] themeResourcePath:_name fileName:theName];
    [theData writeToFile:resPath atomically:YES];
    return theName;
}

-(NSDictionary *)parseAttributes:(NSDictionary *)theAttributes
{
//    NSMutableDictionary *tempDict = [[NSMutableDictionary alloc] initWithCapacity:theAttributes.count];
//    [theAttributes enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL * _Nonnull stop) {
//        [tempDict setObject:obj forKey:key];
//    }];
    return nil;
}

-(id)parseJsonText:(NSString *)theJsonText
{
    id jsonObj = [NSJSONSerialization JSONObjectWithData:[theJsonText dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    return jsonObj?:theJsonText;
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%lx> name:%@",NSStringFromClass(self.class),(unsigned long)self.hash,self.name];

}

-(void)dealloc
{
    NSLog(@"model系统回收:%@",self);
    if (_cacheDictList) {
        NSString *cachePath = [self.themeFileUtil themeCacheFilePath:_name fileName:[NSString stringWithFormat:@"%@.modelcache",_name]];
        NSData *tempData = [NSKeyedArchiver archivedDataWithRootObject:_cacheDictList];
        [tempData writeToFile:cachePath atomically:YES];
    }
    _mThemeDict = nil;
    _cacheDictList = nil;
}


@end



@interface WSThemeConfig()

    // 关联的更新对象.
@property(nonatomic,weak) NSObject *currentObject;
    // 记录当前使用的 model.
@property(nonatomic,weak) WSThemeModel *currentModel;
@property(nonatomic,weak) NSOperationQueue *updateQueue; // [WSTheme sharedObject].updateQueue 的弱引用.
@property(nonatomic) NSHashTable *operationList; // 保存正在执行和将要执行的NSOperation列表.
@property(nonatomic) NSLock *opLock;
// 注册的block列表缓存.
// key: valueBlock;value: identifier;
@property(nonatomic) NSMutableDictionary *customBlockDict;

@end
@implementation WSThemeConfig

- (instancetype)init
{
    self = [super init];
    if (self) {
        _updateQueue = [WSTheme sharedObject].updateQueue;
        _operationList = [NSHashTable weakObjectsHashTable];
        _opLock = [NSLock new];
        
        _currentModel = [WSTheme sharedObject].currentThemeModel;
        _customBlockDict = [NSMutableDictionary new];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(theme_ChangeModelNotify:) name:WSThemeUpdateNotificaiton object:nil];
    }
    return self;
}

    // 接收更新通知, 执行theme切换更新
-(void)theme_ChangeModelNotify:(id)sender
{
    NSLog(@"收到切换theme通知:%@",self);
    [self cancelOperations];
    WSThemeModel *currentModel = [WSTheme sharedObject].currentThemeModel;
    if (!_currentModel || ![_currentModel.name isEqual:currentModel.name]) {
        NSLog(@"开始更新对象:<%@:%lx> 注册的block列表.",NSStringFromClass(self.currentObject.class),(unsigned long)self.currentObject.hash);
        _currentModel = currentModel;
        if (_customBlockDict.count==0) { return; }

        __weak typeof(self) weakSelf = self;
        NSOperation *updateOp = [NSBlockOperation blockOperationWithBlock:^{
            NSArray *valueBlockArray = weakSelf.customBlockDict.allKeys;
            for (WSThemeConfigValueBlock valueBlock in valueBlockArray) {
                NSArray *identifierArray = [weakSelf.customBlockDict objectForKey:valueBlock];
                if (identifierArray && weakSelf.currentModel == currentModel) {
                    [weakSelf getValueFromMdodel:weakSelf.currentModel identifier:[identifierArray firstObject] valueType:((NSNumber *)[identifierArray lastObject]).intValue valueBlock:valueBlock];
                }else{
                    NSLog(@"theme已改变 取消其他更新调用:%@",weakSelf.currentModel.name);
                    break;
                }
            }
        }];
        [self.opLock lock];
        [self.operationList addObject:updateOp];
        [self.opLock unlock];
        [self.updateQueue addOperation:updateOp];

    }
//    NSLog(@"-- 样式更新方法 已完成 :%@ --",currentModel.name);
}

// ================ block 注册 ================
// 注册 更新theme的block回调
-(WSThemeConfigCustomBlock)custom
{
    __weak typeof(self) weakSelf = self;
    return ^(NSString *identifier,WSThemeValueType valueType, WSThemeConfigValueBlock valueBlock)
    {
        if (!valueBlock) {return weakSelf;}
        // 保存,identifier对应的 configblock
        [weakSelf saveCustomBlock:valueBlock identifier:identifier valueType:valueType];
            // 执行一次界面更新
        [weakSelf getValueFromMdodel:weakSelf.currentModel identifier:identifier valueType:valueType valueBlock:valueBlock];
        return weakSelf;
    };
}


//-(WSThemeConfigFixedTypeBlock)color
//{
//    __weak typeof(self) weakSelf = self;
//    return ^(NSString *identifier,WSThemeConfigValueBlock valueBlock){
//            // 保存,identifier对应的 configblock
//        [weakSelf saveCustomBlock:valueBlock identifier:identifier valueType:WSThemeValueTypeColor];
//            // 执行一次界面更新
//        [weakSelf getValueFromMdodel:weakSelf.currentModel identifier:identifier valueType:WSThemeValueTypeColor valueBlock:valueBlock];
//        return weakSelf;
//    };
//}

-(WSThemeConfigFixedTypeBlock)fixedTypeBlock:(WSThemeValueType)valueType
{
    __weak typeof(self) weakSelf = self;
    return ^(NSString *identifier,WSThemeConfigValueBlock valueBlock){
            // 保存,identifier对应的 configblock
        [weakSelf saveCustomBlock:valueBlock identifier:identifier valueType:valueType];
            // 执行一次界面更新
        [weakSelf getValueFromMdodel:weakSelf.currentModel identifier:identifier valueType:valueType valueBlock:valueBlock];
        return weakSelf;
    };
}

-(WSThemeConfigFixedTypeBlock)original
{
    return [self fixedTypeBlock:WSThemeValueTypeOriginal];
}
-(WSThemeConfigFixedTypeBlock)text
{
    return [self fixedTypeBlock:WSThemeValueTypeJson];
}
-(WSThemeConfigFixedTypeBlock)color
{
    return [self fixedTypeBlock:WSThemeValueTypeColor];
}
-(WSThemeConfigFixedTypeBlock)font
{
    return [self fixedTypeBlock:WSThemeValueTypeFont];
}
-(WSThemeConfigFixedTypeBlock)image
{
    return [self fixedTypeBlock:WSThemeValueTypeImage];
}
-(WSThemeConfigFixedTypeBlock)data
{
    return [self fixedTypeBlock:WSThemeValueTypeData];
}
-(WSThemeConfigFixedTypeBlock)attribute
{
    return [self fixedTypeBlock:WSThemeValueTypeAttribute];
}


    // ================ 数据处理层 ================
-(void)saveCustomBlock:(WSThemeConfigValueBlock)valueBlock identifier:(NSString *)identifier valueType:(WSThemeValueType)valueType
{
    __weak typeof(self) weakSelf = self;
        // 保存,identifier对应的 configblock
    identifier = identifier?:(id)[NSNull null];
    [weakSelf.customBlockDict setObject:@[identifier,@(valueType)] forKey:valueBlock];
}

    // 通过 iddentifier 查找模板里的value, 执行回调block
-(void)getValueFromMdodel:(WSThemeModel *)theModel identifier:(NSString *)identifier valueType:(WSThemeValueType)valueType valueBlock:(WSThemeConfigValueBlock)valueBlock
{
    __weak typeof(self) weakSelf = self;
    NSOperation *dataOp = [NSBlockOperation blockOperationWithBlock:^{
        id value = [theModel getDataWithIdentifier:identifier backType:valueType];
        if (theModel == weakSelf.currentModel) {
            NSOperation *backOp = [NSBlockOperation blockOperationWithBlock:^{
                valueBlock(weakSelf.currentObject,value);
            }];
            [weakSelf.opLock lock];
            [weakSelf.operationList addObject:backOp];
            [weakSelf.opLock unlock];
            [[NSOperationQueue mainQueue] addOperation:backOp];
        }
    }];
    [self.opLock lock];
    [self.operationList addObject:dataOp];
    [self.opLock unlock];
    [self.updateQueue addOperation:dataOp];
}


-(void)cancelOperations
{
    // 取消 更新队列. (读数据,更新UI)
    NSArray *opList;
    [self.opLock lock];
    opList = [[self.operationList allObjects] copy];
    [self.operationList removeAllObjects];
    [self.opLock unlock];
    for (NSOperation *tempOp in opList) {[tempOp cancel];}
}

-(void)dealloc
{
    NSLog(@"config 系统回收:%@",self);
    _customBlockDict = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self cancelOperations];
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"<WSThemeConfig:%lx> object:<%@:%lx>",(unsigned long)self.hash,NSStringFromClass(self.currentObject.class),(unsigned long)self.currentObject.hash];
}


@end



#import <objc/runtime.h>
#import <objc/message.h>

static const NSString *WSThemeConfig_objectPropertyKey = @"WSThemeConfig_objectPropertyKey";

@implementation NSObject(WSTheme)

-(WSThemeConfig *)wsTheme
{
    WSThemeConfig *config = objc_getAssociatedObject(self, &WSThemeConfig_objectPropertyKey);
    if (!config) {
        @synchronized (self) {
            WSThemeConfig *tempConfig = objc_getAssociatedObject(self, &WSThemeConfig_objectPropertyKey);
            if(!tempConfig){
                tempConfig = [WSThemeConfig new];
                tempConfig.currentObject = self;
                objc_setAssociatedObject(self, &WSThemeConfig_objectPropertyKey, tempConfig , OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                NSLog(@"开始绑定 WSThemeConfig:%@",tempConfig);
            }
            config = tempConfig;
        }
    }
    return config;
}

@end




