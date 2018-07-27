//
//  WSTheme.m
//  Test_LEETheme
//
//  Created by 王士良 on 2018/7/13.
//  Copyright © 2018年 王士良. All rights reserved.
//

#import "WSTheme.h"
#import <objc/runtime.h>
#import <objc/message.h>


#define isNull(_obj) (_obj==nil || _obj == (id)[NSNull null])

#define WSThemeListCachedKey @"WSThemeListCachedKey"
#define WSThemeCurrentCachedKey @"WSThemeCurrentCachedKey"

#define WSThemeChangingNotificaiton @"WSThemeChangingNotificaiton"
static const NSString *WSThemeConfig_objectPropertyKey = @"WSThemeConfig_objectPropertyKey";

@implementation WSTheme
{
    NSMutableArray<NSString *> *mThemeNameList;
    NSString *currentName;
    WSThemeModel *currentModel;
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

    if (currentName==nil) {
        currentName = [mThemeNameList firstObject];
    }

    if (currentName) {
        NSDictionary *jsonDict = [self getObjectForKey:currentName];
        currentModel = [WSThemeModel createWithJsonDict:jsonDict withName:currentName];
    }else{
        currentModel = [WSThemeModel new];
    }

    if (mThemeNameList.count>0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:WSThemeChangingNotificaiton object:nil userInfo:nil];
    }
}

// json 转换成的object.
-(WSThemeModel *)currentThemeModel
{
    return currentModel;
}

-(WSThemeModel *)themeModelForName:(NSString *)themeName
{
    if (themeName.length>0 && [mThemeNameList containsObject:themeName]) {
        NSDictionary *jsonDict = [self getObjectForKey:themeName];
        return [WSThemeModel createWithJsonDict:jsonDict withName:themeName];
    }
    return nil;
}

-(NSDictionary *)themeJsonDictForName:(NSString *)themeName
{
    if (themeName.length>0 && [mThemeNameList containsObject:themeName]) {
        NSDictionary *jsonDict = [self getObjectForKey:themeName];
        return jsonDict;
    }
    return nil;
}

-(NSString *)currentThemeName
{
    return currentName;
}
-(NSArray<NSString *> *)themeNameList
{
    return [NSArray arrayWithArray:mThemeNameList];
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
    currentName = theName;
    NSDictionary *jsonDict = [self getObjectForKey:theName];
    currentModel = [WSThemeModel createWithJsonDict:jsonDict withName:theName];
    [[NSNotificationCenter defaultCenter] postNotificationName:WSThemeChangingNotificaiton object:nil userInfo:nil];
    [self saveCurrentThemeNameStatus];
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

    NSLog(@"主题添加:%d 个,更新:%d 个,共有:%d 个主题",addNum,updateNum,mThemeNameList.count);
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
            if ([self removeObjectForKey:tempName]) {
                [mThemeNameList removeObjectAtIndex:index];
                subNum ++;
            }
        }
    }
    NSLog(@"主题删除:%d 个,剩余:%d 个",subNum,mThemeNameList.count);
    if (subNum>0) {
        [self saveThemeNameListStatus];
        return YES;
    }
    return NO;

}


    // tools
