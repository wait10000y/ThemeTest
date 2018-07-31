//
//  WSThemeExtension.m
//  test_WSTheme
//
//  Created by wsliang on 2018/7/31.
//  Copyright © 2018年 wsliang. All rights reserved.
//

#import "WSThemeExtension.h"
#import <objc/runtime.h>
#import <objc/message.h>


#define isNull(_obj) (_obj==nil || _obj == (id)[NSNull null])

static NSString *WSThemeModelCacheArrayKey = @"WSThemeModelCacheArrayKey";


@implementation WSThemeExtension

@end


@implementation WSThemeModel(extension)

// 缓存 已经转换后的对象,下次重复读取时,从这里加载.
// key: identifier; value: 已经转换后的内容.

-(NSMutableDictionary *)cacheDictWithType:(WSThemeValueType)theType
{
    if (theType >= WSThemeValueTypeNone) { return nil; }

    NSArray *cachedArray = objc_getAssociatedObject(self, &WSThemeModelCacheArrayKey);
    if (!cachedArray) {
        @synchronized (self) {
            NSArray *tempArray = objc_getAssociatedObject(self, &WSThemeModelCacheArrayKey);
            if(!tempArray){
                NSMutableArray *tempArr = [[NSMutableArray alloc] initWithCapacity:WSThemeValueTypeNone];
                for (int it=0; it<WSThemeValueTypeNone; it++) {
                    [tempArr addObject:[NSMutableDictionary new]];
                }
                tempArray = tempArr;
                objc_setAssociatedObject(self, &WSThemeModelCacheArrayKey, tempArray , OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
            cachedArray = tempArray;
        }
    }
    return [cachedArray objectAtIndex:theType];
}

-(NSOperationQueue *)updateQueue
{
    NSOperationQueue *tempQueue = objc_getAssociatedObject(self, __FUNCTION__);
    if (!tempQueue) {
        tempQueue = [NSOperationQueue new];
        tempQueue.maxConcurrentOperationCount = 10;
        objc_setAssociatedObject(self, __FUNCTION__, tempQueue, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return tempQueue;
}


    // json对象定义文件地址.
//-(BOOL)loadJsonFile:(NSString *)filePath withName:(NSString *)theName
//{
//    _name = theName;
//    NSFileManager *fm = [NSFileManager defaultManager];
//    BOOL isDir = YES;
//    BOOL isFile = [fm fileExistsAtPath:filePath isDirectory:&isDir];
//    if (isFile && !isDir) {
//        NSData *jsonData = [NSData dataWithContentsOfFile:filePath];
//        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
//        if ([dict isKindOfClass:[NSDictionary class]] && dict.count>0) {
//            mThemeDict = dict;
//            [self createDefaultData];
//            return YES;
//        }
//    }
//    return NO;
//}

    // block 形式加载. 回调线程是 updateQueue 线程
-(void)getDataWithIdentifier:(NSString *)identifier backType:(WSThemeValueType)type complete:(void(^)(id value))complete
{
    if (isNull(identifier)){complete(nil);return;}

    if(complete){
        __weak typeof(self) weakSelf = self;
        [[self updateQueue] addOperationWithBlock:^{
            id value = [weakSelf getDataWithIdentifier:identifier backType:type];
            if (weakSelf) {
                complete(value);
            }
        }];
    }
}

    // 获取原生值, identifier 支持keyPath格式.
-(id)getDataWithIdentifier:(NSString *)identifier backType:(WSThemeValueType)type
{
    if (isNull(identifier)) {return nil;}
    SEL callSel = NULL;
    NSMutableDictionary *typeDict = [self cacheDictWithType:WSThemeValueTypeJson];
    if (type == WSThemeValueTypeOriginal) {
        return [self getValueWithIdentifier:identifier];
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
        return [self getValueWithIdentifier:identifier];
    }

    if (typeDict) {
        id backValue;
        @synchronized (typeDict) {
            backValue = [typeDict objectForKey:identifier];
        }
        if (backValue) {
            return isNull(backValue)?nil:backValue;
        }else{
            id tempValue = [self getValueWithIdentifier:identifier];
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


@implementation WSThemeConfig(extension)

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
        [weakSelf getValueFromMdodel:[WSTheme sharedObject].currentThemeModel identifier:identifier valueType:valueType valueBlock:valueBlock];
        return weakSelf;
    };
}


-(WSThemeConfigFixedTypeBlock)color
{
    __weak typeof(self) weakSelf = self;
    return ^(NSString *identifier,WSThemeConfigValueBlock valueBlock){

            // 保存,identifier对应的 configblock
        [weakSelf saveCustomBlock:valueBlock identifier:identifier valueType:WSThemeValueTypeColor];
            // 执行一次界面更新
        [weakSelf getValueFromMdodel:[WSTheme sharedObject].currentThemeModel identifier:identifier valueType:WSThemeValueTypeColor valueBlock:valueBlock];
        return weakSelf;
    };
}



// ================ 数据处理层 ================
-(void)saveCustomBlock:(WSThemeConfigValueBlock)valueBlock identifier:(NSString *)identifier valueType:(WSThemeValueType)valueType
{
    __weak typeof(self) weakSelf = self;
        // 保存,identifier对应的 configblock
    identifier = identifier?:(id)[NSNull null];
//    @synchronized (self) {
        [[weakSelf customBlockDict] setObject:@[identifier,@(valueType)] forKey:valueBlock];
//    }

}

    // 通过 iddentifier 查找模板里的value, 执行回调block
-(void)getValueFromMdodel:(WSThemeModel *)theModel identifier:(NSString *)identifier valueType:(WSThemeValueType)valueType valueBlock:(WSThemeConfigValueBlock)valueBlock
{
    __weak typeof(self) weakSelf = self;
    [theModel getDataWithIdentifier:identifier backType:valueType complete:^(id theValue) {
        if(theModel == [WSTheme sharedObject].currentThemeModel){ //异步请求:已经切换theme,不回调.
            dispatch_async(dispatch_get_main_queue(), ^{
                valueBlock(weakSelf.currentObject,theValue);
            });
        }
    }];
}

-(NSMutableDictionary *)customBlockDict
{
    NSMutableDictionary *customDict = objc_getAssociatedObject(self, __FUNCTION__);
    if (!customDict) {
        @synchronized (self) {
            NSMutableDictionary *tempDict = objc_getAssociatedObject(self, __FUNCTION__);
            if(!tempDict){
                tempDict = [NSMutableDictionary new];
                objc_setAssociatedObject(self, __FUNCTION__, tempDict , OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
            customDict = tempDict;
        }
    }
    return customDict;
}

// 覆盖主类的方法.更新theme时,该方法被调用.
-(void)callOthersCofingWithCurrentModel:(WSThemeModel *)theModel
{
    NSMutableDictionary *tempDict = [self customBlockDict];
    if (tempDict.count==0) { return; }

    NSArray *valueArr = tempDict.allKeys;
    for (WSThemeConfigValueBlock valueBlock in valueArr) {
        NSArray *idArr = [tempDict objectForKey:valueBlock];
        [self getValueFromMdodel:theModel identifier:[idArr firstObject] valueType:((NSNumber *)[idArr lastObject]).intValue valueBlock:valueBlock];
    }
}


@end






