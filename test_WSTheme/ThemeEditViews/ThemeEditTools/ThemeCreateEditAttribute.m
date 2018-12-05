//
//  ThemeCreateEditAttribute.m
//  test_WSTheme
//
//  Created by wsliang on 2018/12/5.
//  Copyright © 2018年 wsliang. All rights reserved.
//

#import "ThemeCreateEditAttribute.h"
#import "ThemeEditManager.h"

#import "ThemeCreateEditToolAlertController.h"
#import "UIView+YV_AlertView.h"
#import "ThemeEditManager.h"

#define isIpad (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)


//@interface ThemeEditItemModel : NSObject
//@property(nonatomic) NSString *name;
//@property(nonatomic) NSString *type;
//@property(nonatomic) NSString *jsonKey;
//@property(nonatomic) NSString *valueKey;
//@property(nonatomic) NSString *value;
//
//+(ThemeEditItemModel*)createWithName:(NSString *)name type:(NSString *)type jKey:(NSString *)jsonKey vKey:(NSString *)valueKey v:(NSString *)value;
//
//@end
//
//@implementation ThemeEditItemModel
//
//+(ThemeEditItemModel*)createWithName:(NSString *)name type:(NSString *)type jKey:(NSString *)jsonKey vKey:(NSString *)valueKey v:(NSString *)value
//{
//    ThemeEditItemModel *item = [ThemeEditItemModel new];
//    item.name = name;
//    item.type = type;
//    item.jsonKey = jsonKey;
//    item.valueKey = valueKey;
//    item.value = value;
//    return item;
//}
//
//@end

@interface ThemeCreateEditAttribute ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic) UITableView *tableView;
@property (nonatomic) NSString *tableViewCellId;
@property (nonatomic) NSMutableArray *dataList; // 两级array,系统theme列表,自定义列表;

@end

@implementation ThemeCreateEditAttribute

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    self.title = @"编辑attribute";

    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:self action:nil];

    [self addNavEditTools];

    [self setTableViewData];

    [self createDefaultAttributeList];

    [self parseAttributeDictToItemValues];
    
}


-(void)addNavEditTools
{
    if (self.navigationItem) {
        UIBarButtonItem *editItem = [[UIBarButtonItem alloc] initWithTitle:@"保存" style:UIBarButtonItemStylePlain target:self action:@selector(barItemAction:)];
        editItem.tag = 1;
        self.navigationItem.rightBarButtonItem = editItem;
        UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(barItemAction:)];
        backItem.tag = 3;
        self.navigationItem.leftBarButtonItem = backItem;
    }
}

-(void)barItemAction:(UIBarButtonItem *)sender
{
    if(sender.tag == 1){ // 添加新主题

        [self saveEditedAttributeList];
        __weak typeof(self) weakSelf = self;
        NSString *tips = @"已保存,是否返回上一界面?";
        [self showAlertMessage:tips needConfirm:YES complete:^(BOOL isOK, id data) {
            if (isOK) {
                // 返回上一界面.
                [weakSelf backLastView];
            }
        }];
    }else if (sender.tag==3){ // 关闭当前界面
        [self backLastView];
    }
}

-(void)backLastView
{
    if (self.navigationController.viewControllers.count>1){
        [self.navigationController popViewControllerAnimated:YES];
    }else{ // presentingViewController
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }
}


-(void)setTableViewData
{
    self.tableViewCellId = @"YV_ThemeCerateEditAttributeCell";
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    _tableView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    if([_tableView respondsToSelector:@selector(setSeparatorInset:)]){
        _tableView.separatorInset = UIEdgeInsetsMake(0, 2, 0, 1);
    }
    if([_tableView respondsToSelector:@selector(setLayoutMargins:)]){
        _tableView.layoutMargins = UIEdgeInsetsZero;
    }
    _tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];

    [self.view addSubview:_tableView];
}

