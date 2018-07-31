//
//  UIView+YV_AlertView.h
//  yivian
//
//  Created by wsliang on 2018/3/28.
//  Copyright © 2018年 yivian. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (YV_AlertView)

-(void)showLoadingTipsView:(BOOL)isShow;

    // 1: // 输入文字框,[确定]; type=2 消息 [确定,取消]; type=4 消息 [确定].;5输入框 [确定,取消] ;3: // 消息 [取消状态的 确定]
-(UIAlertController *)showAlertWithTitle:(NSString*)title withText:(NSString*)text type:(int)type forViewController:(UIViewController *)presentVC completionHandler:(void(^)(BOOL isOK,id data))completionHandler;


@end
