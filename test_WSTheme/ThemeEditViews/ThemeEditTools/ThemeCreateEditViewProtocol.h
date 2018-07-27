//
//  ThemeCreateEditViewProtol.h
//  TestTheme_sakura
//
//  Created by 王士良 on 2018/7/5.
//  Copyright © 2018年 王士良. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol ThemeCreateEditViewProtocol

// 创建 view
+(instancetype)createView;

// 取值
-(id)getCurrentValue;

// 标题 label
@property (weak, nonatomic) IBOutlet UILabel *textTitle;

@end


