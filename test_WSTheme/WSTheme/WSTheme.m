//
//  WSTheme.m
//  Test_LEETheme
//
//  Created on 2018/7/13.
//  wsliang.
//

#import "WSTheme.h"

NSNotificationName const WSThemeUpdateNotificaiton = @"WSThemeUpdateNotificaiton";

#define NSLog(format, ...) do {(NSLog)((format), ##__VA_ARGS__);} while (0)
#define isNull(_obj) (_obj==nil || _obj == (id)[NSNull null])
#define isJsonObject(_obj) ([_obj isKindOfClass:[NSDictionary class]] || [_obj isKindOfClass:[NSArray class]])

#define WSThemeUpdateMaxThreadNumber 16 // 线程池大小


@implementation WSThemeFile

-(instancetype)initWithThemePackagePath:(NSString *)thePath
{
    self = [super init];
    if (self) {
        [self setThemePackagePath:thePath];
    }
    return self;
}

-(instancetype)initWithThemeName:(NSString *)theThemeName
{
    self = [super init];
    if (self) {
        _themePath = [WSThemeFile themeMainPath:theThemeName];
    }
    return self;
}

-(void)setThemePackagePath:(NSString *)thePath
{
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:thePath]) {
        [fm createDirectoryAtPath:thePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    _themePath = thePath;
}
-(void)setThemePackagePathWithName:(NSString *)theThemeName
{
    _themePath = [WSThemeFile themeMainPath:theThemeName];
}

-(NSDictionary *)loadThemeDict
{
    NSData *tempData = [NSData dataWithContentsOfFile:[self getThemeDictPath]];
    if (tempData) {
        return [NSJSONSerialization JSONObjectWithData:tempData options:0 error:nil];
    }
    return nil;
}

-(NSData *)loadThemeResourceWithName:(NSString *)fileName
{
    if (fileName) {
        return [NSData dataWithContentsOfFile:[self getThemeResourcePathWithName:fileName]];
    }
    return nil;
}

-(NSData *)loadThemeCacheFileWithName:(NSString *)fileName
{
    if (fileName) {
        return [NSData dataWithContentsOfFile:[self getThemeCachePathWithName:fileName]];
    }
    return nil;
}

-(BOOL)saveThemeDict:(NSDictionary *)themeDict
{
    if (isJsonObject(themeDict)) {
        NSData *fileData = [NSJSONSerialization dataWithJSONObject:themeDict options:0 error:nil];
        if (fileData) {
            return [fileData writeToFile:[self getThemeDictPath] atomically:YES];
        }
    }
    return NO;
}

-(BOOL)saveThemeResourceData:(NSData *)theData withName:(NSString *)fileName
{
    if (fileName) {
        if (theData) {
            return [theData writeToFile:[self getThemeResourcePathWithName:fileName] atomically:YES];
        }else{
            NSString *tempPath = [self getThemeResourcePathWithName:fileName];
            NSFileManager *fm = [NSFileManager defaultManager];
            if ([fm fileExistsAtPath:tempPath]) {
                return [fm removeItemAtPath:tempPath error:nil];
            }
            return YES;
        }
    }
    return NO;
}

-(BOOL)saveThemeResourceFile:(NSString *)theFilePath withName:(NSString *)fileName
{
    if (fileName) {
        NSString *tempPath = [self getThemeResourcePathWithName:fileName];
        NSFileManager *fm = [NSFileManager defaultManager];
        if ([fm fileExistsAtPath:theFilePath]) {// theFilePath存在数据就是保存
            return [fm copyItemAtPath:theFilePath toPath:tempPath error:nil];
        }else{
            if ([fm fileExistsAtPath:tempPath]) {
                return [fm removeItemAtPath:tempPath error:nil];
            }
            return YES;
        }
    }
    return NO;
}

-(BOOL)saveThemeCacheData:(NSData *)theData withName:(NSString *)fileName
{
    NSString *filePath = [self getThemeCachePathWithName:fileName];
    if (theData) { // 添加,修改
        return [theData writeToFile:filePath atomically:YES];
    }else{ // 删除
        NSFileManager *fm = [NSFileManager defaultManager];
        if ([fm fileExistsAtPath:filePath]) {
            [fm removeItemAtPath:filePath error:nil];
        }
        return YES;
    }
    return NO;
}

-(BOOL)removeTheme
{
    if (_themePath) {
        NSFileManager *fm = [NSFileManager defaultManager];
        if ([fm fileExistsAtPath:_themePath]) {
            return [fm removeItemAtPath:_themePath error:nil];
        }
    }
    return YES;
}

-(BOOL)copyThemeToPackagePath:(NSString *)thePath
{
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:_themePath]) {
        if ([fm fileExistsAtPath:thePath]) { // 清除内容.
            [fm removeItemAtPath:thePath error:nil];
            NSString *tempPath = [thePath stringByDeletingLastPathComponent];
            if (![fm fileExistsAtPath:tempPath]) {
                [fm createDirectoryAtPath:tempPath withIntermediateDirectories:YES attributes:nil error:nil];
            }
        }
        BOOL isOK = [fm copyItemAtPath:_themePath toPath:thePath error:nil];
        if (isOK) {// 删除缓存.
            [fm removeItemAtPath:[thePath stringByAppendingPathComponent:WSThemeFileManager_themeCacheFilesPath] error:nil];
        }
        return isOK;
    }
    return NO;
}


