//
//  ThemeCreateEditEnumView.h
//  test_WSTheme

//  Created on 2018/7/27.

#import <UIKit/UIKit.h>
#import "ThemeCreateEditViewProtocol.h"

@interface ThemeCreateEditEnumView : UIView<ThemeCreateEditViewProtocol>

@property (weak, nonatomic) IBOutlet UILabel *textTitle;

+(instancetype)createView;
-(id)getCurrentValue;

-(void)setEnumDict:(NSDictionary *)theDict defaultValue:(id)theValue;

@end