// 创建可以编辑的attribute属性列表
-(void)createDefaultAttributeList
{

    /**
     未支持的:
     UIKIT_EXTERN NSAttributedStringKey const NSParagraphStyleAttributeName NS_AVAILABLE(10_0, 6_0);      // NSParagraphStyle, default defaultParagraphStyle
     UIKIT_EXTERN NSAttributedStringKey const NSShadowAttributeName NS_AVAILABLE(10_0, 6_0);              // NSShadow, default nil: no shadow

     UIKIT_EXTERN NSAttributedStringKey const NSAttachmentAttributeName NS_AVAILABLE(10_0, 7_0);          // NSTextAttachment, default nil

     UIKIT_EXTERN NSAttributedStringKey const NSWritingDirectionAttributeName NS_AVAILABLE(10_6, 7_0);    // NSArray of NSNumbers representing the nested levels of writing direction overrides as defined by Unicode LRE, RLE, LRO, and RLO characters.  The control characters can be obtained by masking NSWritingDirection and NSWritingDirectionFormatType values.  LRE: NSWritingDirectionLeftToRight|NSWritingDirectionEmbedding, RLE: NSWritingDirectionRightToLeft|NSWritingDirectionEmbedding, LRO: NSWritingDirectionLeftToRight|NSWritingDirectionOverride, RLO: NSWritingDirectionRightToLeft|NSWritingDirectionOverride,

     */

    self.dataList = [@[
                       [ThemeEditItemModel createWithName:@"Font" type:ThemeEditItemTypeFont order:nil value:nil withKeypath:@"NSFontAttributeName"],
                       [ThemeEditItemModel createWithName:@"ForegroundColor" type:ThemeEditItemTypeColor order:nil value:nil withKeypath:@"NSForegroundColorAttributeName"],
                       [ThemeEditItemModel createWithName:@"BackgroundColor" type:ThemeEditItemTypeColor order:nil value:nil withKeypath:@"NSBackgroundColorAttributeName"],
                       [ThemeEditItemModel createWithName:@"Ligature" type:ThemeEditItemTypeNumber order:nil value:nil withKeypath:@"NSLigatureAttributeName"],
                       [ThemeEditItemModel createWithName:@"Kern" type:ThemeEditItemTypeNumber order:nil value:nil withKeypath:@"NSKernAttributeName"],
                       [ThemeEditItemModel createWithName:@"StrikethroughStyle" type:ThemeEditItemTypeNumber order:nil value:nil withKeypath:@"NSStrikethroughStyleAttributeName"],
                       [ThemeEditItemModel createWithName:@"UnderlineStyle" type:ThemeEditItemTypeNumber order:nil value:nil withKeypath:@"NSUnderlineStyleAttributeName"],
                       [ThemeEditItemModel createWithName:@"StrokeColor" type:ThemeEditItemTypeColor order:nil value:nil withKeypath:@"NSStrokeColorAttributeName"],
                       [ThemeEditItemModel createWithName:@"StrokeWidth" type:ThemeEditItemTypeNumber order:nil value:nil withKeypath:@"NSStrokeWidthAttributeName"],
                       [ThemeEditItemModel createWithName:@"TextEffect" type:ThemeEditItemTypeText order:nil value:nil withKeypath:@"NSTextEffectAttributeName"],
                       [ThemeEditItemModel createWithName:@"Link" type:ThemeEditItemTypeText order:nil value:nil withKeypath:@"NSLinkAttributeName"],
                       [ThemeEditItemModel createWithName:@"BaselineOffset" type:ThemeEditItemTypeNumber order:nil value:nil withKeypath:@"NSBaselineOffsetAttributeName"],
                       [ThemeEditItemModel createWithName:@"UnderlineColor" type:ThemeEditItemTypeColor order:nil value:nil withKeypath:@"NSUnderlineColorAttributeName"],
                       [ThemeEditItemModel createWithName:@"StrikethroughColor" type:ThemeEditItemTypeColor order:nil value:nil withKeypath:@"NSStrikethroughColorAttributeName"],
                       [ThemeEditItemModel createWithName:@"Obliqueness" type:ThemeEditItemTypeNumber order:nil value:nil withKeypath:@"NSObliquenessAttributeName"],
                       [ThemeEditItemModel createWithName:@"Expansion" type:ThemeEditItemTypeNumber order:nil value:nil withKeypath:@"NSExpansionAttributeName"],
                       [ThemeEditItemModel createWithName:@"VerticalGlyphForm" type:ThemeEditItemTypeNumber order:nil value:nil withKeypath:@"NSVerticalGlyphFormAttributeName"],

                       [ThemeEditItemModel createWithName:@"ParagraphStyle" type:ThemeEditItemTypeDict order:nil value:nil withKeypath:@"NSParagraphStyleAttributeName"],
                       [ThemeEditItemModel createWithName:@"Shadow" type:ThemeEditItemTypeDict order:nil value:nil withKeypath:@"NSShadowAttributeName"],
                       [ThemeEditItemModel createWithName:@"Attachment" type:ThemeEditItemTypeDict order:nil value:nil withKeypath:@"NSAttachmentAttributeName"],
                       [ThemeEditItemModel createWithName:@"WritingDirection" type:ThemeEditItemTypeDict order:nil value:nil withKeypath:@"NSWritingDirectionAttributeName"],

                       ] mutableCopy];


}

