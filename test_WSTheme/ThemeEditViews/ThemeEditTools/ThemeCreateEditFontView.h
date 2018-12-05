//
//  ThemeCreateEditFontView.h
//  Created on 2018/7/4.

#import <UIKit/UIKit.h>
#import "ThemeCreateEditViewProtocol.h"


@interface ThemeCreateEditFontView : UIView<ThemeCreateEditViewProtocol>

@property (weak, nonatomic) IBOutlet UILabel *textTitle;

@property(nonatomic) UIFont *currentFont;



+(instancetype)createView;
-(id)getCurrentValue;

@end
