//
//  ThemeSelectViewController.m
//  TestTheme_sakura
//
//  Created by wsliang on 2018/6/27.
//  Copyright © 2018年 wsliang. All rights reserved.
//

#import "ThemeSelectViewController.h"

#import "ThemeEditCommon.h"
#import "ThemeEditManager.h"

#import "ThemeCreateViewController.h"
#import "UIView+YV_AlertView.h"

//#import "WSTheme.h"


@interface ThemeSelectViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic) NSString *tableViewCellId;
@property (nonatomic) NSArray *dataList; // 两级array,系统theme列表,自定义列表;

@property(nonatomic) NSString *currentName; // 当前使用的主题名称

@end

@implementation ThemeSelectViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"选择主题";

    self.dataList = @[[NSMutableArray new],[NSMutableArray new]];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:self action:nil];

    [self addNavEditTools];
    
    [self setTableViewData];

}


-(void)addNavEditTools
{
    if (self.navigationItem) {
        UIBarButtonItem *editItem = [[UIBarButtonItem alloc] initWithTitle:@"添加" style:UIBarButtonItemStylePlain target:self action:@selector(barItemAction:)];
        UIBarButtonItem *editItem2 = [[UIBarButtonItem alloc] initWithTitle:@"删除" style:UIBarButtonItemStylePlain target:self action:@selector(barItemAction:)];
        editItem2.tag = 2;
        editItem.tag = 1;
        self.navigationItem.rightBarButtonItems = @[editItem,editItem2];
    }
}

-(void)barItemAction:(UIBarButtonItem *)sender
{
    if(sender.tag == 1){
        NSString *themeName = _currentName?:[ThemeEditManager currentThemeName];
        [self openCreateViewController:themeName];
    }else{
        BOOL isEdit = [@"完成" isEqualToString:sender.title];
        [self.tableView setEditing:!isEdit animated:YES];
        if(isEdit){
            sender.title = @"删除";
        }else{
            sender.title = @"完成";
        }
    }
}

-(void)openCreateViewController:(NSString *)themeName
{
    [self.tableView setEditing:NO animated:YES];
    ThemeCreateViewController *createVC = [ThemeCreateViewController new];
    createVC.selectedThemeName = themeName;
    [self.navigationController pushViewController:createVC animated:YES];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self loadThemeList];
}

-(void)setTableViewData
{
    self.tableViewCellId = @"YV_ThemeListViewControllerCell";
}

-(void)loadThemeList
{

    NSMutableArray *defaultThemeList = [self.dataList objectAtIndex:0];
    NSMutableArray *customThemeList = [self.dataList objectAtIndex:1];

    NSArray *allNames = [ThemeEditManager themeNameList];
    NSArray *sysNameList = [ThemeEditManager themeNameListFixed];
    if (sysNameList.count>0) {
        NSMutableArray *alls = [NSMutableArray arrayWithArray:allNames];
        [alls removeObjectsInArray:sysNameList];
        allNames = alls;
    }
    [defaultThemeList setArray:sysNameList];
    [customThemeList setArray:allNames];
    
    NSString *currentName = [ThemeEditManager currentThemeName];
    self.currentName = currentName;

    [self.tableView reloadData];
}

#pragma mark ======== delegate ==========
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.dataList.count;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *tempArr = self.dataList[section];
    return tempArr.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return isIpad?76:54;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSArray *tempArr = self.dataList[section];
    if (tempArr.count>0) {
        return (isIpad?44:38);
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
    tempLabel.textColor = [UIColor grayColor];
    tempLabel.adjustsFontSizeToFitWidth = YES;
    tempLabel.text = theTitle;
    return headerView;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSArray *tempArr = self.dataList[section];
    if (tempArr.count==0) {
        return nil;
    }
    
    NSString *theTitle;
    if (section==0) {
        theTitle = @"系统主题";
    }else{
        theTitle = @"自定义主题";
    }
    UIView *headerView = [self createTableViewSectionView:theTitle];
    return headerView;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:self.tableViewCellId];
    if (!cell) {
        cell=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:self.tableViewCellId];
//        cell.textLabel.textColor = [[YV_DataUtil sharedObject] getDefaultTheme].tableCellTitleColor;
//        cell.detailTextLabel.textColor = [[YV_DataUtil sharedObject] getDefaultTheme].tableCellSubTitleColor;
//        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        if (isIpad) {
            cell.textLabel.font = [UIFont systemFontOfSize:18];
            cell.detailTextLabel.font = [UIFont systemFontOfSize:15];
        }
    }
    NSArray *tempArr = self.dataList[indexPath.section];
    NSString *item = tempArr[indexPath.row];
    cell.textLabel.text = item;

        // 当前正在使用的主题.
    BOOL isCurrent = ([item isEqualToString:self.currentName]);
    cell.accessoryType = isCurrent?UITableViewCellAccessoryCheckmark:UITableViewCellAccessoryNone;

//    cell.detailTextLabel.text = nil;
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if(cell.accessoryType == UITableViewCellAccessoryCheckmark){ // 当前主题
        return;
    }

    NSArray *tempArr = self.dataList[indexPath.section];
    NSString *item = tempArr[indexPath.row];

    self.currentName = item;
    [ThemeEditManager startThemeWithName:item];

    [tableView reloadData];

//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(200 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
//        [self.navigationController popViewControllerAnimated:YES];
//    });
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
        // 默认主题不可以删除.
    return (indexPath.section>0);
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {

        [self showAlertMessage:@"确认删除该主题?" needConfirm:YES complete:^(BOOL isOK, id data) {
            if (isOK) {
                NSMutableArray *tempArr = self.dataList[indexPath.section];
                NSString *item = tempArr[indexPath.row];

                NSString *result = @"未知错误,请刷新后重试!";
                if ([[ThemeEditManager currentThemeName] isEqualToString:item]) {
                    result = @"正在使用中,无法删除!";
                }else if ([ThemeEditManager removeThemeWithName:item]) {
                    result = @"删除成功!";
                }else{
                    result = @"删除失败!";
                }
                [self showAlertMessage:result needConfirm:NO complete:^(BOOL isOK, id data) {
                        // 重新读取
                    [self loadThemeList];
                }];
            }
        }];

    }
}

-(BOOL)deleteThemeWithName:(NSString *)item
{
    if (item) {
            // 检查是否正在使用中
        if ([[ThemeEditManager currentThemeName] isEqualToString:item]) {
            return NO;
        }
        return [ThemeEditManager removeThemeWithName:item];
    }
    return NO;
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
