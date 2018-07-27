//
//  ThemeCreateViewController.m
//  TestTheme_sakura
//
//  Created by 王士良 on 2018/6/27.
//  Copyright © 2018年 王士良. All rights reserved.
//

#import "ThemeCreateViewController.h"

#import "ThemeEditCommon.h"
#import "ThemeEditManager.h"
#import "ThemeCreateHeaderView.h"
#import "TransDataUtils.h"

#import "ThemeCreateEditToolAlertController.h"
#import "UIView+YV_AlertView.h"


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
@end

@implementation ThemeCreateViewController

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
    if (!_hasLoadThemeData) {
        [self loadThemeData];
        _hasLoadThemeData = YES;
    }
}
// === 截获NAV返回手势 begin ===
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.navigationController.interactivePopGestureRecognizer.delegate = (id)self.navigationController.topViewController;
}

-(BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer == self.navigationController.interactivePopGestureRecognizer) {
        NSLog(@"--- 获取到返回手势 ---");
        [self barItemAction:self.backBarButtonItem];
        return NO;
    }
    return YES;
}
// ============= 截获NAV返回手势  end =============

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

    switch (sender.tag) {
        case 1: // 清空数据,返回
        {
            [self showAlertMessage:@"是否退出新建主题?" needConfirm:YES complete:^(BOOL isOK, id data) {
                if(isOK){
                    [self clearSavedData];
                    [self.navigationController popViewControllerAnimated:YES];
                }
            }];
        } break;
        case 2: // 清空数据
        {
            [self showAlertMessage:@"是否清空已编辑的内容?" needConfirm:YES complete:^(BOOL isOK, id data) {
                if(isOK){
                    [self clearSavedData];
                        // 重置数据.
                    [self loadThemeData];
                }
            }];
        } break;
        case 3: // 保存数据
        {
            [self showAlertMessage:@"是否保存主题?" needConfirm:YES complete:^(BOOL isOK, id data) {
                if(isOK){
                    [self saveThemeData];
                    [self showAlertMessage:@"保存完成!" needConfirm:NO complete:^(BOOL isOK, id data) {
                        [self.navigationController popViewControllerAnimated:YES];
                    }];
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
    NSString *title = [NSString stringWithFormat:@"主题%-ld",(long)[[NSDate date] timeIntervalSince1970]];
    self.themeName = title;
    self.headerView.textTitle.text = title;
    __weak typeof(self) weakSelf = self;
    self.headerView.callBlack = ^(UILabel *textTitle) {
        [weakSelf showCreateThemeNameView];
    };

    self.tableView.tableHeaderView = self.headerView;
}

-(void)loadThemeData
{

    self.titleList = self.tileList;
    self.subTitleList = self.subItemList;
    [self.tableView reloadData];
    if (self.titleList.count == 0 || self.subItemList.count == 0 || (_titleList.count != _subItemList.count)) {
        // 显示 错误.

        return;
    }


}


    // 重置已设置的数据
-(BOOL)clearSavedData
{
// 清除临时文件夹文件.

    if (self.subTitleList.count>0) {
        for (NSArray *subArr in self.subTitleList) {
            for (ThemeEditItemModel *tempInfo in subArr) {
                tempInfo.value = tempInfo.defalut;
            }
        }
    }
    return YES;
}

-(BOOL)saveThemeData
{
    if (self.themeName.length==0) {
            // 提示 创建主题.
        [self showCreateThemeNameView];
        return NO;
    }

    return [ThemeEditManager saveNewTheme:self.subTitleList withName:self.themeName];

}

// 弹出 创建主题的名称
-(void)showCreateThemeNameView
{
    UIAlertController *alertView = [self showAlertInputTextWithMsg:@"输入新主题的名称" complete:^(BOOL isOK, NSString *name) {
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
                    [self showAlertMessage:@"该名称主题已存在!" needConfirm:NO complete:^(BOOL isOK, id data) {
                        [self showCreateThemeNameView];
                    }];
                }else{
                    self.themeName = name;
                    self.headerView.textTitle.text = name;
                }
            }else{
                [self showAlertMessage:@"名称不能为空,或者其他特殊字符!" needConfirm:NO complete:^(BOOL isOK, id data) {
                    [self showCreateThemeNameView];
                }];
            }
        }
    }];
    alertView.textFields.firstObject.text = self.headerView.textTitle.text;

}

// 保存 资源文件到临时目录,保存theme时 统一移动到正式目录.
-(void)saveThemeFileTempWithFileUrl:(NSURL *)fileUrl
{

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
        if (isIpad) {
            cell.textLabel.font = [UIFont systemFontOfSize:18];
            cell.detailTextLabel.font = [UIFont systemFontOfSize:15];
        }
    }

    NSArray *itemModelArr = self.subTitleList[indexPath.section];
    ThemeEditItemModel *itemModel = itemModelArr[indexPath.row];
    NSString *itemValue = itemModel.type?:(itemModel.value?[itemModel.value description]:itemModel.desc);
    cell.textLabel.text = itemModel.name;
    cell.detailTextLabel.text = itemValue;
    return cell;
}

    // 递归获取子视图
