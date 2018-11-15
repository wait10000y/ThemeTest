//
//  UIView+YV_AlertView.h
//  yivian
//
//  Created on 2018/3/28.
//  yivian.
//

#import <UIKit/UIKit.h>

@interface UIView (YV_AlertView)

-(void)showLoadingTipsView:(BOOL)isShow;
-(void)showModelLoadingTipsView:(BOOL)isShow;

    // 1: // 输入文字框,[确定]; type=2 消息 [确定,取消]; type=4 消息 [确定].;5输入框 [确定,取消] ;3: // 消息 [取消状态的 确定]
+ (UIAlertController *)showAlertWithTitle:(NSString*)title withText:(NSString*)text type:(int)type forViewController:(UIViewController *)presentVC completionHandler:(void(^)(BOOL isOK,id data))completionHandler;

// ipad 时,需要指定forView内容, 默认使用presentVC.view.
+(UIAlertController *)showActionSheetWithTitle:(NSString *)title withText:(NSString*)text withActionNames:(NSArray<NSString *> *)names forViewController:(UIViewController *)presentVC forView:(UIView *)showView completionHandler:(void(^)(BOOL isOK,NSString *title))completionHandler;

@end