- (void)saveThemeNameListStatus{
    [[NSUserDefaults standardUserDefaults] setObject:mThemeNameList forKey:WSThemeListCachedKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)saveCurrentThemeNameStatus
{
    [[NSUserDefaults standardUserDefaults] setObject:currentName forKey:WSThemeCurrentCachedKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


-(BOOL)saveObject:(id)object withKey:(NSString *)key
{
    if (key==nil) {return NO;}
    if (object) {
        NSString *dataPath = [self themeObjectPathForName:key];
        NSData *objData = [NSKeyedArchiver archivedDataWithRootObject:object];
        return [objData writeToFile:dataPath options:NSDataWritingAtomic error:nil];
    }
    return NO;
}

-(id)getObjectForKey:(NSString*)key
{
    if (key==nil) {return nil;}
    NSString *dataPath = [self themeObjectPathForName:key];
    return [NSKeyedUnarchiver unarchiveObjectWithFile:dataPath];
}

-(BOOL)removeObjectForKey:(NSString*)key
{
    if (key==nil) {return NO;}
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *dataPath = [self themeObjectPathForName:key];
    if ([fm fileExistsAtPath:dataPath]) {
        return [fm removeItemAtPath:dataPath error:nil];
    }
    return YES;
}

- (NSString *)themeObjectPathForName:(NSString *)string
{
    NSString *basePath = [self themeMainPath];
    return [basePath stringByAppendingPathComponent:string];
}

- (NSString *)themeMainPath
{
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        path = [path stringByAppendingPathComponent:@"WSTheme"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSError *error;
        BOOL isOK = [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
        if (!isOK) {
            return nil;
        }
    }
    return path;
}

@end


@implementation WSThemeModel
{
    NSDictionary *mThemeDict; // json配置对象.

    // 缓存 已经转换后的对象,下次重复读取时,从这里加载.
    NSMutableDictionary *jsonValues;
    NSMutableDictionary *colorValues; // key: identifier; value: 已经转换后的内容.
    NSMutableDictionary *imageValues;
    NSMutableDictionary *attrsValues;
    NSMutableDictionary *fontValues;

        // 刷新theme更新的队列
    NSOperationQueue *updateQueue;

}

-(void)createDefaultData
{
    jsonValues = [NSMutableDictionary new];
    colorValues = [NSMutableDictionary new];
    fontValues = [NSMutableDictionary new];
    imageValues = [NSMutableDictionary new];
    attrsValues = [NSMutableDictionary new];

                updateQueue = [NSOperationQueue new];
                updateQueue.maxConcurrentOperationCount = 10;
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
    if ([jsonDict isKindOfClass:[NSDictionary class]] && jsonDict.count>0) {
        mThemeDict = [jsonDict copy];
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
            mThemeDict = dict;
            [self createDefaultData];
            return YES;
        }
    }
    return NO;
}


-(NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%x> name:%@",NSStringFromClass(self.class),self.hash,self.name];

}

-(void)dealloc
{
    NSLog(@"model系统回收:%@",self);
    [updateQueue cancelAllOperations];
    updateQueue = nil;

    mThemeDict = nil;
//    @synchronized (colorValues) {
//        [colorValues removeAllObjects];
//    }
//    @synchronized (fontValues) {
//        [fontValues removeAllObjects];
//    }
//    @synchronized (imageValues) {
//        [imageValues removeAllObjects];
//    }
//    @synchronized (attrsValues) {
//        [attrsValues removeAllObjects];
//    }

    jsonValues = nil;
    colorValues = nil;
    fontValues = nil;
    imageValues = nil;
    attrsValues = nil;

}

// block 形式加载. 回调线程是 updateQueue 线程
-(void)getDataWithIdentifier:(NSString *)identifier backType:(WSThemeValueType)type complete:(void(^)(id value))complete
{
    if (isNull(identifier) || isNull(mThemeDict)) {complete(nil);return;}

    if(complete){
        __weak typeof(self) weakSelf = self;
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//
//            complete([weakSelf getDataWithIdentifier:identifier backType:type]);
//        });
//        void(^tempBlock)(id value) = [complete copy];
        [updateQueue addOperationWithBlock:^{
            id value = [weakSelf getDataWithIdentifier:identifier backType:type];
            complete(value);
        }];
    }
}

    // 获取原生值, identifier 支持keyPath格式.
-(id)getDataWithIdentifier:(NSString *)identifier backType:(WSThemeValueType)type
{
    if (isNull(identifier) || isNull(mThemeDict)) {return nil;}
    SEL callSel = NULL;
    NSMutableDictionary *typeDict;
    if (type == WSThemeValueTypeOriginal) {
        return [mThemeDict valueForKeyPath:identifier];
    }else if (type == WSThemeValueTypeJson) {
        typeDict = jsonValues;
        callSel = @selector(createJsonText:);
    }else if (type == WSThemeValueTypeColor) {
        typeDict = colorValues;
        callSel = @selector(createColor:);
    }else if (type ==WSThemeValueTypeImage){
        typeDict = imageValues;
        callSel = @selector(createImage:);
    }else if (type ==WSThemeValueTypeFont){
        typeDict = fontValues;
        callSel = @selector(createFont:);
    }else if (type ==WSThemeValueTypeAttribute){
        typeDict = attrsValues;
        callSel = @selector(createAttributes:);
    }else{
            // 默认情况.
        return [mThemeDict valueForKeyPath:identifier];
    }

    if (typeDict) {
        id backValue;
        @synchronized (typeDict) {
            backValue = [typeDict objectForKey:identifier];
        }
        if (backValue) {
            return isNull(backValue)?nil:backValue;
        }else{
            id tempValue = [mThemeDict valueForKeyPath:identifier];
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


@end


@interface WSThemeConfig()

    // 记录当前使用的 model.
@property(nonatomic,weak) WSThemeModel *currentModel;
    // 关联的更新对象.
@property(nonatomic,weak) NSObject *currentObject;

// 注册的block列表缓存.
// key: valueBlock;value: identifier;
@property(nonatomic) NSMutableDictionary *configBlockDict;

@end
@implementation WSThemeConfig

- (instancetype)init
{
    self = [super init];
    if (self) {
        _configBlockDict = [NSMutableDictionary new];
        _currentModel = [WSTheme sharedObject].currentThemeModel;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(theme_ChangeModelNotify:) name:WSThemeChangingNotificaiton object:nil];
    }
    return self;
}

-(void)dealloc
{
    NSLog(@"config 系统回收:%@",self);
    [_configBlockDict removeAllObjects];
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:WSThemeChangingNotificaiton object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"<WSThemeConfig:%lx> object:<%@:%lx>",(unsigned long)self.hash,NSStringFromClass(self.currentObject.class),(unsigned long)self.currentObject.hash];
}


    // 接收更新通知, 执行theme切换更新
-(void)theme_ChangeModelNotify:(id)sender
{
    NSLog(@"收到切换theme通知:%@",self);
    WSThemeModel *currentModel = [WSTheme sharedObject].currentThemeModel;
    if (!_currentModel || ![_currentModel.name isEqual:currentModel.name]) {
        NSLog(@"开始更新对象:<%@:%lx>",NSStringFromClass(self.currentObject.class),(unsigned long)self.currentObject.hash);
        _currentModel = currentModel;
        __weak typeof(self) weakSelf = self;
        [_configBlockDict enumerateKeysAndObjectsUsingBlock:^(WSThemeConfigCustomValueBlock valueBlock, NSArray *attrs, BOOL *stop) {
            [weakSelf getValueForIdentifier:[attrs firstObject] valueType:[(NSNumber *)[attrs lastObject] unsignedLongValue] valueBlock:valueBlock];
        }];
    }
}


// 注册 更新theme的block回调
-(WSThemeConfigCustomBlock)custom
{

    __weak typeof(self) weakSelf = self;
    return ^(NSString *identifier,WSThemeValueType valueType, WSThemeConfigCustomValueBlock valueBlock)
    {
        if (!valueBlock) {return weakSelf;}
        // 保存,identifier对应的 configblock
        [weakSelf saveCustomBlock:valueBlock identifier:identifier valueType:valueType];
            // 执行一次界面更新
        [weakSelf getValueForIdentifier:identifier valueType:valueType valueBlock:valueBlock];
        return weakSelf;
    };
}

-(void)saveCustomBlock:(WSThemeConfigCustomValueBlock)valueBlock identifier:(NSString *)identifier valueType:(WSThemeValueType)valueType
{
    __weak typeof(self) weakSelf = self;
        // 保存,identifier对应的 configblock
    identifier = identifier?:(id)[NSNull null];
    @synchronized (self) {
        [weakSelf.configBlockDict setObject:@[identifier,@(valueType)] forKey:valueBlock];
    }

}

// 通过 iddentifier 查找模板里的value, 执行回调block
-(void)getValueForIdentifier:(NSString *)identifier valueType:(WSThemeValueType)valueType valueBlock:(WSThemeConfigCustomValueBlock)valueBlock
{
    __weak typeof(self) weakSelf = self;
    [_currentModel getDataWithIdentifier:identifier backType:valueType complete:^(id theValue) {
        dispatch_async(dispatch_get_main_queue(), ^{
            valueBlock(weakSelf.currentObject,theValue);
        });
    }];
}

-(WSThemeConfigDefinedTypeBlock)color
{
    __weak typeof(self) weakSelf = self;
    return ^(NSString *identifier,WSThemeConfigCustomValueBlock valueBlock){

            // 保存,identifier对应的 configblock
        [weakSelf saveCustomBlock:valueBlock identifier:identifier valueType:WSThemeValueTypeColor];
            // 执行一次界面更新
        [weakSelf getValueForIdentifier:identifier valueType:WSThemeValueTypeColor valueBlock:valueBlock];

        return weakSelf;
    };
}

@end


@implementation NSObject(WSTheme)

-(WSThemeConfig *)theme
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

