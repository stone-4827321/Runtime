//
//  Student_Swizzle.m
//  Method_Swizzling
//
//  Created by stone on 2021/1/25.
//

#import "Student_Swizzle.h"
#import "JRSwizzle.h"

@implementation Student (swizzle)
+ (void)load {
    [self jr_swizzleMethod:@selector(s_sayHello) withMethod:@selector(sayHello) error:nil];
}

- (void)s_sayHello {
    [self s_sayHello];

    NSLog(@"Student + swizzle say hello");
}
@end
