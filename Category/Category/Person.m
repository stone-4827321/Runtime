//
//  Person.m
//  Category
//
//  Created by stone on 2020/7/14.
//

#import "Person.h"

@implementation Person

+ (void)load {
    NSLog(@"Person load");
}

+ (void)initialize {
    NSLog(@"Person initialize");
}

- (void)sayHello {
    NSLog(@"Person hello");
}

@end


@implementation Student

+ (void)load {
    NSLog(@"Student load");
}


@end


