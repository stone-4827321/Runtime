//
//  STObject.m
//  Runtime类与对象
//
//  Created by stone on 16/8/22.
//  Copyright © 2016年 duoyi. All rights reserved.
//

#import "STObject.h"
#import <objc/runtime.h>

@interface STObject()
{
    NSInteger _age;
}

@end

@implementation STObject

- (void)test
{
    [self superTest];
}



@end








