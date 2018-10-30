//
//  LSTImagePreviewView.m
//  ImagePreview
//
//  Created by Abhinav Singh on 06/04/16.
//  Copyright © 2016 Abhinav Singh. All rights reserved.
//

#import "LSTImagePreviewView.h"

@interface LSTImagePreviewView ()
{
    __weak UIView *backgroundView;
    __weak UIImageView *imageView;
    __weak UIScrollView *scrollView;
    __weak UIImageView *animatedFromImageView;
    __weak UIButton *mSaveBtn;
    __weak UIButton *mCloseBtn;
}

@end

@implementation LSTImagePreviewView

+(LSTImagePreviewView*)defaultPreviewView {
    
    return [[[self class] alloc] initWithFrame:CGRectZero];
}

- (instancetype)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        
        [self initialSetup];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    
    self = [super initWithCoder:coder];
    if (self) {
        
        [self initialSetup];
    }
    
    return self;
}

-(void)initialSetup {
    
    self.minimumZoomScale = 0.25;
    self.maximumZoomScale = 4;
    self.animationDuration = 0.25;

    self.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;

    self.removeOnPinch = NO;
    self.removeOnTap = YES;
}

-(CGFloat)maximumWidthAllowed
{
    return [UIScreen mainScreen].bounds.size.width - 10;
}
-(CGFloat)maximumHeightAllowed
{
    return [UIScreen mainScreen].bounds.size.height - 10;
}

-(void)showPreviewForImageView:(UIImageView *)imageV1 {
    
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    if (imageView || !window) {
        return;
    }
    
    self.frame = window.bounds;
    [window addSubview:self];
    
    UIImageView *from = imageV1;
    UIImage *imageForPreview = from.image;
    CGFloat corners = from.layer.cornerRadius;
    
    UIView *bView = [[UIView alloc] initWithFrame:self.bounds];
    bView.backgroundColor = [UIColor blackColor];
    bView.autoresizingMask = (UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth);
    [self addSubview:bView];
    
    backgroundView = bView;
    
    UIScrollView *tempScrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    tempScrollView.alwaysBounceVertical = YES;
    tempScrollView.alwaysBounceHorizontal = YES;
    
    tempScrollView.multipleTouchEnabled = YES;

//    tempScrollView.alwaysBounceHorizontal = YES;
    tempScrollView.contentSize = self.bounds.size;
    [tempScrollView setMaximumZoomScale:self.maximumZoomScale];
    tempScrollView.delegate = self;
    tempScrollView.autoresizingMask = (UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth);
    [self addSubview:tempScrollView];
    
    [tempScrollView setMinimumZoomScale:self.removeOnPinch?(self.minimumZoomScale-0.1):self.minimumZoomScale];

    UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(viewDoubleTapped:)];
    doubleTapGesture.numberOfTapsRequired =2;
    doubleTapGesture.numberOfTouchesRequired =1;
    [tempScrollView addGestureRecognizer:doubleTapGesture];

        //只有当doubleTapGesture识别失败的时候(即识别出这不是双击操作)，singleTapGesture才能开始识别
    if (self.removeOnTap) {
        UITapGestureRecognizer *tapToClose = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped:)];
        tapToClose.numberOfTapsRequired = 1;
        tapToClose.numberOfTouchesRequired = 1;
        [tempScrollView addGestureRecognizer:tapToClose];
        [tapToClose requireGestureRecognizerToFail:doubleTapGesture];
    }
    
    CGRect overMe = [tempScrollView convertRect:from.frame fromView:from.superview];
    
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:overMe];
    imgView.userInteractionEnabled = NO;
    imgView.image = imageForPreview;
    imgView.backgroundColor = from.backgroundColor;
    imgView.layer.cornerRadius = corners;
    imgView.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleTopMargin);
    imgView.contentMode = from.contentMode;
    imgView.layer.masksToBounds = YES;
    [tempScrollView addSubview:imgView];

    // add buttons
    [self addOperationButtons];

    imageView = imgView;
    scrollView = tempScrollView;
    

    CGFloat maxWidthAllowed = [self maximumWidthAllowed];
    CGFloat maxHeightAllowed = [self maximumHeightAllowed];
    
    CGFloat imageWidth = imageForPreview.size.width;
    CGFloat imageHeight = imageForPreview.size.height;

    // 自动最大全屏化.
    CGFloat whRatio = (imageWidth/imageHeight);
    imageWidth = maxWidthAllowed;
    imageHeight = (imageWidth/whRatio);
    if (imageHeight > maxHeightAllowed) {
        imageHeight = maxHeightAllowed;
        imageWidth = (whRatio*imageHeight);
    }

    CGRect newFrame = CGRectMake(0, 0, imageWidth, imageHeight);
    
    newFrame.origin.x = (tempScrollView.frame.size.width - newFrame.size.width)/2.0f;
    newFrame.origin.y = (tempScrollView.frame.size.height - newFrame.size.height)/2.0f;
    
    [tempScrollView setContentSize:newFrame.size];
    backgroundView.alpha = 0;
    
    CABasicAnimation *animation =  [CABasicAnimation animationWithKeyPath:@"cornerRadius"];
    animation.duration = self.animationDuration;
    animation.fromValue = [NSNumber numberWithInt:corners];
    animation.toValue = [NSNumber numberWithInt:5];
    [imageView.layer addAnimation:animation forKey:@"movingInAnimation"];
    
    [UIView animateWithDuration:self.animationDuration animations:^{
        imageView.layer.cornerRadius = 5;
        imageView.frame = newFrame;
        backgroundView.alpha = 0.8;
    }];
    
    animatedFromImageView = from;
}

