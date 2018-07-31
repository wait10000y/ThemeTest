//
//  ThemeCreateEditToolAlertController.h
//  TestTheme_sakura
//
//  Created by wsliang on 2018/7/2.
//  Copyright © 2018年 wsliang. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^ThemeCreateEditToolAlertBlock)(BOOL isOK,id data);



@interface ThemeCreateEditToolAlertController : UIAlertController

+(ThemeCreateEditToolAlertController *)createColorAlertWithColor:(UIColor *)theColor complete:(ThemeCreateEditToolAlertBlock)completeBlock;
+(ThemeCreateEditToolAlertController *)createTextAlertWithText:(NSString *)theText complete:(ThemeCreateEditToolAlertBlock)completeBlock;
+(ThemeCreateEditToolAlertController *)createFontAlertWithFont:(UIFont *)theFont complete:(ThemeCreateEditToolAlertBlock)completeBlock;
+(ThemeCreateEditToolAlertController *)createEnumAlertWithDataDict:(NSDictionary *)theDict defaultValue:(id)value complete:(ThemeCreateEditToolAlertBlock)completeBlock;

-(void)setTipTitle:(NSString *)title;


@end
