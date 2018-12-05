//
//  ThemeSelectViewController.m
//  Created on 2018/6/27.

#import "ThemeSelectViewController.h"

#import "ThemeEditManager.h"

#import "ThemeCreateViewController.h"
#import "UIView+YV_AlertView.h"

#define isIpad (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

@interface ThemeSelectViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic) NSString *tableViewCellId;
@property (nonatomic) NSArray *dataList; // 两级array,系统theme列表,自定义列表;

@property(nonatomic) NSString *currentName; // 当前使用的主题名称

@end

@implementation ThemeSelectViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"选择主题";
    self.dataList = @[[NSMutableArray new],[NSMutableArray new]];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:self action:nil];

    [self addNavEditTools];
    
    [self setTableViewData];

}


-(void)addNavEditTools
{
    if (self.navigationItem) {
        UIBarButtonItem *editItem = [[UIBarButtonItem alloc] initWithTitle:@"添加主题" style:UIBarButtonItemStylePlain target:self action:@selector(barItemAction:)];
        editItem.tag = 1;
//        UIBarButtonItem *editItem2 = [[UIBarButtonItem alloc] initWithTitle:@"删除" style:UIBarButtonItemStylePlain target:self action:@selector(barItemAction:)];
//        editItem2.tag = 2;
//        self.navigationItem.rightBarButtonItems = @[editItem,editItem2];
        self.navigationItem.rightBarButtonItem = editItem;

        UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStylePlain target:self action:@selector(barItemAction:)];
        backItem.tag = 3;
        self.navigationItem.leftBarButtonItem = backItem;

    }
}

-(void)barItemAction:(UIBarButtonItem *)sender
{
    if(sender.tag == 1){ // 添加新主题
        NSString *defaultThemeName = [[self.dataList firstObject] firstObject];
        NSString *themeName = defaultThemeName?:[ThemeEditManager currentThemeName];
        NSString *tips = [NSString stringWithFormat:@"以 %@ 为模板,创建新主题?",themeName];
        [self showAlertMessage:tips needConfirm:YES complete:^(BOOL isOK, id data) {
            if (isOK) {
                [self openCreateViewController:themeName];
            }
        }];
    }else if (sender.tag==3){ // 关闭当前界面
        if (self.navigationController.viewControllers.count>1){
            [self.navigationController popViewControllerAnimated:YES];
        }else{ // presentingViewController
            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        }

        
    }else if(sender.tag == 2){ // 删除功能..
        BOOL isEdit = [@"完成" isEqualToString:sender.title];
        [_tableView setEditing:!isEdit animated:YES];
        if(isEdit){
            sender.title = @"删除";
        }else{
            sender.title = @"完成";
        }
    }
}

-(void)openCreateViewController:(NSString *)themeName
{
    [_tableView setEditing:NO animated:YES];
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

    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
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

    [_tableView reloadData];
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
    return isIpad?72:56;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSArray *tempArr = self.dataList[section];
    if (tempArr.count>0) {
        return (isIpad?58:48);
    }
    return 0;
}

-(UIView *)createTableViewSectionView:(NSString *)theTitle
{
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, isIpad?58:48)];
    headerView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    UILabel *tempLabel = [[UILabel alloc] initWithFrame:CGRectMake(isIpad?25:15, 0, 290, isIpad?58:48)];
    tempLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
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
//        // 默认主题不可以删除.
//    return (indexPath.section>0);
    return YES;
}

- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    __weak typeof(self) weakSelf = self;
    UITableViewRowAction *actionReview = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"复制主题" handler:^(UITableViewRowAction * action3, NSIndexPath * indexPath3) {
        NSMutableArray *tempArr = weakSelf.dataList[indexPath3.section];
        NSString *themeName = tempArr[indexPath3.row];
        [weakSelf showAlertMessage:@"以该主题为模板创建新主题?" needConfirm:YES complete:^(BOOL isOK, id data) {
            if (isOK) {
                [weakSelf openCreateViewController:themeName];
            }
        }];
    }];


    if (indexPath.section >0) { // 自定义主题,可以删除.
        UITableViewRowAction *actionDel = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:@"删除主题" handler:^(UITableViewRowAction * action1, NSIndexPath * indexPath1) {
            [weakSelf showAlertMessage:@"确认删除该主题?" needConfirm:YES complete:^(BOOL isOK, id data) {
                if (isOK) {
                    NSMutableArray *tempArr = weakSelf.dataList[indexPath1.section];
                    NSString *item = tempArr[indexPath1.row];

                    NSString *result = @"未知错误,请刷新后重试!";
                    if ([[ThemeEditManager currentThemeName] isEqualToString:item]) {
                        result = @"正在使用中,无法删除!";
                    }else if ([ThemeEditManager removeThemeWithName:item]) {
                            //                    result = @"删除成功!";
                        result = nil;
                        [tempArr removeObjectAtIndex:indexPath1.row];
                    }else{
                        result = @"删除失败!";
                    }
                    if (result) {
                        [weakSelf showAlertMessage:result needConfirm:NO complete:^(BOOL isOK, id data) {
                                // 重新读取
                            [weakSelf loadThemeList];
                        }];
                    }else{
                        [weakSelf.tableView deleteRowsAtIndexPaths:@[indexPath1] withRowAnimation:UITableViewRowAnimationAutomatic];
                    }

                }
            }];

        }];

        return @[actionDel,actionReview];
    }

    return @[actionReview];

}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle != UITableViewCellEditingStyleDelete) { return; }
    __weak typeof(self) weakSelf = self;
    [self showAlertMessage:@"确认删除该主题?" needConfirm:YES complete:^(BOOL isOK, id data) {
        if (isOK) {
            NSMutableArray *tempArr = weakSelf.dataList[indexPath.section];
            NSString *item = tempArr[indexPath.row];

            NSString *result = @"未知错误,请刷新后重试!";
            if ([[ThemeEditManager currentThemeName] isEqualToString:item]) {
                result = @"正在使用中,无法删除!";
            }else if ([ThemeEditManager removeThemeWithName:item]) {
                    //                    result = @"删除成功!";
                [tempArr removeObjectAtIndex:indexPath.row];
                result = nil;
            }else{
                result = @"删除失败!";
            }
            if (result) {
                [weakSelf showAlertMessage:result needConfirm:NO complete:^(BOOL isOK, id data) {
                        // 重新读取
                    [weakSelf loadThemeList];
                }];
            }else{
                [weakSelf.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            }

        }
    }];
}

-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section >0){
        return UITableViewCellEditingStyleDelete; // UITableViewCellEditingStyleNone
    }
    return UITableViewCellEditingStyleNone;
}

-(NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section >0){
        return @"删除主题";
    }
    return nil;
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
