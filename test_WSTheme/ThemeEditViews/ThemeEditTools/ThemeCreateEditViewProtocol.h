//
//  ThemeCreateEditViewProtol.h
//  Created on 2018/7/5.

#import <UIKit/UIKit.h>


@protocol ThemeCreateEditViewProtocol

// 创建 view
+(instancetype)createView;

// 取值
-(id)getCurrentValue;

// 标题 label
@property (weak, nonatomic) IBOutlet UILabel *textTitle;

@end


