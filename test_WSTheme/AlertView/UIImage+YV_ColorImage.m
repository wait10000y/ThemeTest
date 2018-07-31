//
//  UIImage+YV_ColorImage.m
//  yivian
//
//  Created by wsliang on 2018/4/25.
//  Copyright © 2018年 yivian. All rights reserved.
//

#import "UIImage+YV_ColorImage.h"

@implementation UIImage (YV_ColorImage)

    //绘图
-(UIImage*)imageChangeColor:(UIColor*)color
{
        //获取画布
    UIGraphicsBeginImageContextWithOptions(self.size, NO, 0.0f);
        //画笔沾取颜色
    [color setFill];

    CGRect bounds = CGRectMake(0, 0, self.size.width, self.size.height);
    UIRectFill(bounds);
        //绘制一次
    [self drawInRect:bounds blendMode:kCGBlendModeOverlay alpha:1.0f];
        //再绘制一次
    [self drawInRect:bounds blendMode:kCGBlendModeDestinationIn alpha:1.0f];
        //获取图片
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

@end
