//
//  TestCoderObject.m
//  test_WSTheme
//
//  Created by wsliang on 2018/8/1.
//  Copyright © 2018年 wsliang. All rights reserved.
//

#import "TestCoderObject.h"

@implementation TestCoderObject


-(void)testPrint
{
    NSLog(@"==== testPrint ====");
}

+(instancetype)create
{
    return [TestCoderObject new];
}

- (void)encodeWithCoder:(nonnull NSCoder *)aCoder {
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:self.titles forKey:@"titles"];
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.name = [aDecoder decodeObjectForKey:@"name"];
        self.titles = [aDecoder decodeObjectForKey:@"titles"];
    }
    return self;
}

@end
