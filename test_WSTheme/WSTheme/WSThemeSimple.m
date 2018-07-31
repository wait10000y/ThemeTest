//
//  WSThemeSimple.m
//  test_WSTheme
//
//  Created by wsliang on 2018/7/31.
//  Copyright © 2018年 wsliang. All rights reserved.
//

#import "WSThemeSimple.h"

#define WSThemeSimpleThemeListCachedKey @"WSThemeSimpleThemeListCachedKey"
#define WSThemeSimpleCurrentNameCachedKey @"WSThemeSimpleCurrentNameCachedKey"
#define WSThemeSimpleUpdateNotificaiton @"WSThemeSimpleUpdateNotificaiton"
static const NSString *WSThemeSimpleTheme_objectPropertyKey = @"WSThemeSimpleTheme_objectPropertyKey";

@implementation WSThemeSimple
{
    NSMutableArray<NSString *> *mThemeNameList;
    NSString *currentName;
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
    NSArray *cachedNmaeList = [[NSUserDefaults standardUserDefaults] objectForKey:WSThemeSimpleThemeListCachedKey];
    if ([cachedNmaeList isKindOfClass:[NSArray class]] && cachedNmaeList.count>0) {
        mThemeNameList = [NSMutableArray arrayWithArray:cachedNmaeList];
        NSString *cachedCurrentName = [[NSUserDefaults standardUserDefaults] objectForKey:WSThemeSimpleCurrentNameCachedKey];
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

    if (mThemeNameList.count>0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:WSThemeSimpleUpdateNotificaiton object:nil userInfo:nil];
    }
}

    // 所有主题
-(NSArray<NSString *> *)themeNameList
{
    return [NSArray arrayWithArray:mThemeNameList];
}
-(NSString *)currentThemeName
{
    return [currentName copy];
}

    // 切换新主题.
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
    [self saveCurrentThemeNameStatus];
    [[NSNotificationCenter defaultCenter] postNotificationName:WSThemeSimpleUpdateNotificaiton object:nil userInfo:nil];

    return YES;
}

-(BOOL)addThemeWithNameList:(NSArray<NSString *> *)nameList
{
    BOOL addNum = 0;
    BOOL updateNum = 0;
    for (int it=0; it<nameList.count; it++) {
        NSString *tempName = nameList[it];
        if ([mThemeNameList containsObject:tempName]) { // 更新
            updateNum ++;
        }else{ // 添加
            [mThemeNameList addObject:tempName];
            addNum ++;
        }
    }

    NSLog(@"主题添加:%d 个,未添加:%d 个,共有:%lu 个主题",addNum,updateNum,(unsigned long)mThemeNameList.count);
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
            [mThemeNameList removeObjectAtIndex:index];
            subNum ++;
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
    [[NSUserDefaults standardUserDefaults] setObject:mThemeNameList forKey:WSThemeSimpleThemeListCachedKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)saveCurrentThemeNameStatus
{
    [[NSUserDefaults standardUserDefaults] setObject:currentName forKey:WSThemeSimpleCurrentNameCachedKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end


@interface WSThemeSimpleConfig()
    // 关联的更新对象.
@property(nonatomic,weak) NSObject *currentObject;
    // 记录当前使用的 theme.
@property(nonatomic,weak) NSString *currentTheme;

    // 注册的block列表缓存.
    // key: valueBlock;value: identifier;
@property(nonatomic) NSMutableSet *configBlockSet;

@end

@implementation WSThemeSimpleConfig

- (instancetype)init
{
    self = [super init];
    if (self) {
        _configBlockSet = [NSMutableSet new];
        _currentTheme = [WSThemeSimple sharedObject].currentThemeName;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(theme_ChangeModelNotify:) name:WSThemeSimpleUpdateNotificaiton object:nil];
    }
    return self;
}


    // 接收更新通知, 执行theme切换更新
-(void)theme_ChangeModelNotify:(id)sender
{
    NSLog(@"收到切换theme通知:%@",self);
    NSString *currentTheme = [WSThemeSimple sharedObject].currentThemeName;
    if (!_currentTheme || ![_currentTheme isEqual:currentTheme]) {
        NSLog(@"开始更新对象:<%@:%lx>",NSStringFromClass(self.currentObject.class),(unsigned long)self.currentObject.hash);
        _currentTheme = currentTheme;
        for (WSThemeSimpleConfigValueBlock valueBlock in _configBlockSet) {
            valueBlock(_currentObject,_currentTheme);
        }
    }
}


    // 注册 更新theme的block回调
-(WSThemeSimpleConfigConfigBlock)custom
{
    __weak typeof(self) weakSelf = self;
    return ^(WSThemeSimpleConfigValueBlock valueBlock)
    {
        if (!valueBlock) {return weakSelf;}
            // 保存,identifier对应的 configblock
        [weakSelf.configBlockSet addObject:valueBlock];
            // 执行一次界面更新
        valueBlock(weakSelf.currentObject,weakSelf.currentTheme);
        return weakSelf;
    };
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
    return [NSString stringWithFormat:@"<WSThemeSimpleConfig:%lx> object:<%@:%lx>",(unsigned long)self.hash,NSStringFromClass(self.currentObject.class),(unsigned long)self.currentObject.hash];
}


@end

#import <objc/runtime.h>

@implementation NSObject(WSThemeSimple)

-(WSThemeSimpleConfig *)wsThemeSimple
{
    WSThemeSimpleConfig *config = objc_getAssociatedObject(self, &WSThemeSimpleTheme_objectPropertyKey);
    if (!config) {
        @synchronized (self) {
            WSThemeSimpleConfig *tempConfig = objc_getAssociatedObject(self, &WSThemeSimpleTheme_objectPropertyKey);
            if(!tempConfig){
                tempConfig = [WSThemeSimpleConfig new];
                tempConfig.currentObject = self;
                objc_setAssociatedObject(self, &WSThemeSimpleTheme_objectPropertyKey, tempConfig , OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                NSLog(@"开始绑定 WSThemeConfig:%@",tempConfig);
            }
            config = tempConfig;
        }
    }
    return config;
}

@end












