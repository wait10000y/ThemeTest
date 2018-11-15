//
//  ThemeCreateEditTextView.m
//  TestTheme_sakura
//
//  Created on 2018/7/4.
//  wsliang.
//

#import "ThemeCreateEditTextView.h"

@implementation ThemeCreateEditTextView

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.textView.layer.cornerRadius = 5;
    self.textView.layer.masksToBounds = YES;
}

+(instancetype)createView
{
    return [[[NSBundle mainBundle] loadNibNamed:@"ThemeCreateEditTextView" owner:nil options:nil] firstObject];
}

-(id)getCurrentValue
{
    return _textView.text;
}

@end
