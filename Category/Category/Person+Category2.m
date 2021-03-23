//
//  Person+Category2.m
//  Category
//
//  Created by stone on 2020/7/14.
//

#import "Person+Category2.h"

@implementation Person (Category2)

+ (void)load {
    NSLog(@"Person load2");
}

+ (void)initialize {
    NSLog(@"Person initialize2");
}

- (void)sayHello {
    NSLog(@"Person hello2");
}

@end
