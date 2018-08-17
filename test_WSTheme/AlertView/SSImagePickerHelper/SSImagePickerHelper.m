//
//  SSImagePickerHelper.m
//  Sinofake
//
//  Created by zhucuirong on 15/6/18.
//  Copyright (c) 2015年 elong. All rights reserved.
//

#import "SSImagePickerHelper.h"
#import "UIImage+FixOrientation.h"

@interface SSImagePickerHelper ()<UINavigationControllerDelegate,UIImagePickerControllerDelegate>
@property (nonatomic, copy) SSImagePickerHelperDidCaptureImageBlock didCaptureImageBlock;

@end

@implementation SSImagePickerHelper

- (void)showImagePickerControllerWithSourceType:(UIImagePickerControllerSourceType)sourceType presentingViewController:(UIViewController *)presentingViewController completionHandler:(SSImagePickerHelperDidCaptureImageBlock)completionHandler {
    if (![UIImagePickerController isSourceTypeAvailable:sourceType]) {
        if (completionHandler) {
            completionHandler(nil, nil);
            completionHandler = nil;
        }
        return;
    }
    self.didCaptureImageBlock = completionHandler;
    
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.delegate = self;
    imagePickerController.allowsEditing = self.allowsEditing;
    imagePickerController.sourceType = sourceType;
    //解注释这条语句，在拍照界面可以选择视频
    //if (sourceType == UIImagePickerControllerSourceTypeCamera) {
        //imagePickerController.mediaTypes =  [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
    //}
    [presentingViewController presentViewController:imagePickerController animated:YES completion:^{
        
    }];
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    //视频：public.movie   图片：public.image
    UIImage *image;
    if ([mediaType isEqualToString:@"public.image"]) {
        if (self.allowsEditing) {
            image = info[UIImagePickerControllerEditedImage];
        }
        else {
            image = info[UIImagePickerControllerOriginalImage];
        }
        image = [image fixOrientation];
    }
    if (self.didCaptureImageBlock) {
        self.didCaptureImageBlock(image, info);
        self.didCaptureImageBlock = nil;
    }
    [picker dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    if (self.didCaptureImageBlock) {
        self.didCaptureImageBlock(nil, nil);
        self.didCaptureImageBlock = nil;
    }
    [picker dismissViewControllerAnimated:YES completion:^{
        
    }];
}

@end
