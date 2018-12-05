//
//  ThemeCreateViewController.m
//  Created on 2018/6/27.

#import "ThemeCreateViewController.h"

#import "ThemeEditManager.h"
#import "ThemeCreateHeaderView.h"

#import "ThemeCreateEditToolAlertController.h"
#import "ThemeCreateEditAttribute.h"
#import "UIView+YV_AlertView.h"
#import "SSImagePickerHelper.h"

#define isIpad (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

@interface ThemeCreateViewController ()<UINavigationControllerDelegate,UIGestureRecognizerDelegate,UITableViewDelegate,UITableViewDataSource>

@property (nonatomic) UITableView *tableView;

@property (nonatomic) NSString *tableViewCellId;

@property (nonatomic) NSArray *titleList; // section标题列表.
@property (nonatomic) NSArray *subTitleList; // 两级数据. key列表
@property(nonatomic) NSMutableArray *sectionStatusList; // section 开关状态列表. number 0:1

@property(nonatomic) NSString *themeName; // 新主题名称.
@property(nonatomic) NSDictionary *itemDataTypeDict; // 修改字段类型时,生成的枚举列表内容.

@property(nonatomic) ThemeEditManager *editManager;

@property(nonatomic) ThemeCreateHeaderView *headerView;

@property(nonatomic,weak) UIBarButtonItem *backBarButtonItem;

@property(nonatomic) BOOL hasLoadThemeData;

@property(nonatomic) SSImagePickerHelper *photoAlbum; // 相册控件

@end

@implementation ThemeCreateViewController
{


}
-(SSImagePickerHelper *)photoAlbum
{
    if (!_photoAlbum) {
        _photoAlbum = [[SSImagePickerHelper alloc] init];
        _photoAlbum.allowsEditing = YES;
    }
    return _photoAlbum;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"添加主题";
    self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    
    _hasLoadThemeData = NO;
    self.editManager = [ThemeEditManager new];

    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:self action:nil];

    [self addNavEditTools];

    [self setTableViewData];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)])
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;

    if (!_hasLoadThemeData) {
        [self loadThemeData];
        _hasLoadThemeData = YES;
    }
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)])
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
}

-(void)addNavEditTools
{
    if (self.navigationItem) {
        UIBarButtonItem *editItem1 = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(barItemAction:)];
        UIBarButtonItem *editItem2 = [[UIBarButtonItem alloc] initWithTitle:@"重置" style:UIBarButtonItemStylePlain target:self action:@selector(barItemAction:)];
        UIBarButtonItem *editItem3 = [[UIBarButtonItem alloc] initWithTitle:@"保存" style:UIBarButtonItemStylePlain target:self action:@selector(barItemAction:)];
        editItem1.tag = 1;editItem2.tag = 2;editItem3.tag = 3;
        self.navigationItem.rightBarButtonItem=editItem3;
        self.navigationItem.leftBarButtonItems = @[editItem1,editItem2];
        self.backBarButtonItem = editItem1;
    }
}

// 保存主题
-(void)barItemAction:(UIBarButtonItem *)sender
{
__weak typeof(self) weakSelf = self;
    switch (sender.tag) {
        case 1: // 清空数据,返回
        {
            [self showAlertMessage:@"是否退出新建主题?" needConfirm:YES complete:^(BOOL isOK, id data) {
                if(isOK){
                    [weakSelf.tableView setContentOffset:weakSelf.tableView.contentOffset animated:NO];
                    [weakSelf clearSavedData];
                    [weakSelf.navigationController popViewControllerAnimated:YES];
                }
            }];
        } break;
        case 2: // 清空数据
        {
            [self showAlertMessage:@"是否清空已编辑的内容?" needConfirm:YES complete:^(BOOL isOK, id data) {
                if(isOK){
                    [weakSelf.tableView setContentOffset:weakSelf.tableView.contentOffset animated:NO];
//                    [weakSelf clearSavedData];
                        // 重置数据.
                    [weakSelf loadThemeData];
                }
            }];
        } break;
        case 3: // 保存数据
        {
            [self showAlertMessage:@"是否保存主题?" needConfirm:YES complete:^(BOOL isOK, id data) {
                if(isOK){
                    [weakSelf.tableView setContentOffset:weakSelf.tableView.contentOffset animated:NO];
                    BOOL isSaveOK = [weakSelf saveThemeData];
                    if (isSaveOK) {
                        [weakSelf clearSavedData]; // 清除 缓存数据.
                        [weakSelf showAlertMessage:@"保存完成!" needConfirm:NO complete:^(BOOL isOK, id data) {
                            [weakSelf.navigationController popViewControllerAnimated:YES];
                        }];
                    }else{
                        [weakSelf showAlertMessage:@"保存失败!是否退出编辑?" needConfirm:YES complete:^(BOOL isOK, id data) {
                            if(isOK){
                                [weakSelf clearSavedData]; // 清除 缓存数据.
                                [weakSelf.navigationController popViewControllerAnimated:YES];
                            }
                        }];
                    }
                }
            }];
        } break;
        default:
            break;
    }

}

