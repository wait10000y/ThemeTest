//
//  UIView+YV_AlertView.m
//  yivian
//
//  Created by 王士良 on 2018/3/28.
//  Copyright © 2018年 yivian. All rights reserved.
//

#import "UIView+YV_AlertView.h"

#define isIpad (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

@implementation UIView (YV_AlertView)

+(UIAlertController *)showActionSheetWithTitle:(NSString *)title withText:(NSString*)text withActionNames:(NSArray<NSString *> *)names forViewController:(UIViewController *)presentVC completionHandler:(void(^)(BOOL isOK,NSString *title))completionHandler
{
    if (!presentVC) {
        return nil;
    }
    UIAlertController *alertC = [UIAlertController alertControllerWithTitle:title message:text preferredStyle:UIAlertControllerStyleActionSheet];

        // support iPad
    alertC.popoverPresentationController.sourceView = presentVC.view;
    CGRect tempRect = presentVC.view.bounds;
    alertC.popoverPresentationController.sourceRect = CGRectMake(CGRectGetWidth(tempRect)/2, CGRectGetHeight(tempRect)-1, 1, 1);


    for (int it=0; it<names.count; it++) {
        NSString *tempName = names[it];
        UIAlertAction *action2 = [UIAlertAction actionWithTitle:tempName style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            NSLog(@"UIAlertActionStyleDefault");
            if (completionHandler) {
                completionHandler(YES,action.title);
            }
        }];
        [alertC addAction:action2];
    }

    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"取  消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
        NSLog(@"UIAlertActionStyleCancel");
        if (completionHandler) {
            completionHandler(NO,nil);
        }
    }];
    [alertC addAction:actionCancel];

    [presentVC presentViewController:alertC animated:YES completion:nil];
    return alertC;
}



+ (UIAlertController *)showAlertWithTitle:(NSString*)title withText:(NSString*)text type:(int)type forViewController:(UIViewController *)presentVC completionHandler:(void(^)(BOOL isOK,id data))completionHandler
{
    if (!presentVC) {
        return nil;
    }
    UIAlertController *alertC = [UIAlertController alertControllerWithTitle:title message:text preferredStyle:UIAlertControllerStyleAlert];
        // support iPad
    alertC.popoverPresentationController.sourceView = presentVC.view;
    CGRect tempRect = presentVC.view.bounds;
    alertC.popoverPresentationController.sourceRect = CGRectMake(CGRectGetWidth(tempRect)/2, CGRectGetHeight(tempRect)/2, 1, 1);
    switch (type) {
        case 1: // 输入文字框,确定
        {
            UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"确 定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {

                NSString *text = [alertC.textFields firstObject].text;
                if (completionHandler) {
                    completionHandler(YES,text);
                }
            }];
            [alertC addAction:action1];

            [alertC addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                textField.placeholder = @"输入内容";
            }];

                //      [alertC addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                //        textField.secureTextEntry = YES;
                //        textField.placeholder = @"输入密码";
                //      }];
        } break;
        case 2: // 确认,取消 选择框
        {
                //      [alertC addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                //        textField.secureTextEntry = YES;
                //        textField.placeholder = @"输入密码";
                //      }];

            UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"确  认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                NSLog(@"UIAlertActionStyleDestructive");
                NSString *text = [alertC.textFields lastObject].text;
                if (completionHandler) {
                    completionHandler(YES,text);
                }
            }];
            [alertC addAction:action2];



            UIAlertAction *action3 = [UIAlertAction actionWithTitle:@"取  消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
                NSLog(@"UIAlertActionStyleCancel");
                NSString *text = [alertC.textFields lastObject].text;
                if (completionHandler) {
                    completionHandler(NO,text);
                }
            }];
            [alertC addAction:action3];

        } break;
        case 3: // 取消状态的 确定
        {

            UIAlertAction *action3 = [UIAlertAction actionWithTitle:@"确  定" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
                if (completionHandler) {
                    completionHandler(YES,nil);
                }
            }];
            [alertC addAction:action3];
        } break;
        case 4:// 确定
        {

            UIAlertAction *action3 = [UIAlertAction actionWithTitle:@"确  定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                if (completionHandler) {
                    completionHandler(YES,nil);
                }
            }];
            [alertC addAction:action3];
        } break;
        case 5: // 输入框的 确定,取消.
        {
            [alertC addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                textField.placeholder = @"输入内容";
            }];

                //      [alertC addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                //        textField.secureTextEntry = YES;
                //        textField.placeholder = @"输入密码";
                //      }];

            UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"确  认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                NSLog(@"UIAlertActionStyleDestructive");
                NSString *text = [alertC.textFields lastObject].text;
                if (completionHandler) {
                    completionHandler(YES,text);
                }
            }];
            [alertC addAction:action2];



            UIAlertAction *action3 = [UIAlertAction actionWithTitle:@"取  消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
                NSLog(@"UIAlertActionStyleCancel");
                NSString *text = [alertC.textFields lastObject].text;
                if (completionHandler) {
                    completionHandler(NO,text);
                }
            }];
            [alertC addAction:action3];

        } break;
        default:
            break;
    }





    [presentVC presentViewController:alertC animated:YES completion:^{
            //        NSLog(@"show ok");
    }];

    return alertC;
}

-(void)showLoadingTipsView:(BOOL)isShow
{
    UIActivityIndicatorView *activeView = [self viewWithTag:10001];
    if (isShow && !activeView) {
        activeView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:isIpad?UIActivityIndicatorViewStyleWhiteLarge:UIActivityIndicatorViewStyleWhite];
        activeView.userInteractionEnabled = NO;
        activeView.tag = 10001;
        activeView.color = [UIColor colorWithWhite:0.2f alpha:0.4f];
        activeView.hidesWhenStopped = YES;
        activeView.frame = self.bounds;
        activeView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        activeView.center = self.center;
        [self addSubview:activeView];
    }
        //    NSLog(@"==== actiview:%@ ======",activeView);
    activeView.hidden = !isShow;
    if (isShow) {
        [activeView startAnimating];
    }else{
        [activeView stopAnimating];
    }
}


@end
