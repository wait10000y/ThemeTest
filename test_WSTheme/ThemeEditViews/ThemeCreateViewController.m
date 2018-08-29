//
//  ThemeCreateViewController.m
//  TestTheme_sakura
//
//  Created by wsliang on 2018/6/27.
//  Copyright © 2018年 wsliang. All rights reserved.
//

#import "ThemeCreateViewController.h"

#import "ThemeEditManager.h"
#import "ThemeCreateHeaderView.h"

#import "ThemeCreateEditToolAlertController.h"
#import "UIView+YV_AlertView.h"
#import "SSImagePickerHelper.h"

#define isIpad (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

@interface ThemeCreateViewController ()<UINavigationControllerDelegate,UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic) NSString *tableViewCellId;

@property (nonatomic) NSArray *titleList; // section标题列表.
@property (nonatomic) NSArray *subTitleList; // 两级数据. key列表

@property(nonatomic) NSString *themeName; // 新主题名称.


@property(nonatomic) ThemeEditManager *editManager;

@property(nonatomic) ThemeCreateHeaderView *headerView;

@property(nonatomic,weak) UIBarButtonItem *backBarButtonItem;

@property(nonatomic) BOOL hasLoadThemeData;

@property(nonatomic) SSImagePickerHelper *photoAlbum; // 相册控件

@end

@implementation ThemeCreateViewController

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

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.headerView.frame = CGRectMake(0, 0, self.tableView.frame.size.width, 92);
    self.tableView.tableHeaderView = self.headerView;
}

-(void)setTableViewData
{
    self.tableViewCellId = @"YV_ThemeListViewControllerCell";
    self.headerView = [ThemeCreateHeaderView ceateHeaderView];
    NSString *tempTitle = ((self.selectedThemeName.length>12)?[self.selectedThemeName substringToIndex:6]:self.selectedThemeName);
    NSString *title = [NSString stringWithFormat:@"%@%ld",tempTitle?:@"未命名",(long)[[NSDate date] timeIntervalSince1970]];
    self.headerView.textTitle.text = title;
    __weak typeof(self) weakSelf = self;
    self.headerView.callBlack = ^(UILabel *textTitle) {
        [weakSelf showCreateThemeNameView];
    };

    self.tableView.tableHeaderView = self.headerView;
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
    [self.tableView reloadData];
}