-(IBAction)actionTableViewSectionEvent:(UIControl *)sender
{
    BOOL showTag = [self.sectionStatusList[sender.tag] boolValue];
    [self.sectionStatusList replaceObjectAtIndex:sender.tag withObject:@(!showTag)];
    [_tableView reloadSections:[NSIndexSet indexSetWithIndex:sender.tag] withRowAnimation:UITableViewRowAnimationAutomatic];
}

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.headerView.frame = CGRectMake(0, 0, _tableView.frame.size.width, isIpad?140:114);
    _tableView.tableHeaderView = self.headerView;
}

-(void)setTableViewData
{
    self.tableViewCellId = @"YV_ThemeListViewControllerCell";
    self.headerView = [ThemeCreateHeaderView ceateHeaderView];

    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    _tableView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    _tableView.delegate = self;
    _tableView.dataSource = self;

    if([_tableView respondsToSelector:@selector(setSeparatorInset:)]){
        _tableView.separatorInset = UIEdgeInsetsMake(0, 2, 0, 1);
    }
    if([_tableView respondsToSelector:@selector(setLayoutMargins:)]){
        _tableView.layoutMargins = UIEdgeInsetsZero;
    }
    _tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];

    NSString *title = @"(复制)";
    NSRange tempRange = [self.selectedThemeName rangeOfString:title];
    if (tempRange.location != NSNotFound) {
        title = [self.selectedThemeName substringToIndex:tempRange.location+tempRange.length];
    }else{
        title = [NSString stringWithFormat:@"%@%@",self.selectedThemeName,title];
    }
    NSArray *allNames = [ThemeEditManager themeNameList];
    NSUInteger num = 0;
    NSString *newTitle = title;
    while ([allNames containsObject:newTitle] && num < 10001) { // 最多10000个主题.
        newTitle = [NSString stringWithFormat:@"%@%lu",title,(unsigned long)++num];
    }
    self.headerView.textTitle.text = newTitle;
    self.themeName = newTitle;
    self.title = newTitle;
    __weak typeof(self) weakSelf = self;
    self.headerView.callBlack = ^(UILabel *textTitle) {
        [weakSelf showCreateThemeNameView];
    };

    _tableView.tableHeaderView = self.headerView;

    [self.view addSubview:_tableView];
}

-(void)loadThemeData
{

    if (!self.selectedThemeName) {
        [self backLastViewAndShowMessage:@"未正确选择主题!"];
        return;
    }

        // 复制主题(selectedThemeName)到新主题缓存目录.
    NSString *newPath = [_editManager createThemeCopyFromTheme:self.selectedThemeName];
    if (!newPath) {
        [self backLastViewAndShowMessage:@"新主题,无法创建缓存!"];
        return;
    }

    NSArray *subItemList;
    NSArray *titleList;
    BOOL isOK = [_editManager parseThemeEditItemList:&subItemList titleList:&titleList];

    if (!isOK || (titleList.count != subItemList.count) || subItemList.count == 0) {
            // 显示 错误.
        [self backLastViewAndShowMessage:@"数据错误,无法创建新主题!"];
        return;
    }


    self.titleList = titleList;
    self.subTitleList = subItemList;
    self.sectionStatusList = [[NSMutableArray alloc] initWithCapacity:titleList.count];
    for (int it=0; it<titleList.count; it++) {
        [self.sectionStatusList addObject:@(YES)];
    }
    [_tableView reloadData];
}

