//
//  ThemeCreateEditFontView.m
//  TestTheme_sakura
//
//  Created on 2018/7/4.
//  wsliang.
//

#import "ThemeCreateEditFontView.h"

@interface ThemeCreateEditFontView()<UIPickerViewDelegate,UIPickerViewDataSource>

@property (weak, nonatomic) IBOutlet UIPickerView *pickerView;
@property (weak, nonatomic) IBOutlet UILabel *showText;
@property (weak, nonatomic) IBOutlet UIButton *systemFontBtn; // tag==0:使用自定义字体;是否使用系统字体.

@property(nonatomic) NSArray *fontNameList; // 第一级 名称列表
@property(nonatomic) NSMutableArray *fontFamilyList; // 次级列表列表
@property(nonatomic) NSArray *fontFamilyNameList; // 次级名称列表.
@property(nonatomic) NSMutableArray *fontSizeList;

@property(nonatomic) NSString *fontNameFamily;
@property(nonatomic) NSString *fontName;
@property(nonatomic) NSNumber *fontSize;

@end

@implementation ThemeCreateEditFontView

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self createDefaultData];
}

+(instancetype)createView
{
    return [[[NSBundle mainBundle] loadNibNamed:@"ThemeCreateEditFontView" owner:nil options:nil] firstObject];
}

-(void)setCurrentFont:(UIFont *)currentFont
{
    _currentFont = currentFont;
    if (currentFont) {
        _fontNameFamily = currentFont.familyName;
        self.fontName = currentFont.fontName;
        self.fontSize = @(currentFont.pointSize);
        self.showText.font = currentFont;

        [self updateForDefaultFont];
    }

}


- (IBAction)actionTypeChanged:(UIButton *)sender {
    BOOL isCustom = (sender.tag ==0);
    NSString *title = isCustom?@"系统字体":@"自定义字体";
    [sender setTitle:title forState:UIControlStateNormal];
    sender.tag = isCustom?1:0;

    if(isCustom){
        _currentFont = [UIFont systemFontOfSize:_fontSize.floatValue];
    }else{
        _currentFont = [UIFont fontWithName:_fontName size:[_fontSize floatValue]];
    }
    self.showText.font = _currentFont;
}

-(id)getCurrentValue
{
    return _currentFont;
}

-(void)createDefaultData
{
    self.textTitle.text = @"字体选择:";
    int sizeMax = 72;
    _fontSizeList = [[NSMutableArray alloc] initWithCapacity:sizeMax];
    for (int it=0; it<sizeMax; it++) {
        [_fontSizeList addObject:@(it+1)];
    }

    NSArray *fontFNames = [UIFont familyNames];
    _fontNameList = [fontFNames copy];
    _fontFamilyNameList = [UIFont fontNamesForFamilyName:[_fontNameList firstObject]];
    _fontFamilyList = [[NSMutableArray alloc] initWithCapacity:_fontNameList.count];
    for (int it=0; it<_fontNameList.count; it++) {
        NSString *familyName = [_fontNameList objectAtIndex:it];
        NSArray *fNList = [UIFont fontNamesForFamilyName:familyName];
        if (fNList.count==0) {
            fNList = @[familyName];
        }
        [_fontFamilyList addObject:fNList];

    }
    [self.pickerView reloadAllComponents];

}

-(void)updateForDefaultFont
{
    int select1=0,select2=0,select3=0;
    BOOL hasNotFind = YES;

        // 检查当前字体位置
    for (int it=0; it<_fontNameList.count; it++) {
        NSString *familyName = [_fontNameList objectAtIndex:it];
        if (hasNotFind && _fontNameFamily && [_fontNameFamily isEqualToString:familyName]) {
            NSArray *fNList = [_fontFamilyList objectAtIndex:it];
            for (int ij=0; ij<fNList.count; ij++) {
                NSString *tempName = fNList[ij];
                if ([_fontName isEqualToString:tempName]) {
                    select1 = it;
                    select2 = ij;
                    _fontFamilyNameList = fNList;
                    hasNotFind = NO;
                    break;
                }
            }
        }
    }
    
    select3 = self.fontSize.intValue;

    if (!hasNotFind) {
        [self.pickerView reloadAllComponents];
    }
    
        // 设定默认值
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(300 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
        if (select3 > 0) {
            @try{
                [self.pickerView selectRow:(select3-1) inComponent:2 animated:NO];
            }@catch(NSException *excp){}
        }

        if(!hasNotFind){
            @try{
                [self.pickerView selectRow:select1 inComponent:0 animated:NO];
                [self.pickerView selectRow:select2 inComponent:1 animated:NO];
            }@catch(NSException *excp){}
        }
    });

}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 3;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if (component==0) {
        return self.fontNameList.count;
    }else if (component==1){
        return _fontFamilyNameList.count;
    }else if (component==2){
        return _fontSizeList.count;
    }
    return 0;
}


- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
    float allWidth = pickerView.frame.size.width;
    if (component==0) {
        return 0.4*allWidth;
    }else if (component ==1){
        return 0.4*allWidth;
    }else if (component ==2){
        return 0.2*allWidth;
    }
    return 0;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
    return 50;
}

//- (nullable NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
//{
//    if (component==0) {
//        return _fontNameList[row];
//    }else if (component ==1){
//        return _fontFamilyNameList[row];
//    }else if (component ==2){
//        return [_fontSizeList[row] description];
//    }
//    return nil;
//}
/**
 //字体大小
 [attributedStr addAttribute:NSFontAttributeName
 value:font
 range:range];


 */
//- (nullable NSAttributedString *)pickerView:(UIPickerView *)pickerView attributedTitleForRow:(NSInteger)row forComponent:(NSInteger)component
//{
//}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(nullable UIView *)view
{
    UILabel *showLabel = [[UILabel alloc] init];
    showLabel.minimumScaleFactor = 0.125f;
    showLabel.font = [UIFont systemFontOfSize:20];
    showLabel.numberOfLines = 4;
    showLabel.adjustsFontSizeToFitWidth = YES;
//    if (_currentFont) {
//        showLabel.font = _currentFont;
//    }
    NSString *tempStr;
    if (component==0) {
        tempStr = _fontNameList[row];
    }else if (component ==1){
        tempStr = _fontFamilyNameList[row];
    }else if (component ==2){
        tempStr = [_fontSizeList[row] description];
    }
    showLabel.text = tempStr;
    return showLabel;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if (component==0) {
        _fontFamilyNameList = _fontFamilyList[row];
        [pickerView reloadComponent:1];
    }
//    else if (component ==1){
//        _fontName = _fontFamilyNameList[row];
//    }else if (component ==2){
//        _fontSize = _fontSizeList[row];
//    }

    NSInteger cRow1 = [pickerView selectedRowInComponent:1];
    NSInteger cRow2 = [pickerView selectedRowInComponent:2];
    _fontSize = _fontSizeList[cRow2];
    _fontName = _fontFamilyNameList[cRow1];
    if (_fontName && _fontSize) {
        if(_systemFontBtn.tag == 0){
            _currentFont = [UIFont fontWithName:_fontName size:[_fontSize floatValue]];
        }else{
            _currentFont = [UIFont systemFontOfSize:_fontSize.floatValue];
        }
        self.showText.font = _currentFont;
    }
}




@end