// 解析传递过来的dict,保存到datalist中.
-(void)parseAttributeDictToItemValues
{
    if (_dataList && _attributeDict.count>0) {
        NSMutableDictionary *dictCopy = [_attributeDict mutableCopy];
        NSArray *dictKeys = dictCopy.allKeys;

            // 保存已存在的字段value值.
        for (int it=0; it<self.dataList.count; it++) {
            ThemeEditItemModel *item = self.dataList[it];
            NSString *key = item.keypath;
            if ([dictKeys containsObject:key]) {
                NSString *value = [dictCopy objectForKey:key];
                [dictCopy removeObjectForKey:key];
                item.value = value;
            }
        }

        // 添加自定义的字段.
        __weak typeof(self) weakSelf = self;
        [dictCopy enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
            ThemeEditItemModel *item = [ThemeEditItemModel createWithName:key type:ThemeEditItemTypeNone order:nil value:obj withKeypath:key];
            [weakSelf.dataList addObject:item];
        }];

        [self.tableView reloadData];
    }
}

-(void)setAttributeDict:(NSDictionary *)attributeDict
{
    _attributeDict = attributeDict;
    [self performSelector:@selector(parseAttributeDictToItemValues)];
}

// 调用 block,保存已编辑的属性列表
-(NSDictionary *)saveEditedAttributeList
{
    if(!self.editCallBack){return nil;};

    NSMutableDictionary *saveDict = [[NSMutableDictionary alloc] initWithCapacity:self.dataList.count];
//    遍历,保存需要的值.
    for (int it=0; it<self.dataList.count; it++) {
        ThemeEditItemModel *item = self.dataList[it];
        NSString *value = item.value;
        if (value.length>0) {
            [saveDict setObject:value forKey:item.keypath];
        }
    }
    self.editCallBack(saveDict);
    return saveDict;
}

#pragma mark ======== delegate ==========

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataList.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return isIpad?72:56;
}