-(void)backLastViewAndShowMessage:(NSString *)theMsg
{
    __weak typeof(self) weakSelf = self;
    [self showAlertMessage:theMsg needConfirm:NO complete:^(BOOL isOK, id data) {
        if (weakSelf.navigationController) {
            [weakSelf.navigationController popViewControllerAnimated:YES];
        }else{
            [weakSelf dismissViewControllerAnimated:YES completion:nil];
        }
    }];
}

// 删除 所有数据.
-(BOOL)clearSavedData
{
// 清除临时文件夹文件.
//    if (self.subTitleList.count>0) {
//        for (NSArray *subArr in self.subTitleList) {
//            for (ThemeEditItemModel *tempInfo in subArr) {
//                tempInfo.value = tempInfo.defalut;
//            }
//        }
//    }
    
    [ThemeEditManager newThemeMainPath:YES];
    
    return YES;
}

-(BOOL)saveThemeData
{
    if (_themeName.length==0) {
            // 提示 创建主题.
        [self showCreateThemeNameView];
        return NO;
    }

    return [_editManager saveNewTheme:self.subTitleList withName:_themeName hasPackage:YES];

}

// 弹出 创建主题的名称
-(void)showCreateThemeNameView
{
    __weak typeof(self) weakSelf = self;
    ThemeCreateEditToolAlertController *textAlert = [ThemeCreateEditToolAlertController createTextAlertWithText:self.headerView.textTitle.text complete:^(BOOL isOK, NSString *name) {
        if (isOK) {
            name = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if(name.length>0){
                    // 所有主题名称 default(TXSakuraTypeMainBundle),本地主题(TXSakuraTypeMainBundle),下载的主题(TXSakuraTypeSandbox)
                    //            NSMutableArray *dataSource = [[TXSakuraManager tx_getSakurasList] mutableCopy];
                
                    // 查看自定义主题 所有命名,是否有冲突.
                NSArray *remoteItems = [ThemeEditManager themeNameList];
                BOOL hasSameName =NO;
                for (NSString *tempName in remoteItems) {
                    if ([tempName isEqualToString:name]) {
                        hasSameName = YES;
                        break;
                    }
                }

                if (hasSameName) {
                    [weakSelf showAlertMessage:@"该名称主题已存在!" needConfirm:NO complete:^(BOOL isOK, id data) {
                        [weakSelf showCreateThemeNameView];
                    }];
                }else{
                    weakSelf.themeName = name;
                    weakSelf.title = name;
                    weakSelf.headerView.textTitle.text = name;
                }
            }else{
                [weakSelf showAlertMessage:@"名称不能为空,或者其他特殊字符!" needConfirm:NO complete:^(BOOL isOK, id data) {
//                    NSString *tempTitle = ((self.selectedThemeName.length>12)?[self.selectedThemeName substringToIndex:6]:self.selectedThemeName);
//                    NSString *title = [NSString stringWithFormat:@"%@%ld",tempTitle?:@"未命名",(long)[[NSDate date] timeIntervalSince1970]];
//                    weakSelf.headerView.textTitle.text = title;
                    [weakSelf showCreateThemeNameView];
                }];
            }
        }
    }];
[textAlert setTipTitle:@"输入新主题的名称"];
[self presentViewController:textAlert animated:YES completion:nil];

}


#pragma mark ======== delegate ==========
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.subTitleList.count;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSNumber *showTag = self.sectionStatusList[section];
    if (showTag.boolValue) {
        NSArray *tempArr = self.subTitleList[section];
        return tempArr.count;
    }
    return 0;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return isIpad?72:56;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSArray *tempArr = self.subTitleList[section];
    if (tempArr.count>0) {
        return (isIpad?58:48);
    }
    return 0;
}

