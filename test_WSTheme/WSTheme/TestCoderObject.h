//
//  TestCoderObject.h
//  test_WSTheme
//
//  Created by wsliang on 2018/8/1.
//  Copyright © 2018年 wsliang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TestCoderObject : NSObject<NSCoding>

@property(nonatomic) NSString *name;
@property(nonatomic) NSArray *titles;

-(void)testPrint;
+(instancetype)create;


@end
