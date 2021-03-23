//
//  Person+Category1.m
//  Category
//
//  Created by stone on 2020/7/14.
//

#import "Person+Category1.h"
#import <objc/runtime.h>

@implementation Person (Category1)

+ (void)load {
    NSLog(@"Person load1");
}

+ (void)initialize {
    NSLog(@"Person initialize1");
}


- (void)sayHello {
    NSLog(@"Person hello1");
}

@end

@implementation Person (Category11)

+ (void)load {
    NSLog(@"Person load11");
}

+ (void)initialize {
    NSLog(@"Person initialize11");
}


- (void)sayHello {
    NSLog(@"Person hello11");
}

@end