-(UIView *)createTableViewSectionView:(NSString *)theTitle withSection:(NSInteger)section
{
    CGFloat viewHeight = (isIpad?58:48);
    CGFloat marginX = (isIpad?25:15);
    BOOL showTag = [self.sectionStatusList[section] boolValue];

    UIControl *headerView = [[UIControl alloc] initWithFrame:CGRectMake(0, 0, 320, viewHeight)];
    [headerView addTarget:self action:@selector(actionTableViewSectionEvent:) forControlEvents:UIControlEventTouchUpInside];
    headerView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    headerView.tag = section;

    UILabel *tempLabel = [[UILabel alloc] initWithFrame:CGRectMake(marginX, 0, 320-marginX, viewHeight)];
    tempLabel.font = [UIFont systemFontOfSize:isIpad?20:16];
    tempLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [headerView addSubview:tempLabel];
//        tempLabel.userInteractionEnabled = YES;
    tempLabel.adjustsFontSizeToFitWidth = YES;
    tempLabel.text = theTitle;
    tempLabel.textColor = [UIColor grayColor];

    UIImageView *tagView = [[UIImageView alloc] initWithFrame:CGRectMake(320-viewHeight, viewHeight/4, viewHeight/2, viewHeight/2)];
    tagView.contentMode = UIViewContentModeScaleAspectFit;
    tagView.image = [[UIImage imageNamed:showTag?@"down.png":@"minus.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [tagView setTintColor:[UIColor lightGrayColor]];

    tagView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [headerView addSubview:tagView];

    return headerView;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSArray *tempArr = self.subTitleList[section];
    if (tempArr.count>0) {
        ThemeEditItemModel *theTitle = self.titleList[section];
        return [self createTableViewSectionView:theTitle.name withSection:section];
    }
    return nil;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:self.tableViewCellId];
    if (!cell) {
        cell=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:self.tableViewCellId];
            //        cell.textLabel.textColor = [[YV_DataUtil sharedObject] getDefaultTheme].tableCellTitleColor;
            //        cell.detailTextLabel.textColor = [[YV_DataUtil sharedObject] getDefaultTheme].tableCellSubTitleColor;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.detailTextLabel.minimumScaleFactor = 0.25f;
        cell.detailTextLabel.numberOfLines = 2;
        cell.textLabel.minimumScaleFactor = 0.25f;
        cell.textLabel.numberOfLines = 2;
        if (isIpad) {
            cell.textLabel.font = [UIFont systemFontOfSize:21];
            cell.detailTextLabel.font = [UIFont systemFontOfSize:17];
        }else{
            cell.textLabel.font = [UIFont systemFontOfSize:16];
            cell.detailTextLabel.font = [UIFont systemFontOfSize:14];
        }
        cell.textLabel.adjustsFontSizeToFitWidth=YES;
        cell.detailTextLabel.adjustsFontSizeToFitWidth=YES;
        cell.separatorInset = UIEdgeInsetsMake(0, 2, 0, 1);
        if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
            cell.layoutMargins = UIEdgeInsetsZero;
        }
    }

    NSArray *itemModelArr = self.subTitleList[indexPath.section];
    ThemeEditItemModel *itemModel = itemModelArr[indexPath.row];
