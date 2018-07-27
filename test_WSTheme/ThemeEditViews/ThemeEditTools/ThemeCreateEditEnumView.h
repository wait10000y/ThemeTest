//
//  ThemeCreateEditEnumView.h
//  test_WSTheme
//
//  Created by 王士良 on 2018/7/27.
//  Copyright © 2018年 王士良. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ThemeCreateEditViewProtocol.h"

@interface ThemeCreateEditEnumView : UIView<ThemeCreateEditViewProtocol>

@property (weak, nonatomic) IBOutlet UILabel *textTitle;

+(instancetype)createView;
-(id)getCurrentValue;

-(void)setEnumDict:(NSDictionary *)theDict defaultValue:(id)theValue;

@end
