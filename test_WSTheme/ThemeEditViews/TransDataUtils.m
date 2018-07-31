//
//  TransDataUtils.m
//  test_WSTheme
//
//  Created by wsliang on 2018/7/27.
//  Copyright © 2018年 wsliang. All rights reserved.
//

#import "TransDataUtils.h"

@implementation TransDataUtils






    // ======== utils ============

+(UIColor *)parseColorWithValue:(NSString *)value
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

// string,number
+(UIFont *)parseFontWithValue:(NSString *)fontSize
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

+(UIImage *)parseImageWithValue:(NSString *)imgName
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

// 定义模式 转系统模式.
+(NSDictionary *)parseAttributesWithValue:(NSDictionary *)value
{
    if ([value isKindOfClass:[NSDictionary class]] && value.count>0) {

        NSMutableDictionary *attrs = [[NSMutableDictionary alloc] initWithCapacity:value.count];
            // 判断支持转换的属性.

            // 是否有font属性
        NSString *tempAttrName = @"NSFontAttributeName";
        NSString *fontName = [value objectForKey:tempAttrName];
        if (fontName) {
            UIFont *font = [self parseFontWithValue:fontName];
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
                UIColor *tempColor = [self parseColorWithValue:colorHex];
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


// 转成保存形式.

+(NSString *)parseNumberStringWithValue:(id)value
{
    return [value description];
}

// 字典类型的转换.
+(NSString *)parseDictStringWithValue:(NSDictionary *)theObject
{
    if (theObject) {
        if ([theObject isKindOfClass:[NSArray class]] || [theObject isKindOfClass:[NSDictionary class]]) {
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:theObject options:0 error:nil];
            if (jsonData) {
                return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            }
        }
    }
    return [theObject description];
}


// argb
+(NSString *)parseColorStringWithValue:(UIColor *)theColor
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

+(NSString *)parseFontStringWithValue:(UIFont *)value
{
    return [NSString stringWithFormat:@"%@:%.0f",value.fontName,value.pointSize];
}

// 写到指定目录,返回path?
+(NSString *)parseImageStringWithValue:(UIImage *)value
{
    return nil;
}

+(NSNumber *)parseNumberWithValue:(NSString *)value
{

    return @([value doubleValue]);
}

// 字典类型的转换.
+(NSDictionary *)parseDictWithValue:(NSString *)value
{
    if (value) {
        return [NSJSONSerialization JSONObjectWithData:[value dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    }
    return nil;
}


@end