//    NSString *itemValue = itemModel.type?:(itemModel.value?[itemModel.value description]:itemModel.desc);
    UIImage *imageIcon; //TODO: 图标选取.
    NSString *detailText;
    switch (itemModel.mType) {
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
            detailText = itemModel.value?[itemModel.value description]:@"没有内容";
        } break;
    }

    cell.textLabel.text = itemModel.name;
    cell.detailTextLabel.text = detailText;
    cell.imageView.image = imageIcon;

    return cell;
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}
-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}
- (nullable NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @"修改编辑类型";
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSMutableArray *itemModelArr = self.subTitleList[indexPath.section];
        ThemeEditItemModel *itemModel = itemModelArr[indexPath.row];
        __weak typeof(self) weakSelf = self;
        [self showTypeChangeViewForUnKnowTypeValue:itemModel withTitle:nil complete:^(BOOL isChange, NSNumber *value) {
            if (isChange) {
                itemModel.mType = value.intValue;
                [weakSelf.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
        }];
    }
}

- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    __weak typeof(self) weakSelf = self;
    UITableViewRowAction *actionReview = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"查看原值" handler:^(UITableViewRowAction * action3, NSIndexPath * indexPath3) {
        NSMutableArray *itemModelArr = weakSelf.subTitleList[indexPath3.section];
        ThemeEditItemModel *itemModel = itemModelArr[indexPath3.row];

        NSString *cText;
        if ([itemModel.value isKindOfClass:[NSNull class]]) {
            cText = itemModel.value = @"";
        }else if ([itemModel.value isKindOfClass:[NSArray class]] || [itemModel.value isKindOfClass:[NSDictionary class]]) {
            cText = [itemModel createJsonText];
        }else{
            cText = [itemModel.value description];
        }
        [weakSelf showAlertMessage:cText needConfirm:NO complete:nil];
    }];

    UITableViewRowAction *actionChangeType = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:@"修改编辑类型" handler:^(UITableViewRowAction * action3, NSIndexPath * indexPath3) {
        NSMutableArray *itemModelArr = weakSelf.subTitleList[indexPath3.section];
        ThemeEditItemModel *itemModel = itemModelArr[indexPath3.row];
        [weakSelf showTypeChangeViewForUnKnowTypeValue:itemModel withTitle:nil complete:^(BOOL isChange, NSNumber *value) {
            if (isChange) {
                itemModel.mType = value.intValue;
                [weakSelf.tableView reloadRowsAtIndexPaths:@[indexPath3] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
        }];
    }];
    return @[actionReview,actionChangeType];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *itemModelArr = self.subTitleList[indexPath.section];
    ThemeEditItemModel *itemModel = itemModelArr[indexPath.row];
//    NSString *itemValue = itemModel.value;

    if (itemModel.mType == ThemeEditItemTypeNode) { // 不可编辑的类型.
        return;
    }

    // 判断枚举类型
    if(itemModel.enums.count>0){ // enums 格式要正确.
        [self showEnumEditSelectViewForItem:itemModel withIndexPath:indexPath];
        return;
    }

    /**
     type: none,node,color:1,text:2,font:3,image:4,data:5,number:6,dict:7
     value: nsstring,nsnumber,nsdictionary
     */
    switch (itemModel.mType) {
        case ThemeEditItemTypeNone:
        {
            [self showTypeChangeSelectViewForItem:itemModel withIndexPath:indexPath];
        } break;
        case ThemeEditItemTypeImage:
        {
            [self showImageEditSelectViewForItem:itemModel withIndexPath:indexPath];
        } break;
        case ThemeEditItemTypeColor: // color
        {
            [self showColorEditSelectViewForItem:itemModel withIndexPath:indexPath];
        } break;
        case ThemeEditItemTypeFont: // font
        {
            [self showFontEditSelectViewForItem:itemModel withIndexPath:indexPath];
        } break;
        case ThemeEditItemTypeDict: // dict
        {
            [self showAttributeEditSelectViewForItem:itemModel withIndexPath:indexPath];
        } break;
        default:
        {
            [self showDefaultEditSelectViewForItem:itemModel withIndexPath:indexPath];
        } break;
    }

}

