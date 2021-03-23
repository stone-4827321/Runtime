//
//  Person_Swizzle.h
//  Method_Swizzling
//
//  Created by stone on 2021/1/25.
//

#import "Person.h"

NS_ASSUME_NONNULL_BEGIN

@interface Person (swizzle)

+ (void)hook;

@end

NS_ASSUME_NONNULL_END