-(void)backLastViewAndShowMessage:(NSString *)theMsg
{
    [self showAlertMessage:theMsg needConfirm:NO complete:^(BOOL isOK, id data) {
        if (self.navigationController) {
            [self.navigationController popViewControllerAnimated:YES];
        }else{
            [self dismissViewControllerAnimated:YES completion:nil];
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
                    weakSelf.headerView.textTitle.text = name;
                }
            }else{
                [weakSelf showAlertMessage:@"名称不能为空,或者其他特殊字符!" needConfirm:NO complete:^(BOOL isOK, id data) {

                    NSString *tempTitle = ((self.selectedThemeName.length>12)?[self.selectedThemeName substringToIndex:6]:self.selectedThemeName);
                    NSString *title = [NSString stringWithFormat:@"%@%ld",tempTitle?:@"未命名",(long)[[NSDate date] timeIntervalSince1970]];
                    weakSelf.headerView.textTitle.text = title;
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
    NSArray *tempArr = self.subTitleList[section];
    return tempArr.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return isIpad?76:54;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSArray *tempArr = self.subTitleList[section];
    if (tempArr.count>0) {
        return (isIpad?54:44);
    }
    return 0;
}

-(UIView *)createTableViewSectionView:(NSString *)theTitle
{
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 38)];
    headerView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    UILabel *tempLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, 290, 38)];
    tempLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [headerView addSubview:tempLabel];
//        tempLabel.userInteractionEnabled = YES;
    tempLabel.adjustsFontSizeToFitWidth = YES;
    tempLabel.text = theTitle;
    tempLabel.textColor = [UIColor grayColor];

    return headerView;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSArray *tempArr = self.subTitleList[section];
    if (tempArr.count>0) {
        ThemeEditItemModel *theTitle = self.titleList[section];
        return [self createTableViewSectionView:theTitle.name];
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
        cell.detailTextLabel.numberOfLines = 0;
        if (isIpad) {
            cell.textLabel.font = [UIFont systemFontOfSize:18];
            cell.detailTextLabel.font = [UIFont systemFontOfSize:15];
        }
    }

    NSArray *itemModelArr = self.subTitleList[indexPath.section];
    ThemeEditItemModel *itemModel = itemModelArr[indexPath.row];
//    NSString *itemValue = itemModel.type?:(itemModel.value?[itemModel.value description]:itemModel.desc);
    UIImage *imageIcon; //TODO: 图标选取.
    NSString *detailText;
    switch (itemModel.mType) {
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
            detailText = [itemModel.value description]?:@"没有内容";
        } break;
    }

    cell.textLabel.text = itemModel.name;
    cell.detailTextLabel.text = detailText;
    cell.imageView.image = imageIcon;

    return cell;
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
        [self showEnumSelectViewForItem:itemModel withIndexPath:indexPath];
        return;
    }

    /**
     type: none,node,color:1,text:2,font:3,image:4,data:5,number:6,dict:7
     value: nsstring,nsnumber,nsdictionary
     */
    switch (itemModel.mType) {
        case ThemeEditItemTypeImage:
        {
            [self showImageSelectViewForItem:itemModel withIndexPath:indexPath];
        } break;
        case ThemeEditItemTypeColor: // color
        {
            [self showColorSelectViewForItem:itemModel withIndexPath:indexPath];
        } break;
        case ThemeEditItemTypeFont: // font
        {
            [self showFontSelectViewForItem:itemModel withIndexPath:indexPath];
        } break;
        default:
        {
            [self showDefaultSelectViewForItem:itemModel withIndexPath:indexPath];
        } break;
    }

}

