//
//  LSTImagePreviewView.h
//  ImagePreview
//
//  Created by Abhinav Singh on 06/04/16.
//  Copyright © 2016 Abhinav Singh. All rights reserved.
//

/**
 使用方法:

 UIImageView *tempImgView = [[UIImageView alloc] initWithImage:qrImg];
 tempImgView.frame = showRect;

 1.
 [[LSTImagePreviewView defaultPreviewView] showPreviewForImageView:tempImgView];

 2.
 LSTImagePreviewView *preview = [[LSTImagePreviewView alloc] initWithFrame:CGRectZero];
 [preview showPreviewForImageView:tempImgView];



 */
@import UIKit;

typedef void(^LSTImagePreviewViewSavedBlock)(BOOL saveOK,NSError *err);

@interface LSTImagePreviewView : UIView <UIScrollViewDelegate>

@property(nonatomic, assign) CGFloat maximumZoomScale;
@property(nonatomic, assign) CGFloat minimumZoomScale;

@property(nonatomic, assign) CGFloat animationDuration;

@property(nonatomic, assign) BOOL removeOnTap;
@property(nonatomic, assign) BOOL removeOnPinch;

@property(nonatomic,copy) LSTImagePreviewViewSavedBlock savedCall; // 保存到系统后,回调block

+(LSTImagePreviewView*)defaultPreviewView;

-(void)showPreviewForImageView:(UIImageView *)imageV;

@end