// ----- path utils -------

    // 主题 资源文件路径
- (NSString *)getThemeResourcePathWithName:(NSString *)fileName
{
    NSString *tempPath = [_themePath stringByAppendingPathComponent:WSThemeFileManager_themeResourcePath];
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:tempPath]) {
        [fm createDirectoryAtPath:tempPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return fileName?[tempPath stringByAppendingPathComponent:fileName]:fileName;
}

- (NSString *)getThemeCachePathWithName:(NSString *)fileName
{
    NSString *tempPath = [_themePath stringByAppendingPathComponent:WSThemeFileManager_themeCacheFilesPath];
    if (fileName) {
        NSFileManager *fm = [NSFileManager defaultManager];
        if (![fm fileExistsAtPath:tempPath]) {
            [fm createDirectoryAtPath:tempPath withIntermediateDirectories:YES attributes:nil error:nil];
        }
        return [tempPath stringByAppendingPathComponent:fileName];
    }
    return tempPath;
}

    // 主题 json路径
- (NSString *)getThemeDictPath
{
    return [_themePath stringByAppendingPathComponent:WSThemeFileManager_themeJsonName];
}

    // 返回theme主目录,如果不存在自动创建.
+ (NSString *)themeMainPath:(NSString *)themeName
{
    return [self themeMainPath:themeName isAutoCreate:YES isClear:NO];
}

    // 主题主目录+themeName目录,传值nil返回主目录.
    // isCreate 是否自动创建不存在的目录.
    // isClear 是否清空已存在的文件.
+ (NSString *)themeMainPath:(NSString *)themeName isAutoCreate:(BOOL)isCreate isClear:(BOOL)isClear
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

+(BOOL)themeNameListSave:(NSArray *)themeNameList
{
    NSString *basePath = [[self themeMainPath:nil] stringByAppendingPathComponent:WSThemeFileManager_themeNameListName];
    return [themeNameList writeToFile:basePath atomically:YES];
}

+(BOOL)themeCurrentNameSave:(NSString *)themeName
{
    NSString *basePath = [[self themeMainPath:nil] stringByAppendingPathComponent:WSThemeFileManager_themeNameCurrentName];
    return [themeName writeToFile:basePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

+(NSArray *)themeNameList
{
    NSString *basePath = [[self themeMainPath:nil] stringByAppendingPathComponent:WSThemeFileManager_themeNameListName];
    NSArray *tempArr = [NSArray arrayWithContentsOfFile:basePath];
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

+(NSString *)themeCurrentName
{
    NSString *basePath = [[self themeMainPath:nil] stringByAppendingPathComponent:WSThemeFileManager_themeNameCurrentName];
    return [NSString stringWithContentsOfFile:basePath encoding:NSUTF8StringEncoding error:nil];
}

+(BOOL)saveNewTheme:(NSString *)themeName withPackagePath:(NSString *)thePath
{
    if (themeName && thePath) {
        NSFileManager *fm = [NSFileManager defaultManager];
        if ([fm fileExistsAtPath:thePath]) {
            NSString *tempPath = [self themeMainPath:themeName isAutoCreate:NO isClear:YES];
            return [fm copyItemAtPath:thePath toPath:tempPath error:nil];
        }
    }
    return NO;
}

+(BOOL)saveNewTheme:(NSString *)themeName withThemeDict:(NSDictionary *)themeDict
{
    if(themeName && isJsonObject(themeDict)){
        NSData *fileData = [NSJSONSerialization dataWithJSONObject:themeDict options:0 error:nil];
        if (fileData) {
            NSString *dictPath = [[self themeMainPath:themeName] stringByAppendingPathComponent:WSThemeFileManager_themeJsonName];
            return [fileData writeToFile:dictPath atomically:YES];
        }
    }
    return NO;
}

@end


@interface WSTheme()
@property(nonatomic) NSOperationQueue *updateQueue; // 线程队列(读取json配置数据,转化类型)
//@property(nonatomic) WSThemeFileManager *themeFileUtil; // 文件处理工具.
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

@dynamic currentThemeModel;
@dynamic currentThemeName;
@dynamic themeNameList;

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

    // 读取 记录的themeModel模板数据.
    mThemeNameList = [NSMutableArray arrayWithArray:[WSThemeFile themeNameList]];
    currentName = [WSThemeFile themeCurrentName];
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
    [WSThemeFile themeCurrentNameSave:currentName];
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
    WSThemeFile *tempFile = [WSThemeFile new];
    for (int it=0; it<nameList.count; it++) {
        NSString *tempName = [nameList[it] copy];
        NSDictionary *tempDict;
        if(dictList.count>it){ // 是否一一对应.
            tempDict = dictList[it];
            [tempFile setThemePackagePathWithName:tempName];
            BOOL hasSaved = [tempFile saveThemeDict:tempDict];
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
        [WSThemeFile themeNameListSave:mThemeNameList];
    }
    return (addNum+updateNum);
}

-(BOOL)removeThemes:(NSArray<NSString *> *)nameList
{
    BOOL subNum = 0;
    WSThemeFile *tempFile = [WSThemeFile new];
    for (NSString *tempName in nameList) {
        if ([tempName isEqualToString:currentName]) { // 当前主题使用的不可删除.
            continue;
        }
        NSUInteger index = [mThemeNameList indexOfObject:tempName];
        if (index != NSNotFound) {
            [tempFile setThemePackagePathWithName:tempName];
            if ([tempFile removeTheme]) {
                [mThemeNameList removeObjectAtIndex:index];
                subNum ++;
            }
        }
    }
    NSLog(@"主题删除:%d 个,剩余:%lu 个",subNum,(unsigned long)mThemeNameList.count);
    if (subNum>0) {
        [WSThemeFile themeNameListSave:mThemeNameList];
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
        BOOL hasAdd = [WSThemeFile saveNewTheme:tempName withPackagePath:tempPath];
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
        [WSThemeFile themeNameListSave:mThemeNameList];
    }
    return addNum+updateNum;
}

    // TODO: 修改成 新的model
-(WSThemeModel *)themeModelForName:(NSString *)themeName
{
    if ([currentModel.name isEqualToString:themeName]) {
        return currentModel;
    }
    return [WSThemeModel createWithName:themeName];
}

@end



@interface WSThemeModel()
@property(nonatomic) NSDictionary *mThemeDict; // json配置对象.
    // 缓存 已经转换后的对象,下次重复读取时,从这里加载;key: identifier; value: 已经转换后的内容
@property(nonatomic) NSMutableArray *cacheDictList; // 位置与 WSThemeValueType数值一一对应.
@property(nonatomic) WSThemeFile *themeFileUtil;
@end

@implementation WSThemeModel

-(NSDictionary *)themeDict
{
    return _mThemeDict;
}

-(NSOperationQueue *)updateQueue
{
    return [WSTheme sharedObject].updateQueue;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _themeFileUtil = [WSThemeFile new];
    }
    return self;
}

-(void)createDefaultData
{
    // 检查物理缓存
    NSData *tempData = [_themeFileUtil loadThemeCacheFileWithName:@"WSThemeModel_cachedDictList"];
    NSArray *tempArray = [NSKeyedUnarchiver unarchiveObjectWithData:tempData];
    if(![tempArray isKindOfClass:[NSArray class]]){ tempArray = nil; }

    _cacheDictList = [[NSMutableArray alloc] initWithCapacity:WSThemeValueTypeOriginal];
    for (int it=0; it<WSThemeValueTypeOriginal; it++) {
        NSDictionary *tempDict = (tempArray.count>it)?tempArray[it]:nil;
        [_cacheDictList addObject:[[NSMutableDictionary alloc] initWithDictionary:tempDict]];
    }
}

+(instancetype)createWithPackagePath:(NSString *)thePath
{
    WSThemeModel *tempModel = [WSThemeModel new];
    BOOL isOK = [tempModel loadThemeDataWithPackagePath:thePath];
    NSLog(@"themePath 创建model:%@%@",tempModel,isOK?@"":@" 没有jsonDict定义.");
    return tempModel; // 未定义json 也可以返回空.
}

-(BOOL)loadThemeDataWithPackagePath:(NSString *)thePath
{
    _name = [thePath lastPathComponent];
    [_themeFileUtil setThemePackagePath:thePath];
    _mThemeDict = [_themeFileUtil loadThemeDict];
    [self createDefaultData];
    return YES;
}

+(instancetype)createWithName:(NSString *)theName
{
    WSThemeModel *tempModel = [WSThemeModel new];
    BOOL isOK = [tempModel loadThemeDataWithName:theName];
    NSLog(@"themeName 创建model:%@%@",tempModel,isOK?@"":@" 没有jsonDict定义.");
    return tempModel; // 未定义json 也可以返回空.
}

-(BOOL)loadThemeDataWithName:(NSString *)themeName
{
    _name = themeName;
    [_themeFileUtil setThemePackagePathWithName:themeName];
    _mThemeDict = [_themeFileUtil loadThemeDict];
    [self createDefaultData];
    return YES;
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
        return [self createData:tempValue];
    }else if (type ==WSThemeValueTypeImage){
            //        callSel = @selector(createImage:);
        id tempValue = [_mThemeDict valueForKeyPath:identifier];
        return [self createImage:tempValue];
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
    if (isJsonObject(value)) {
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
    if ([value isKindOfClass:[NSString class]] && value.length>0) {
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
            return [UIFont fontWithName:[fonts firstObject] size:size]?:[UIFont systemFontOfSize:size];
        }
    }else{
        int size = [[fontSize description] intValue];
        if (size>0) {
            return [UIFont systemFontOfSize:size];
        }
    }
    return nil;
}

/**
 支持的文件名类型:
 "imgName" "imgName.jpg"
 */
-(UIImage *)createImage:(NSString *)imgName
{
    UIImage *tempImg = [UIImage imageWithContentsOfFile:[_themeFileUtil getThemeResourcePathWithName:imgName]];
    if (!tempImg) {
        tempImg = [UIImage imageNamed:imgName];
    }
    return tempImg;
}

// 读取data对象,数据类型同image.
-(NSData *)createData:(NSString *)theDataName
{
    NSData *tempData = [NSData dataWithContentsOfFile:[_themeFileUtil getThemeResourcePathWithName:theDataName]];
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
    return @"";
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
    NSString *resPath = [_themeFileUtil getThemeResourcePathWithName:theName];
    [UIImagePNGRepresentation(theImage) writeToFile:resPath atomically:YES];
    return theName;
}

-(NSString *)parseData:(NSData *)theData withName:(NSString *)theName
{
    NSString *resPath = [_themeFileUtil getThemeResourcePathWithName:theName];
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
    if (_themeFileUtil && _cacheDictList.count>0) {
        NSData *dictData = [NSKeyedArchiver archivedDataWithRootObject:_cacheDictList];
        [_themeFileUtil saveThemeCacheData:dictData withName:@"WSThemeModel_cachedDictList"];
    }
    _mThemeDict = nil;
    _cacheDictList = nil;
}


@end



@interface WSThemeConfig()
@property(nonatomic,weak) NSObject *currentObject; // 关联的更新对象.
@property(nonatomic,weak) WSThemeModel *currentModel; // 记录当前使用的 model.
@property(nonatomic,weak) NSOperationQueue *updateQueue; // [WSTheme sharedObject].updateQueue 的弱引用.
@property(nonatomic) NSHashTable *operationList; // 保存正在执行和将要执行的NSOperation列表.
@property(nonatomic) NSLock *opLock;

@property(nonatomic) NSMutableDictionary *customBlockDict; // 注册的block列表缓存. // key: valueBlock;value: identifier;

@end

@implementation WSThemeConfig

@dynamic custom;
@dynamic original;
@dynamic text;
@dynamic color;
@dynamic font;
@dynamic image;
@dynamic data;
@dynamic attribute;

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

@implementation NSObject(WSTheme)

-(WSThemeConfig *)wsTheme
{
    WSThemeConfig *config = objc_getAssociatedObject(self, __func__);
    if (!config) {
        @synchronized (self) {
            WSThemeConfig *tempConfig = objc_getAssociatedObject(self, __func__);
            if(!tempConfig){
                tempConfig = [WSThemeConfig new];
                tempConfig.currentObject = self;
                objc_setAssociatedObject(self, __func__, tempConfig , OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                NSLog(@"开始绑定 WSThemeConfig:%@",tempConfig);
            }
            config = tempConfig;
        }
    }
    return config;
}

@end




