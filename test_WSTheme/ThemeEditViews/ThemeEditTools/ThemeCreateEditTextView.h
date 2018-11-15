//
//  ThemeCreateEditTextView.h
//  TestTheme_sakura
//
//  Created on 2018/7/4.
//  wsliang.
//

#import <UIKit/UIKit.h>
#import "ThemeCreateEditViewProtocol.h"

@interface ThemeCreateEditTextView : UIView<ThemeCreateEditViewProtocol>

@property (weak, nonatomic) IBOutlet UILabel *textTitle;
@property (weak, nonatomic) IBOutlet UITextView *textView;

+(instancetype)createView;
-(id)getCurrentValue;

@end
