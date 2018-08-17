//
//  SSImagePickerHelper.h
//  Sinofake
//
//  Created by zhucuirong on 15/6/18.
//  Copyright (c) 2015年 elong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void(^SSImagePickerHelperDidCaptureImageBlock)(UIImage *image, NSDictionary *info);

@interface SSImagePickerHelper : NSObject

/**
 *  图片是否可以编辑 default NO;
 */
@property (nonatomic, assign) BOOL allowsEditing;

/** eg:
 __weak __typeof(self)weakSelf = self;
 [self.imagePickerHelper showImagePickerControllerWithSourceType:UIImagePickerControllerSourceTypeCamera presentingViewController:self completionHandler:^(UIImage *image, NSDictionary *info) {
     //这里应当使用weakSelf，避免循环引用
 }];
 */
- (void)showImagePickerControllerWithSourceType:(UIImagePickerControllerSourceType)sourceType presentingViewController:(UIViewController *)presentingViewController completionHandler:(SSImagePickerHelperDidCaptureImageBlock)completionHandler;

@end
