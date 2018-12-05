//
//  ThemeCreateEditTextView.h
//  Created on 2018/7/4.

#import <UIKit/UIKit.h>
#import "ThemeCreateEditViewProtocol.h"

@interface ThemeCreateEditTextView : UIView<ThemeCreateEditViewProtocol>

@property (weak, nonatomic) IBOutlet UILabel *textTitle;
@property (weak, nonatomic) IBOutlet UITextView *textView;

+(instancetype)createView;
-(id)getCurrentValue;

@end