-(void)addOperationButtons
{
        // add saveBtn
    UIButton *saveBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    saveBtn.frame = CGRectMake(self.bounds.size.width-66, self.bounds.size.height-46, 52, 32);
    saveBtn.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.5f].CGColor;
    saveBtn.layer.cornerRadius = 4;
    saveBtn.layer.masksToBounds = YES;
    saveBtn.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin;
    saveBtn.backgroundColor = [UIColor colorWithWhite:0.4 alpha:0.5f];
    saveBtn.titleLabel.font = [UIFont systemFontOfSize:15];
    [saveBtn setTitle:@"保 存" forState:UIControlStateNormal];
    [saveBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [saveBtn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:saveBtn];
    mSaveBtn = saveBtn;

    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    closeBtn.frame = CGRectMake(self.bounds.size.width-46, 20, 32, 32);
//    closeBtn.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.5f].CGColor;
    closeBtn.layer.cornerRadius = 4;
    closeBtn.layer.masksToBounds = YES;
    closeBtn.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleLeftMargin;
//    closeBtn.backgroundColor = [UIColor colorWithWhite:0.4 alpha:0.5f];
    closeBtn.titleLabel.font = [UIFont systemFontOfSize:18];
    [closeBtn setTitle:@"✖️" forState:UIControlStateNormal];
    [closeBtn setTitleColor:[UIColor cyanColor] forState:UIControlStateNormal];
    [closeBtn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:closeBtn];
    mCloseBtn = closeBtn;

}

-(void)hiddenOperationButtons:(BOOL)hidden
{
    mSaveBtn.hidden = hidden;
    mCloseBtn.hidden = hidden;
}

- (void)viewTapped:(UITapGestureRecognizer*)gesture {
        // 点中图片以外的区域 隐藏工具条;
    // 点击图片关闭预览.
    CGPoint overImageView = [gesture locationInView:imageView];
    bool hasTapImg = CGRectContainsPoint(imageView.bounds, overImageView);
    if (hasTapImg == NO) {
        [self hiddenOperationButtons:!mSaveBtn.hidden];
    }else{
        [self dismiss];
    }
}

- (void)viewDoubleTapped:(UITapGestureRecognizer*)gesture {

//            CGPoint overImageView = [gesture locationInView:imageView];
//            if (CGRectContainsPoint(imageView.frame, overImageView)) {
                // 执行 缩放. (全屏和默认尺寸之间缩放.)

                if (scrollView.zoomScale != 1) {
                    [scrollView setZoomScale:1 animated:YES];
                }else{

                    /**
                     // 自动最大全屏化.
                    CGFloat maxWidthAllowed = [self maximumWidthAllowed];
                    CGFloat maxHeightAllowed = [self maximumHeightAllowed];

                    UIImage *imageForPreview = imageView.image;
                    CGFloat imageWidth = imageForPreview.size.width;
                    CGFloat imageHeight = imageForPreview.size.height;

                    CGFloat whRatio = (imageWidth/imageHeight);
                    imageWidth = maxWidthAllowed;
                    imageHeight = (imageWidth/whRatio);
                    if (imageHeight < maxHeightAllowed) {
                        imageHeight = maxHeightAllowed;
                        imageWidth = (whRatio*imageHeight);
                    }

                    float scale = imageWidth/imageView.bounds.size.width;
                    [scrollView setZoomScale:scale animated:YES];
//                    NSLog(@"最大化 缩放比例:%f",scale);
                     */
                    
                    // 默认尺寸
                    float scale = (imageView.image.size.width*imageView.image.scale)/imageView.bounds.size.width;
                    [scrollView setZoomScale:scale animated:YES];

                }

//            }
}

// 保存相册
-(void)btnClick:(id)sender
{
    if (sender == mSaveBtn) {
        UIImageWriteToSavedPhotosAlbum(imageView.image, self, @selector(image:didFinishSavingWithError:contextInfo:), (__bridge void *)self);
    }else if (sender == mCloseBtn){
        [self dismiss];
    }
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
//    NSString *saveMsg = error?@"图片保存失败~!":@"图片保存成功!";
    if (self.savedCall) {
        self.savedCall(!error, error);
    }
}

-(void)dismiss {
    
    UIView *from = animatedFromImageView;
    if (from) {
        
        CGFloat corners = animatedFromImageView.layer.cornerRadius;
        
        imageView.layer.cornerRadius = corners;
        
        CABasicAnimation *animation =  [CABasicAnimation animationWithKeyPath:@"cornerRadius"];
        animation.duration = self.animationDuration;
        animation.fromValue = [NSNumber numberWithInt:5];
        animation.toValue = [NSNumber numberWithInt:corners];
        [imageView.layer addAnimation:animation forKey:@"movingOutAnimation"];
        
        [UIView animateWithDuration:self.animationDuration animations:^{
            
            backgroundView.alpha = 0;
            imageView.frame = [imageView.superview convertRect:from.frame fromView:from.superview];
        } completion:^(BOOL finished) {
            
            [self removeFromSuperview];
        }];
    }else {
        
        //If we don't have final state of animation don't animate.
        [self removeFromSuperview];
    }
}

#pragma mark UIScrollViewDelegate's

-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    
    return imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    
    CGRect rect = imageView.frame;
    rect.origin.x = MAX(0, ((scrollView.bounds.size.width - rect.size.width)/2));
    rect.origin.y = MAX(0, ((scrollView.bounds.size.height - rect.size.height)/2));
    imageView.frame = rect;
}

-(void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {
    
    if ( self.removeOnPinch && (scale < self.minimumZoomScale) ) {
        [self dismiss];
    }
}

@end