-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:self.tableViewCellId];
    if (!cell) {
        cell=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:self.tableViewCellId];
            //        cell.textLabel.textColor = [[YV_DataUtil sharedObject] getDefaultTheme].tableCellTitleColor;
            //        cell.detailTextLabel.textColor = [[YV_DataUtil sharedObject] getDefaultTheme].tableCellSubTitleColor;
            //        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.detailTextLabel.minimumScaleFactor = 0.25f;
        cell.detailTextLabel.numberOfLines = 2;
        cell.textLabel.minimumScaleFactor = 0.25f;
        cell.textLabel.numberOfLines = 2;
        if (isIpad) {
            cell.textLabel.font = [UIFont systemFontOfSize:18];
            cell.detailTextLabel.font = [UIFont systemFontOfSize:15];
        }

        cell.textLabel.adjustsFontSizeToFitWidth=YES;
        cell.detailTextLabel.adjustsFontSizeToFitWidth=YES;
        cell.separatorInset = UIEdgeInsetsMake(0, 2, 0, 1);
        if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
            cell.layoutMargins = UIEdgeInsetsZero;
        }
    }

    ThemeEditItemModel *item = self.dataList[indexPath.row];
    cell.textLabel.text = item.name;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    NSString *detailText;
    switch (item.mType) {
        case ThemeEditItemTypeNone:
        {
            detailText = @"未定义类型";
        } break;
        case ThemeEditItemTypeImage:
        {
            detailText = @"图片资源";
        } break;
        case ThemeEditItemTypeData:
        {
            detailText = @"Data数据";
        } break;
        case ThemeEditItemTypeDict:
        {
            detailText = @"字典内容";
        } break;
        case ThemeEditItemTypeNode:
        {
            detailText = @"节点信息";
        } break;
        default:
        {
            detailText = item.value?[item.value description]:@"没有内容";
        } break;
    }
    cell.detailTextLabel.text = detailText;
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
//    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    ThemeEditItemModel *itemModel = self.dataList[indexPath.row];
    if (itemModel.mType == ThemeEditItemTypeNode) { // 不可编辑的类型.
        // 显示提示
        return;
    }

    switch (itemModel.mType) {
        case ThemeEditItemTypeColor: // color
        {
            [self showColorEditSelectViewForItem:itemModel withIndexPath:indexPath];
        } break;
        case ThemeEditItemTypeFont: // font
        {
            [self showFontEditSelectViewForItem:itemModel withIndexPath:indexPath];
        } break;
        default:
        {
            [self showDefaultEditSelectViewForItem:itemModel withIndexPath:indexPath];
        } break;
    }

    
}


