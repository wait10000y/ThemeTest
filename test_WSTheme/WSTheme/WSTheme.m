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

@interface WSThemeModel()
@property(nonatomic) NSDictionary *mThemeDict; // json配置对象.

    // 缓存 已经转换后的对象,下次重复读取时,从这里加载;key: identifier; value: 已经转换后的内容
@property(nonatomic) NSMutableArray *cacheDictList; // 位置与 WSThemeValueType数值一一对应.
@property(nonatomic,weak) NSOperationQueue *updateQueue; // [WSTheme sharedObject].updateQueue 的弱引用.

@end

@implementation WSThemeModel

-(void)createDefaultData
{
    _cacheDictList = [[NSMutableArray alloc] initWithCapacity:WSThemeValueTypeNone];
    for (int it=0; it<WSThemeValueTypeNone; it++) {
        [_cacheDictList addObject:[NSMutableDictionary new]];
    }
}


+(instancetype)createWithJsonDict:(NSDictionary *)jsonDict withName:(NSString *)theName
{
    WSThemeModel *tempModel = [WSThemeModel new];
    BOOL isOK = [tempModel loadJsonDict:jsonDict withName:theName];
    NSLog(@"创建model:%@%@",tempModel,isOK?@"":@" 没有jsonDict定义.");
    return tempModel; // 未定义json 也可以返回空.
}

    // 添加模板 内容.json格式定义.
    // 已转换的json对象类型.
-(BOOL)loadJsonDict:(NSDictionary *)jsonDict withName:(NSString *)theName
{
    _name = theName;
    if ([jsonDict isKindOfClass:[NSDictionary class]]) {
        _mThemeDict = [jsonDict copy];
        [self createDefaultData];
        return YES;
    }
    return NO;
}

    // json对象定义文件地址.
