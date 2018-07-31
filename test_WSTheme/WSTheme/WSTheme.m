//
//  WSTheme.m
//  Test_LEETheme
//
//  Created by wsliang on 2018/7/13.
//  Copyright © 2018年 wsliang. All rights reserved.
//

#import "WSTheme.h"
#import <objc/runtime.h>
#import <objc/message.h>

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
        currentModel = [WSThemeModel getThemeModelWithDict:jsonDict withName:currentName];
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
        return [WSThemeModel getThemeModelWithDict:jsonDict withName:themeName];
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
    currentModel = [WSThemeModel getThemeModelWithDict:jsonDict withName:theName];
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
            if ([self removeObjectForKey:tempName]) {
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
}

+(WSThemeModel *)getThemeModelWithDict:(NSDictionary *)themeDict withName:(NSString *)theName
{
    WSThemeModel *tempModel = [WSThemeModel new];
    BOOL isOK = [tempModel setThemeDict:themeDict withName:theName];
    NSLog(@"创建model:%@%@",tempModel,isOK?@"":@" 没有jsonDict定义.");
    return tempModel; // 未定义json 也可以返回空.
}

-(BOOL)setThemeDict:(NSDictionary *)jsonDict withName:(NSString *)theName
{
    _name = theName;
    if ([jsonDict isKindOfClass:[NSDictionary class]] && jsonDict.count>0) {
        mThemeDict = [jsonDict copy];
        return YES;
    }
    return NO;
}

-(id)getValueWithIdentifier:(NSString *)identifier
{
    return [mThemeDict valueForKeyPath:identifier];
}


-(NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%lx> name:%@",NSStringFromClass(self.class),(unsigned long)self.hash,self.name];
}

-(void)dealloc
{
    NSLog(@"model系统回收:%@",self);
        //    [updateQueue cancelAllOperations];
        //    updateQueue = nil;
        //
        //    mThemeDict = nil;
        //        //    @synchronized (colorValues) {
        //        //        [colorValues removeAllObjects];
        //        //    }
        //        //    @synchronized (fontValues) {
        //        //        [fontValues removeAllObjects];
        //        //    }
        //        //    @synchronized (imageValues) {
        //        //        [imageValues removeAllObjects];
        //        //    }
        //        //    @synchronized (attrsValues) {
        //        //        [attrsValues removeAllObjects];
        //        //    }
        //
        //    jsonValues = nil;
        //    colorValues = nil;
        //    fontValues = nil;
        //    imageValues = nil;
        //    attrsValues = nil;

}

@end


@interface WSThemeConfig()

    // 记录当前使用的 model.
@property(nonatomic,weak) WSThemeModel *currentModel;

// 注册的block列表缓存.
// key: valueBlock;value: identifier;
@property(nonatomic) NSMutableSet *configBlockSet;

@end
@implementation WSThemeConfig

- (instancetype)init
{
    self = [super init];
    if (self) {
        _configBlockSet = [NSMutableSet new];
        _currentModel = [WSTheme sharedObject].currentThemeModel;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(theme_ChangeModelNotify:) name:WSThemeChangingNotificaiton object:nil];
    }
    return self;
}

-(void)dealloc
{
    NSLog(@"config 系统回收:%@",self);
    [_configBlockSet removeAllObjects];
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
        for (WSThemeConfigValueBlock valueBlock in _configBlockSet) {
            valueBlock(_currentObject,_currentModel);
        }
        [self callOthersCofingWithCurrentModel:_currentModel];
    }
}


// 注册 更新theme的block回调
-(WSThemeConfigConfigBlock)config
{
    __weak typeof(self) weakSelf = self;
    return ^(WSThemeConfigValueBlock valueBlock)
    {
        if (!valueBlock) {return weakSelf;}
        // 保存,identifier对应的 configblock
        [weakSelf.configBlockSet addObject:valueBlock];
            // 执行一次界面更新
        valueBlock(weakSelf.currentObject,weakSelf.currentModel);
        return weakSelf;
    };
}


// TODO: 其他更新.扩展类实现.
-(void)callOthersCofingWithCurrentModel:(WSThemeModel *)theModel
{

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

