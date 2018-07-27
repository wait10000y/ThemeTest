//
//  TransDataUtils.h
//  test_WSTheme
//
//  Created by 王士良 on 2018/7/27.
//  Copyright © 2018年 王士良. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIFont.h>
#import <UIKit/UIColor.h>
#import <UIKit/UIImage.h>
#import <UIKit/NSAttributedString.h>


@interface TransDataUtils : NSObject


    // 字典类型的转换.type == dict时.
// string
+(UIColor *)parseColorWithValue:(NSString *)value;
// string,number
+(UIFont *)parseFontWithValue:(NSString *)value;
// string
+(UIImage *)parseImageWithValue:(NSString *)value;
// number ...
+(NSString *)parseNumberStringWithValue:(NSNumber *)value;
// nsdictionary
+(NSString *)parseDictStringWithValue:(NSDictionary *)value;


+(NSString *)parseColorStringWithValue:(UIColor *)value;
+(NSString *)parseFontStringWithValue:(UIFont *)value;
+(NSString *)parseImageStringWithValue:(UIImage *)value;
+(NSNumber *)parseNumberWithValue:(NSString *)value;
+(NSDictionary *)parseDictWithValue:(NSString *)value;

@end
