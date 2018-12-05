//
//  ThemeCreateEditAttribute.h
//  test_WSTheme
//
//  Created by wsliang on 2018/12/5.
//  Copyright © 2018年 wsliang. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^attributeEditResultCallBack)(NSDictionary *editedDict);

@interface ThemeCreateEditAttribute : UIViewController

@property(nonatomic) NSDictionary *attributeDict;
@property(nonatomic) attributeEditResultCallBack editCallBack;


@end

NS_ASSUME_NONNULL_END
