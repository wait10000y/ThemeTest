//
//  ThemeCreateEditEnumView.m
//  test_WSTheme
//
//  Created by 王士良 on 2018/7/27.
//  Copyright © 2018年 王士良. All rights reserved.
//

#import "ThemeCreateEditEnumView.h"

@interface ThemeCreateEditEnumView()
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic) NSString *tableViewCellId;
@property (nonatomic) NSMutableArray *dataList;

@property(nonatomic) NSString *currentName; // 当前选中的显示内容.
@property(nonatomic) NSDictionary *mDict; // 原始数据. currentName查找value 返回.


@end

@implementation ThemeCreateEditEnumView

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.tableView.layer.cornerRadius = 5;
    self.tableView.layer.masksToBounds = YES;

    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0.1f, 0.1f)];
    self.tableViewCellId = @"ThemeCreateEditEnumViewCellId";
    _dataList = [NSMutableArray new];

}

+(instancetype)createView
{
    return [[[NSBundle mainBundle] loadNibNamed:@"ThemeCreateEditEnumView" owner:nil options:nil] firstObject];
}

-(id)getCurrentValue
{
    return _currentName?[_mDict objectForKey:_currentName]:nil;
}

-(void)setEnumDict:(NSDictionary *)theDict defaultValue:(id)theValue
{
    [_dataList removeAllObjects];
    _mDict = nil;
    _currentName = nil;

    if (theDict.count>0) {
        if (theValue) {
            
            [theDict enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL * stop) {
                if ([theValue isEqual:obj]) {
                    self.currentName = key;
                    *stop = YES;
                }
            }];
            
            if (!self.currentName) {
                _currentName = [theValue description];
                [_dataList addObject:_currentName];
                [_dataList addObjectsFromArray:theDict.allKeys];
                NSMutableDictionary *tempDict= [NSMutableDictionary dictionaryWithDictionary:theDict];
                [tempDict setObject:theValue forKey:_currentName];
                _mDict = tempDict;
            }else{
                [_dataList addObjectsFromArray:theDict.allKeys];
                _mDict = theDict;
            }
            
        }else{
            _mDict = theDict;
            [_dataList addObjectsFromArray:theDict.allKeys];
            _currentName = [_dataList firstObject];
        }
        
    }else if(theValue){
        _currentName = [theValue description];
        [_dataList addObject:_currentName];
        _mDict = @{_currentName:theValue};
    }

    [self.tableView reloadData];
}



-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataList.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 42;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:self.tableViewCellId];
    if (!cell) {
        cell=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:self.tableViewCellId];
            //        cell.textLabel.textColor = [[YV_DataUtil sharedObject] getDefaultTheme].tableCellTitleColor;
            //        cell.detailTextLabel.textColor = [[YV_DataUtil sharedObject] getDefaultTheme].tableCellSubTitleColor;
            //        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    NSString *name = self.dataList[indexPath.row];
    cell.textLabel.text = name;
    cell.detailTextLabel.text = [[self.mDict objectForKey:name] description];
        // 当前正在使用的主题.
    BOOL isCurrent = ([name isEqualToString:self.currentName]);
    cell.accessoryType = isCurrent?UITableViewCellAccessoryCheckmark:UITableViewCellAccessoryNone;

    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if(cell.accessoryType == UITableViewCellAccessoryCheckmark){ // 当前主题
        return;
    }

    NSString *name = self.dataList[indexPath.row];
    self.currentName = name;
    [tableView reloadData];
}

@end
