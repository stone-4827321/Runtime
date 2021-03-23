//
//  Person_Swizzle.m
//  Method_Swizzling
//
//  Created by stone on 2021/1/25.
//

#import "Person_Swizzle.h"
#import "JRSwizzle.h"

@implementation Person (swizzle)
+ (void)load {
    //[self jr_swizzleMethod:@selector(p_sayHello) withMethod:@selector(sayHello) error:nil];
}


+ (void)hook {
    //[self jr_swizzleMethod:@selector(p_sayHello) withMethod:@selector(sayHello) error:nil];
}
- (void)p_sayHello {
    //[self p_sayHello];

    NSLog(@"Person + swizzle say hello");
}
@end