- (void)getSub:(UIView *)view andLevel:(int)level {
    NSArray *subviews = [view subviews];

        // 如果没有子视图就直接返回
    if ([subviews count] == 0) return;

    for (UIView *subview in subviews) {

            // 根据层级决定前面空格个数，来缩进显示
        NSString *blank = @"";
        for (int i = 1; i < level; i++) {
            blank = [NSString stringWithFormat:@"  %@", blank];
        }

            // 打印子视图类名
        NSLog(@"%@%d: %@", blank, level, subview);

            // 递归获取此视图的子视图
        [self getSub:subview andLevel:(level+1)];

    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *itemModelArr = self.subTitleList[indexPath.section];
    ThemeEditItemModel *itemModel = itemModelArr[indexPath.row];
//    NSString *itemValue = itemModel.value;
    NSString *editViewTitle = [NSString stringWithFormat:@"编辑%@:",itemModel.name?:@"内容"];

    // 判断枚举类型
    if(itemModel.enums.count>0){ // enums 格式要正确.
        ThemeCreateEditToolAlertController *textAlert = [ThemeCreateEditToolAlertController createEnumAlertWithDataDict:itemModel.enums defaultValue:itemModel.value complete:^(BOOL isOK, NSString *data) {
            if (isOK) {
                itemModel.value = data;
                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
        }];
        [textAlert setTipTitle:editViewTitle];
        [self presentViewController:textAlert animated:YES completion:nil];

        return;
    }

    /**
     type: color:1,text:2,font:3,image:4,number:5,dict:6,enum:7
     value: nsstring,nsnumber,nsdictionary
     */
    switch (itemModel.mType) {
//        case ThemeEditItemTypeNone:
//        {
//
//        } break;
//        case ThemeEditItemTypeDict:
//        {
//
//        } break;
//        case ThemeEditItemTypeImage:
//        {
//
//        } break;
//        case ThemeEditItemTypeNumber:
//        {
//
//        } break;
        case ThemeEditItemTypeColor: // color
        {
            UIColor *cColor = [TransDataUtils parseColorWithValue:itemModel.value];
            ThemeCreateEditToolAlertController *colorAlert = [ThemeCreateEditToolAlertController createColorAlertWithColor:cColor complete:^(BOOL isOK, NSString *data) {
                if (isOK) {
                    itemModel.value = data;
                    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                }
            }];
            [colorAlert setTipTitle:editViewTitle];
            [self presentViewController:colorAlert animated:YES completion:nil];

        } break;
        case ThemeEditItemTypeText: //text
        {
            NSString *cText = [itemModel.value description];
            ThemeCreateEditToolAlertController *textAlert = [ThemeCreateEditToolAlertController createTextAlertWithText:cText complete:^(BOOL isOK, NSString *data) {
                if (isOK) {
                    itemModel.value = data;
                    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                }
            }];
            [textAlert setTipTitle:editViewTitle];
            [self presentViewController:textAlert animated:YES completion:nil];

        } break;
        case ThemeEditItemTypeFont: // font
        {
            UIFont *tempFont = [TransDataUtils parseFontWithValue:itemModel.value];
            ThemeCreateEditToolAlertController *fontAlert = [ThemeCreateEditToolAlertController createFontAlertWithFont:tempFont complete:^(BOOL isOK, UIFont *data) {
                if (isOK) {
                    itemModel.value = [TransDataUtils parseFontStringWithValue:data];
                    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                }
            }];
            [fontAlert setTipTitle:editViewTitle];
            [self presentViewController:fontAlert animated:YES completion:nil];

        } break;
        default:
        {
            NSString *cText = [TransDataUtils parseDictStringWithValue:itemModel.value];
            ThemeCreateEditToolAlertController *textAlert = [ThemeCreateEditToolAlertController createTextAlertWithText:cText complete:^(BOOL isOK, NSString *data) {
                if (isOK) {
                    itemModel.value = [TransDataUtils parseDictWithValue:data];
                    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                }
            }];
            [textAlert setTipTitle:editViewTitle];
            [self presentViewController:textAlert animated:YES completion:nil];
        }
            break;
    }

}


// utils
//提醒框封装方法
-(UIAlertController *)showAlertMessage:(NSString *)message needConfirm:(BOOL)isNeed complete:(void(^)(BOOL isOK,id data))completionHandler
{
    return [self.view showAlertWithTitle:nil withText:message type:isNeed?2:4 forViewController:self completionHandler:completionHandler];
}

-(UIAlertController *)showAlertInputTextWithMsg:(NSString *)message complete:(void(^)(BOOL isOK,id data))completionHandler
{
    return [self.view showAlertWithTitle:nil withText:message type:5 forViewController:self completionHandler:completionHandler];
}


@end
