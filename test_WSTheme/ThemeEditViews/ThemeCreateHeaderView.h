//
//  ThemeCreateHeaderView.h
//  TestTheme_sakura
//
//  Created on 2018/7/2.
//  wsliang.
//

#import <UIKit/UIKit.h>

typedef void(^ThemeCreateHeaderBlock)(UILabel *textTitle);
@interface ThemeCreateHeaderView : UIView

@property (weak, nonatomic) IBOutlet UILabel *textTitle;
@property(nonatomic) ThemeCreateHeaderBlock callBlack;

- (IBAction)actionSelect:(UIButton *)sender;

+(ThemeCreateHeaderView *)ceateHeaderView;

@end