//ThemeCreateEditAttribute
-(void)showAttributeEditSelectViewForItem:(ThemeEditItemModel *)itemModel withIndexPath:(NSIndexPath *)indexPath
{

    __weak typeof(self) weakSelf = self;
    UITableViewCell *tempCell = [_tableView cellForRowAtIndexPath:indexPath];
    [UIView showActionSheetWithTitle:@"操作提示: " withText:nil withActionNames:@[@"字典内容编辑",@"原始值修改"] forViewController:self forView:tempCell completionHandler:^(BOOL isOK, NSString *title) {
        if(isOK){
            if ([@"原始值修改" isEqualToString:title]){
                [weakSelf showTextEditViewForUnKnowTypeValue:itemModel withTitle:nil complete:^(BOOL isChange, id value) {
                    if (isChange) {
                        itemModel.value = value;
                        [weakSelf.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                    }
                }];
            }else if([@"字典内容编辑" isEqualToString:title]){
                NSDictionary *tempValue = itemModel.value;
                if (![tempValue isKindOfClass:[NSDictionary class]]) {
                    if ([tempValue isKindOfClass:[NSNull class]] || [tempValue description].length==0) {
                        tempValue = @{};
                    }else{
                        tempValue = nil;
                    }
                }
                if (tempValue) {
                    ThemeCreateEditAttribute *editVC = [ThemeCreateEditAttribute new];
                    editVC.attributeDict = tempValue;
                    editVC.editCallBack = ^(NSDictionary * _Nonnull editedDict) {
                        itemModel.value = [editedDict copy];
                    };
                    [weakSelf.navigationController pushViewController:editVC animated:YES];
                }else{
                    [weakSelf showAlertMessage:@"已存在非字典内容,无法使用字典内容编辑器!" needConfirm:NO complete:nil];
                }
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
// 修改属性的 编辑类型(本次编辑中有效)
-(void)showTypeChangeSelectViewForItem:(ThemeEditItemModel *)itemModel withIndexPath:(NSIndexPath *)indexPath
{
    __weak typeof(self) weakSelf = self;
    UITableViewCell *tempCell = [_tableView cellForRowAtIndexPath:indexPath];
    [UIView showActionSheetWithTitle:@"操作提示: " withText:nil withActionNames:@[@"修改编辑类型",@"原始值修改"] forViewController:self forView:tempCell completionHandler:^(BOOL isOK, NSString *title) {
        if(isOK){
            if ([@"修改编辑类型" isEqualToString:title]){
                [weakSelf showTypeChangeViewForUnKnowTypeValue:itemModel withTitle:nil complete:^(BOOL isChange, NSNumber *value) {
                    if (isChange) {
                        itemModel.mType = value.intValue;
                        [weakSelf.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                    }
                }];
            }else{
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

-(void)showEnumEditSelectViewForItem:(ThemeEditItemModel *)itemModel withIndexPath:(NSIndexPath *)indexPath
{
    __weak typeof(self) weakSelf = self;
    UITableViewCell *tempCell = [_tableView cellForRowAtIndexPath:indexPath];
    [UIView showActionSheetWithTitle:nil withText:nil withActionNames:@[@"列表选取",@"原始值修改"] forViewController:self forView:tempCell completionHandler:^(BOOL isOK, NSString *title) {
        if(isOK){
            if ([@"列表选取" isEqualToString:title]) {
                NSString *editViewTitle = [NSString stringWithFormat:@"编辑%@:",itemModel.name?:@"内容"];
                ThemeCreateEditToolAlertController *textAlert = [ThemeCreateEditToolAlertController createEnumAlertWithDataDict:itemModel.enums defaultValue:itemModel.value complete:^(BOOL isOK, NSString *data) {
                    if (isOK) {
                        itemModel.value = data;
                        [weakSelf.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                    }
                }];
                [textAlert setTipTitle:editViewTitle];
                [weakSelf presentViewController:textAlert animated:YES completion:nil];

            }else if ([@"原始值修改" isEqualToString:title]){
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

-(void)showImageEditSelectViewForItem:(ThemeEditItemModel *)itemModel withIndexPath:(NSIndexPath *)indexPath
{
    // 相册上传,直接输入,取消
    __weak typeof(self) weakSelf = self;
    UITableViewCell *tempCell = [_tableView cellForRowAtIndexPath:indexPath];
    [UIView showActionSheetWithTitle:nil withText:nil withActionNames:@[@"相机拍照",@"相册选取",@"修改地址"] forViewController:self forView:tempCell completionHandler:^(BOOL isOK, NSString *title) {
        if(isOK){
            if ([@"相机拍照" isEqualToString:title]) {
                [weakSelf.photoAlbum showImagePickerControllerWithSourceType:UIImagePickerControllerSourceTypeCamera presentingViewController:weakSelf completionHandler:^(UIImage *image, NSDictionary *info) {
//                    NSLog(@"image:%@ ,info:%@",image, info);
                    if (itemModel.attachs) {
                        CGSize tempSize = CGSizeFromString([itemModel.attachs description]);
                        if (!CGSizeEqualToSize(tempSize, CGSizeZero)) {
                            NSLog(@"==== 可以修改图片尺寸:%@ ====",itemModel.attachs);

                        }
                    }

                    NSString *tempFileName = itemModel.value?:[NSString stringWithFormat:@"%@.png",itemModel.keypath];
                    NSData *imgData = UIImagePNGRepresentation(image);
                    BOOL isOK = [weakSelf.editManager newThemeSaveResource:imgData forFileName:tempFileName];
                    if (isOK) {
                        itemModel.value = tempFileName;
                        itemModel.defalut = tempFileName; // 不可撤回.
                        [weakSelf.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                    }
                }];

            }else if([@"相册选取" isEqualToString:title]) {
                [weakSelf.photoAlbum showImagePickerControllerWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary presentingViewController:weakSelf completionHandler:^(UIImage *image, NSDictionary *info) {
//                    NSLog(@"image:%@ ,info:%@",image, info);

                    // 修改图片尺寸.根据配置项.
//                    if (itemModel.attachs) {
//                        CGSize tempSize = CGSizeFromString([itemModel.attachs description]);
//                        if (tempSize.width>0 && tempSize.height>0) {
//                                // TODO:test
//                            NSLog(@"==== 可以修改图片尺寸:%@ ====",itemModel.attachs);
//                        }
//                    }
                    NSString *tempFileName = itemModel.value?:[NSString stringWithFormat:@"%@.png",itemModel.keypath];
                    NSData *imgData = UIImagePNGRepresentation(image);
                    BOOL isOK = [weakSelf.editManager newThemeSaveResource:imgData forFileName:tempFileName];
                    if (isOK) {
                        itemModel.value = tempFileName;
                        itemModel.defalut = tempFileName; // 不可撤回.
                        [weakSelf.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                    }

                }];

            }else if ([@"修改地址" isEqualToString:title]){ // 会删除原资源文件.
                [weakSelf showTextEditViewForUnKnowTypeValue:itemModel withTitle:@"图片名称或主题资源名称:" complete:^(BOOL isChange, id value) {
                    if (isChange) {
                            // 如果目标文件存在,删除原资源;如果目标文件不存在,修改原资源名称.
                        NSString *cText = [itemModel.value description];
                        NSString *data = [value description];
                        NSData *imgData = [weakSelf.editManager newThemeGetResourceWithFileName:cText];
                        if(![weakSelf.editManager newThemeGetResourceWithFileName:data]){
                            if (imgData) {
                                [weakSelf.editManager newThemeSaveResource:imgData forFileName:data];
                            }
                        }
                        if (imgData) {
                            [weakSelf.editManager newThemeRemoveResourceWithFileName:cText];
                        }

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

-(void)showTypeChangeViewForUnKnowTypeValue:(ThemeEditItemModel *)itemModel withTitle:(NSString *)showTitle complete:(void(^)(BOOL isChange,id value))completeBlock
{
    __weak typeof(self) weakSelf = self;
    NSString *editViewTitle = showTitle?:[NSString stringWithFormat:@"修改数据编辑类型:"];
    if (!self.itemDataTypeDict) {
        NSArray *typeDescList = ThemeEditItemModelTypeDescList;
        NSMutableDictionary *tempDict = [[NSMutableDictionary alloc] initWithCapacity:typeDescList.count];
        for (int it=0; it<typeDescList.count; it++) {
            [tempDict setObject:@(it) forKey:typeDescList[it]];
        }
        self.itemDataTypeDict = [NSDictionary dictionaryWithDictionary:tempDict];
    }
    NSNumber *tempType = @(itemModel.mType);
    ThemeCreateEditToolAlertController *textAlert = [ThemeCreateEditToolAlertController createEnumAlertWithDataDict:self.itemDataTypeDict defaultValue:tempType complete:^(BOOL isOK, NSNumber *data) {
        BOOL isChange = NO;
        id tempValue = data;
        if (isOK) {
            if (![data isEqual:tempType]) { // 如果内容已修改
                isChange = YES;
            }
        }
        if (completeBlock) {
            completeBlock(isChange,tempValue);
        }
    }];
    [textAlert setTipTitle:editViewTitle];
    [weakSelf presentViewController:textAlert animated:YES completion:nil];
}

// utils
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