-(void)showDefaultSelectViewForItem:(ThemeEditItemModel *)itemModel withIndexPath:(NSIndexPath *)indexPath
{
    __weak typeof(self) weakSelf = self;
    [UIView showActionSheetWithTitle:nil withText:nil withActionNames:@[@"原始值修改"] forViewController:self completionHandler:^(BOOL isOK, NSString *title) {
        if(isOK){
            if ([@"原始值修改" isEqualToString:title]){
                [self showTextEditViewForUnKnowTypeValue:itemModel complete:^(BOOL isChange, id value) {
                    if (isChange) {
                        itemModel.value = value;
                        [weakSelf.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                    }
                }];
            }
        }
    }];
}

-(void)showEnumSelectViewForItem:(ThemeEditItemModel *)itemModel withIndexPath:(NSIndexPath *)indexPath
{
    __weak typeof(self) weakSelf = self;
    [UIView showActionSheetWithTitle:nil withText:nil withActionNames:@[@"列表选取",@"原始值修改"] forViewController:self completionHandler:^(BOOL isOK, NSString *title) {
        if(isOK){
            if ([@"列表选取" isEqualToString:title]) {
                NSString *editViewTitle = [NSString stringWithFormat:@"编辑%@:",itemModel.name?:@"内容"];
                ThemeCreateEditToolAlertController *textAlert = [ThemeCreateEditToolAlertController createEnumAlertWithDataDict:itemModel.enums defaultValue:itemModel.value complete:^(BOOL isOK, NSString *data) {
                    if (isOK) {
                        itemModel.value = data;
                        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                    }
                }];
                [textAlert setTipTitle:editViewTitle];
                [self presentViewController:textAlert animated:YES completion:nil];

            }else if ([@"原始值修改" isEqualToString:title]){
                [self showTextEditViewForUnKnowTypeValue:itemModel complete:^(BOOL isChange, id value) {
                    if (isChange) {
                        itemModel.value = value;
                        [weakSelf.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                    }
                }];
            }
        }
    }];
}

-(void)showFontSelectViewForItem:(ThemeEditItemModel *)itemModel withIndexPath:(NSIndexPath *)indexPath
{
    __weak typeof(self) weakSelf = self;
    [UIView showActionSheetWithTitle:nil withText:nil withActionNames:@[@"字体编辑",@"原始值修改"] forViewController:self completionHandler:^(BOOL isOK, NSString *title) {
        if(isOK){
            if ([@"字体编辑" isEqualToString:title]) {
                NSString *editViewTitle = [NSString stringWithFormat:@"编辑%@:",itemModel.name?:@"字体内容"];
                UIFont *tempFont = [itemModel createFont];
                ThemeCreateEditToolAlertController *fontAlert = [ThemeCreateEditToolAlertController createFontAlertWithFont:tempFont complete:^(BOOL isOK, UIFont *data) {
                    if (isOK) {
                        itemModel.value = [itemModel parseFont:data];
                        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                    }
                }];
                [fontAlert setTipTitle:editViewTitle];
                [self presentViewController:fontAlert animated:YES completion:nil];
            }else if ([@"原始值修改" isEqualToString:title]){
                [self showTextEditViewForUnKnowTypeValue:itemModel complete:^(BOOL isChange, id value) {
                    if (isChange) {
                        itemModel.value = value;
                        [weakSelf.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                    }
                }];
            }
        }
    }];
}

-(void)showColorSelectViewForItem:(ThemeEditItemModel *)itemModel withIndexPath:(NSIndexPath *)indexPath
{
    __weak typeof(self) weakSelf = self;
    [UIView showActionSheetWithTitle:nil withText:nil withActionNames:@[@"颜色编辑",@"原始值修改"] forViewController:self completionHandler:^(BOOL isOK, NSString *title) {
        if(isOK){
            if ([@"颜色编辑" isEqualToString:title]) {
                NSString *editViewTitle = [NSString stringWithFormat:@"编辑%@:",itemModel.name?:@"颜色内容"];
                UIColor *cColor = [itemModel createColor];
                ThemeCreateEditToolAlertController *colorAlert = [ThemeCreateEditToolAlertController createColorAlertWithColor:cColor complete:^(BOOL isOK, NSString *data) {
                    if (isOK) {
                        itemModel.value = data;
                        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                    }
                }];
                [colorAlert setTipTitle:editViewTitle];
                [self presentViewController:colorAlert animated:YES completion:nil];
            }else if ([@"原始值修改" isEqualToString:title]){
                [self showTextEditViewForUnKnowTypeValue:itemModel complete:^(BOOL isChange, id value) {
                    if (isChange) {
                        itemModel.value = value;
                        [weakSelf.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                    }
                }];
            }
        }
    }];
}

-(void)showImageSelectViewForItem:(ThemeEditItemModel *)itemModel withIndexPath:(NSIndexPath *)indexPath
{
    // 相册上传,直接输入,取消
    __weak typeof(self) weakSelf = self;
    [UIView showActionSheetWithTitle:nil withText:nil withActionNames:@[@"相机拍照",@"相册选取",@"修改地址"] forViewController:self completionHandler:^(BOOL isOK, NSString *title) {
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
                [self showTextEditViewForUnKnowTypeValue:itemModel complete:^(BOOL isChange, id value) {
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
-(void)showTextEditViewForUnKnowTypeValue:(ThemeEditItemModel *)itemModel complete:(void(^)(BOOL isChange,id value))completeBlock
{
    NSString *editViewTitle = [NSString stringWithFormat:@"编辑%@:",itemModel.name?:@"内容"];
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
        completeBlock(isChange,tempValue);
    }];
    [textAlert setTipTitle:editViewTitle];
    [self presentViewController:textAlert animated:YES completion:nil];
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