-(BOOL)loadJsonFile:(NSString *)filePath withName:(NSString *)theName
{
    _name = theName;
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDir = YES;
    BOOL isFile = [fm fileExistsAtPath:filePath isDirectory:&isDir];
    if (isFile && !isDir) {
        NSData *jsonData = [NSData dataWithContentsOfFile:filePath];
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
        if ([dict isKindOfClass:[NSDictionary class]] && dict.count>0) {
            _mThemeDict = dict;
            [self createDefaultData];
            return YES;
        }
    }
    return NO;
}


    // block 形式加载. 回调线程是 updateQueue 线程;
    // 结果回调不受theme切换影响.
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

    // 获取原生值, identifier 支持keyPath格式.
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
    }else if (type ==WSThemeValueTypeImage){
        callSel = @selector(createImage:);
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
    // 主要转json格式的字符串形式.
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

    // 默认匹配转换. 支持 0x,#或者直接写的三种格式十六进制的字符串.
    // [0xffddffdd,#ffddffdd,ffddffdd], 八位时格式ARGB.六位时RGB.
    // 支持 NSNumber 类型, 该类型没有alpha项.
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

    // NSNumber,NSSting:默认字体指定字号大小值;
    // "fontName:20":指定字体名称和字号大小,:分隔符;
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

    // 支持的文件名类型:
    // "imgName" "imgName.jpg" "https://www.test.com/imgName.png"
-(UIImage *)createImage:(NSString *)imgName
{
    UIImage *value = [UIImage imageNamed:imgName];
    if (value) {return value;}

    if([imgName hasPrefix:@"/"]){ // 可能需要延时加载.
        return [UIImage imageWithContentsOfFile:imgName];
    }else{
        imgName = [imgName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSURL *tempUrl = [NSURL URLWithString:imgName];
        if(tempUrl){
            NSData *tempData = [NSData dataWithContentsOfURL:tempUrl];
            if (tempData) {
                return [UIImage imageWithData:tempData];
            }
        }
    }
    return nil;
}

    // 支持 NSAttributedString.h 定义的 attributeName字符串转换的key,对应的value值font,color类型自动转换,number,string使用原值,其他的属性暂不支持.
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


-(NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%lx> name:%@",NSStringFromClass(self.class),(unsigned long)self.hash,self.name];

}

-(void)dealloc
{
    NSLog(@"model系统回收:%@",self);
    _mThemeDict = nil;
    _cacheDictList = nil;
}


@end


#define WSThemeListCachedKey @"WSThemeListCachedKey"
#define WSThemeCurrentCachedKey @"WSThemeCurrentCachedKey"
#define WSThemeUpdateNotificaiton @"WSThemeUpdateNotificaiton"

@interface WSTheme()
@property(nonatomic) NSOperationQueue *updateQueue; // 线程队列(读取json配置数据,转化类型)
@property(nonatomic) NSHashTable *delegateTable; // delegate列表.
@property(nonatomic) NSHashTable *callBlockTable; // 事件队列.

@end

@implementation WSTheme
{
    NSMutableArray<NSString *> *mThemeNameList;
    NSString *currentName;
    WSThemeModel *currentModel;
    NSLock *opLock;
}

+(instancetype)sharedObject
{
    static dispatch_once_t onceTag;
    static id staticObject = nil;
    dispatch_once(&onceTag, ^{
        staticObject = [self new];
        [staticObject loadDefaultThemeData];
    });
    return staticObject;
}

// 加载默认的theme数据.
-(void)loadDefaultThemeData
{
        _updateQueue = [[NSOperationQueue alloc] init];
        _updateQueue.maxConcurrentOperationCount = 16;

    // 读取 记录的themeModel模板数据.
    NSArray *cachedNmaeList = [[NSUserDefaults standardUserDefaults] objectForKey:WSThemeListCachedKey];
    if ([cachedNmaeList isKindOfClass:[NSArray class]] && cachedNmaeList.count>0) {
        mThemeNameList = [NSMutableArray arrayWithArray:cachedNmaeList];
        NSString *cachedCurrentName = [[NSUserDefaults standardUserDefaults] objectForKey:WSThemeCurrentCachedKey];
        if (cachedCurrentName) {
            for (int it=0; it<mThemeNameList.count; it++) {
                NSString *tempName = mThemeNameList[it];
                if ([cachedCurrentName isEqualToString:tempName]) {
                    currentName = tempName;
                    break;
                }
            }
        }

    }else{
        mThemeNameList = [NSMutableArray new];
    }

    // 添加默认
    if (![mThemeNameList containsObject:WSThemeDefaultThemeName]) {
        [mThemeNameList addObject:WSThemeDefaultThemeName];
        [self saveThemeNameListStatus];
    }

    if (currentName==nil) {
        currentName = [mThemeNameList firstObject];
        [self saveCurrentThemeNameStatus];
    }

    currentModel = [self themeModelForName:currentName];
    if (!currentModel) {
        currentModel = [WSThemeModel new];
        currentModel.updateQueue = _updateQueue;
    }
}

// json 转换成的object.
-(WSThemeModel *)currentThemeModel
{
    return currentModel;
}

-(WSThemeModel *)themeModelForName:(NSString *)themeName
{
    WSThemeModel *tempModel;
    NSDictionary *jsonDict = [self themeJsonDictForName:themeName];
    if (jsonDict) {
        tempModel = [WSThemeModel createWithJsonDict:jsonDict withName:themeName];
        tempModel.updateQueue = _updateQueue;
    }
    return tempModel;
}

-(NSDictionary *)themeJsonDictForName:(NSString *)themeName
{
    NSDictionary *jsonDict;
    if ([WSThemeDefaultThemeName isEqualToString:themeName]) {
        NSString *jsonPath = [[NSBundle mainBundle] pathForResource:@"default" ofType:@"json"];
        if (jsonPath) {
            NSData *defaultData = [NSData dataWithContentsOfFile:jsonPath];
            jsonDict = [NSJSONSerialization JSONObjectWithData:defaultData options:0 error:nil];
        }
    }else{
        jsonDict = [self getObjectForKey:themeName];
    }
    return jsonDict;
}

-(NSString *)currentThemeName
{
    return currentName;
}
-(NSArray<NSString *> *)themeNameList
{
    return [NSArray arrayWithArray:mThemeNameList];
}

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

    currentName = theName;
    currentModel = [self themeModelForName:theName];
    [self saveCurrentThemeNameStatus];

        // 消息推送
    [[NSNotificationCenter defaultCenter] postNotificationName:WSThemeUpdateNotificaiton object:nil userInfo:nil];

    __weak typeof(self) weakSelf = self;
    NSOperation *newOp = [NSBlockOperation blockOperationWithBlock:^{
        [weakSelf willChangeValueForKey:@"currentThemeName"];
        [weakSelf didChangeValueForKey:@"currentThemeName"];// KVO消息
    }];
    [opLock lock];
    [_callBlockTable addObject:newOp];
    [opLock unlock];
    [[NSOperationQueue mainQueue] addOperation:newOp];

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

-(BOOL)addThemeJsonDictList:(NSArray<NSDictionary *> *)dictList withNameList:(NSArray<NSString *> *)nameList
{
    BOOL addNum = 0;
    BOOL updateNum = 0;
    for (int it=0; it<nameList.count; it++) {
        NSString *tempName = nameList[it];
        NSDictionary *tempDict;
        if(dictList.count>it){ // 是否一一对应.
            tempDict = dictList[it];
            BOOL hasSaved = [self saveObject:tempDict withKey:tempName];
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
        [self saveThemeNameListStatus];
        return YES;
    }
    return NO;
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
            if ([self saveObject:nil withKey:tempName]) {
                [mThemeNameList removeObjectAtIndex:index];
                subNum ++;
            }
        }
    }
    NSLog(@"主题删除:%d 个,剩余:%lu 个",subNum,(unsigned long)mThemeNameList.count);
    if (subNum>0) {
        [self saveThemeNameListStatus];
        return YES;
    }
    return NO;

}

// 清理缓存 model缓存.
-(BOOL)clearCacheData
{
    return YES;
}


// WSTheme/thmename
//
/**
主题目录.
 WSTheme/thmename/

 WSTheme/thmename/default.json
 WSTheme/thmename/default_tl.json
  WSTheme/thmename/files/...
 WSTheme/thmename/cached/keypath


 // 当前主题 状态.
 // array:所有主题,current:当前主题
 {current:"theme1","themelist":["theme1","theme2"]}
 WSTheme/theme.plist



 */

    // ================= tools ================= 
- (void)saveThemeNameListStatus{
    [[NSUserDefaults standardUserDefaults] setObject:mThemeNameList forKey:WSThemeListCachedKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)saveCurrentThemeNameStatus
{
    [[NSUserDefaults standardUserDefaults] setObject:currentName forKey:WSThemeCurrentCachedKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

// object为nil时,删除操作
-(BOOL)saveObject:(id)object withKey:(NSString *)key
{
    if (key==nil) {return NO;}
    NSString *dataPath = [self themeObjectPathForName:key];
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

-(id)getObjectForKey:(NSString*)key
{
    if (key==nil) {return nil;}
    NSString *dataPath = [self themeObjectPathForName:key];
    return [NSKeyedUnarchiver unarchiveObjectWithFile:dataPath];
}

- (NSString *)themeObjectPathForName:(NSString *)string
{
    NSString *basePath = [self themeMainPath:nil];
    return [basePath stringByAppendingPathComponent:string];
}


// =================== 目录工具 ===================
// 删除一个主题的所有文件和目录.
-(BOOL)removeThemeFilesWithName:(NSString *)themeName
{
    [self themeMainPath:themeName isAutoCreate:NO isClear:YES];
    return YES;
}

    // 主题列表保存路径
- (NSString *)themeListDataPath
{
    NSString *basePath = [self themeMainPath:nil];
    return [basePath stringByAppendingPathComponent:@"themeList.json"];
}

    // 当前主题保存路径
- (NSString *)themeCurrentDataPath
{
    NSString *basePath = [self themeMainPath:nil];
    return [basePath stringByAppendingPathComponent:@"currentTheme.json"];
}

// // 主题 cache路径(大文件等)
- (NSString *)themeDataCachePathForName:(NSString *)themeName fileName:(NSString *)fileName
{
    NSString *basePath = [self themeMainPath:themeName];
    return [basePath stringByAppendingPathComponent:[NSString stringWithFormat:@"cache/%@",fileName?:@""]];
}

// 主题 json路径
- (NSString *)themeJsonDictPathForName:(NSString *)themeName
{
    NSString *basePath = [self themeMainPath:themeName];
    return [basePath stringByAppendingPathComponent:@"theme.json"];
}
// 主题 模板路径
- (NSString *)themeTempleteDictPathForName:(NSString *)themeName
{
    NSString *basePath = [self themeMainPath:themeName];
    return [basePath stringByAppendingPathComponent:@"theme_tl.json"];
}

- (NSString *)themeMainPath:(NSString *)themeName
{
    return [self themeMainPath:themeName isAutoCreate:YES isClear:NO];
}

// 主题主目录+themeName目录,传值nil返回主目录.
// isCreate 是否自动创建不存在的目录.
// isClear 是否清空已存在的文件.
- (NSString *)themeMainPath:(NSString *)themeName isAutoCreate:(BOOL)isCreate isClear:(BOOL)isClear
{
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    path = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"WSTheme/%@",themeName?:@""]];
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