-(void)showColorEditSelectViewForItem:(ThemeEditItemModel *)itemModel withIndexPath:(NSIndexPath *)indexPath
{
    __weak typeof(self) weakSelf = self;
    UITableViewCell *tempCell = [_tableView cellForRowAtIndexPath:indexPath];
    [UIView showActionSheetWithTitle:@"操作提示: " withText:nil withActionNames:@[@"颜色编辑",@"原始值修改"] forViewController:self forView:tempCell completionHandler:^(BOOL isOK, NSString *title) {
        if(isOK){
            if ([@"颜色编辑" isEqualToString:title]) {
                NSString *editViewTitle = [NSString stringWithFormat:@"编辑%@:",itemModel.name?:@"颜色内容"];
                UIColor *cColor = [itemModel createColor];
                ThemeCreateEditToolAlertController *colorAlert = [ThemeCreateEditToolAlertController createColorAlertWithColor:cColor complete:^(BOOL isOK, NSString *data) {
                    if (isOK) {
                        itemModel.value = data;
                        [weakSelf.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                    }
                }];
                [colorAlert setTipTitle:editViewTitle];
                [weakSelf presentViewController:colorAlert animated:YES completion:nil];
            }else if ([@"原始值修改" isEqualToString:title]){
                [weakSelf showTextEditViewForUnKnowTypeValue:itemModel withTitle:@"#ARGB十六进制格式或数字:" complete:^(BOOL isChange, id value) {
                    if (isChange) {
                        itemModel.value = value;
                        [weakSelf.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                    }
                }];
            }
        }
    }];
}

-(void)showFontEditSelectViewForItem:(ThemeEditItemModel *)itemModel withIndexPath:(NSIndexPath *)indexPath
{
    __weak typeof(self) weakSelf = self;
    UITableViewCell *tempCell = [_tableView cellForRowAtIndexPath:indexPath];
    [UIView showActionSheetWithTitle:@"操作提示: " withText:nil withActionNames:@[@"字体编辑",@"原始值修改"] forViewController:self forView:tempCell completionHandler:^(BOOL isOK, NSString *title) {
        if(isOK){
            if ([@"字体编辑" isEqualToString:title]) {
                NSString *editViewTitle = [NSString stringWithFormat:@"编辑%@:",itemModel.name?:@"字体内容"];
                UIFont *tempFont = [itemModel createFont];
                ThemeCreateEditToolAlertController *fontAlert = [ThemeCreateEditToolAlertController createFontAlertWithFont:tempFont complete:^(BOOL isOK, UIFont *data) {
                    if (isOK) {
                        itemModel.value = [itemModel parseFont:data];
                        [weakSelf.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                    }
                }];
                [fontAlert setTipTitle:editViewTitle];
                [weakSelf presentViewController:fontAlert animated:YES completion:nil];
            }else if ([@"原始值修改" isEqualToString:title]){
                [weakSelf showTextEditViewForUnKnowTypeValue:itemModel withTitle:@"字号或(字体名:字号)格式:" complete:^(BOOL isChange, id value) {
                    if (isChange) {
                        itemModel.value = value;
                        [weakSelf.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                    }
                }];
            }
        }
    }];
}

-(void)showDefaultEditSelectViewForItem:(ThemeEditItemModel *)itemModel withIndexPath:(NSIndexPath *)indexPath
{
    __weak typeof(self) weakSelf = self;
    UITableViewCell *tempCell = [_tableView cellForRowAtIndexPath:indexPath];
    [UIView showActionSheetWithTitle:@"操作提示: " withText:nil withActionNames:@[@"原始值修改"] forViewController:self forView:tempCell completionHandler:^(BOOL isOK, NSString *title) {
        if(isOK){
            if ([@"原始值修改" isEqualToString:title]){
                [weakSelf showTextEditViewForUnKnowTypeValue:itemModel withTitle:nil complete:^(BOOL isChange, id value) {
                    if (isChange) {
                        itemModel.value = value;
                        [weakSelf.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                    }
                }];
            }
        }
    }];
}

    // 编辑未知类型的内容,原始值编辑.
-(void)showTextEditViewForUnKnowTypeValue:(ThemeEditItemModel *)itemModel withTitle:(NSString *)showTitle complete:(void(^)(BOOL isChange,id value))completeBlock
{
    NSString *editViewTitle = showTitle?:[NSString stringWithFormat:@"编辑%@:",itemModel.name?:@"内容"];
    NSString *cText;
    BOOL isJsonValue = NO;
    if ([itemModel.value isKindOfClass:[NSNull class]]) {
        cText = itemModel.value = @"";
    }else if ([itemModel.value isKindOfClass:[NSArray class]] || [itemModel.value isKindOfClass:[NSDictionary class]]) {
        isJsonValue = YES;
        cText = [itemModel createJsonText];
    }else{
        cText = [itemModel.value description];
    }
    ThemeCreateEditToolAlertController *textAlert = [ThemeCreateEditToolAlertController createTextAlertWithText:cText complete:^(BOOL isOK, NSString *data) {
        BOOL isChange = NO;
        id tempValue;
        if (isOK) {
            if (![cText isEqualToString:data]) { // 如果内容已修改
                isChange = YES;
                tempValue = isJsonValue?[itemModel parseJsonText:data]:data;
                    //                itemModel.value = tempValue;
            }
        }

        if (completeBlock) {
            completeBlock(isChange,tempValue);
        }
    }];
    [textAlert setTipTitle:editViewTitle];
    [self presentViewController:textAlert animated:YES completion:nil];
}















    //提醒框封装方法
-(UIAlertController *)showAlertMessage:(NSString *)message needConfirm:(BOOL)isNeed complete:(void(^)(BOOL isOK,id data))completionHandler
{
    return [UIView showAlertWithTitle:nil withText:message type:isNeed?2:4 forViewController:self completionHandler:completionHandler];
}

-(UIAlertController *)showAlertInputTextWithMsg:(NSString *)message complete:(void(^)(BOOL isOK,id data))completionHandler
{
    return [UIView showAlertWithTitle:nil withText:message type:5 forViewController:self completionHandler:completionHandler];
}

@end
