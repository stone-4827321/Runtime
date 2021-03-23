//
//  main.m
//  消息转发
//
//  Created by stone on 16/8/23.
//  Copyright © 2016年 duoyi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "STObject.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        STObject *object = [[STObject alloc] init];
        
        //执行类方法
        //[STObject classMethod:@"stone"];
        
        //执行实例方法
        //[object instanceMethod:@"stone"];
        [object test];

    }
    return 0;
}
