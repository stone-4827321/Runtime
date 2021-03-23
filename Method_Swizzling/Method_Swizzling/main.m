//
//  main.m
//  Method_Swizzling
//
//  Created by stone on 2020/7/15.
//

#import <Foundation/Foundation.h>
#import <objc/message.h>
#import "JRSwizzle.h"
#import "Student.h"
#import "Person_Swizzle.h"
#import "Aspects.h"


#pragma mark - 静态方法版本 避免方法命名冲突和参数_cmd被篡改，不依赖于必须在类的.m文件中实现

static void MethodSwizzle(id self, SEL _cmd, id arg1);
static void (*MethodOriginal)(id self, SEL _cmd, id arg1);

static void MethodSwizzle(id self, SEL _cmd, id arg1) {
    // 执行被替换方法
    MethodOriginal(self, _cmd, arg1);
    NSLog(@"st_originalMethod2 %@", arg1);
}

BOOL class_swizzleMethodAndStore(Class class, SEL originalSEL, IMP replacementIMP, IMP *store) {
    Method method = class_getInstanceMethod(class, originalSEL);
    IMP imp = NULL;
    if (method) {
        imp = class_replaceMethod(class, originalSEL, replacementIMP, method_getTypeEncoding(method));
        if (!imp) {
            imp = method_getImplementation(method);
        }
    }
    // 存储被替换方法
    if (imp && store) {
        *store = imp;
    }
    return (imp != NULL);
}



@interface Stone : NSObject

@end

@implementation Stone

+ (void)load {
    //class_swizzleMethodAndStore(self, @selector(originalMethod:), (IMP)MethodSwizzle, (IMP *)&MethodOriginal);
    //[self swizzlingWay1];
}

- (void)originalMethod {
    NSLog(@"originalMethod1");
}

- (void)originalMethod:(NSString *)string {
    NSLog(@"originalMethod2 %@", string);
}

- (void)originalMethod:(NSString *)arg1 arg2:(int)arg2 {
    NSLog(@"originalMethod %@ %d", arg1, arg2);
}

+ (void)classoriginalMethod:(NSString *)arg1 arg2:(int)arg2 {
    NSLog(@"originalMethod %@ %d", arg1, arg2);
}

#pragma mark - 常规方法版本

- (void)st_originalMethod {
    [self st_originalMethod];
    NSLog(@"st_originalMethod1");
}

- (void)st_forwardInvocation:(NSInvocation *)invocation {
    SEL sel = invocation.selector;
    NSString *selectorName = NSStringFromSelector(sel);
    NSLog(@"st_forwardInvocation %@", selectorName);
    [self st_forwardInvocation:invocation];
}

+ (void)swizzlingWayForwardInvocation {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL originalSelector = @selector(forwardInvocation:);
        SEL swizzledSelector = @selector(st_forwardInvocation:);
        // swizzling实例方法
        Class class = [self class];
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        // swizzling类方法
        // Class class = object_getClass((id)self);
        // Method originalMethod = class_getClassMethod(class, originalSelector);
        // Method swizzledMethod = class_getClassMethod(class, swizzledSelector);
        // 给源方法增加交换方法的实现，若源方法已经实现，则添加失败并返回NO，否则添加成功并返回YES
        BOOL didAddMethod = class_addMethod(class,
                                            originalSelector,
                                            method_getImplementation(swizzledMethod),
                                            method_getTypeEncoding(swizzledMethod));
        if (didAddMethod) {
            // 添加成功：将源方法的实现(可能是nil，也可能是父类的实现)替换到交换方法的实现
            class_replaceMethod(class,
                                swizzledSelector,
                                method_getImplementation(originalMethod),
                                method_getTypeEncoding(originalMethod));
        }
        else {
            // 添加失败：说明源方法已经有实现，直接将两个方法的实现交换即可
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}


+ (void)swizzlingWay1 {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL originalSelector = @selector(originalMethod);
        SEL swizzledSelector = @selector(st_originalMethod);
        // swizzling实例方法
        Class class = [self class];
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        // swizzling类方法
        // Class class = object_getClass((id)self);
        // Method originalMethod = class_getClassMethod(class, originalSelector);
        // Method swizzledMethod = class_getClassMethod(class, swizzledSelector);
        // 给源方法增加交换方法的实现，若源方法已经实现，则添加失败并返回NO，否则添加成功并返回YES
        BOOL didAddMethod = class_addMethod(class,
                                            originalSelector,
                                            method_getImplementation(swizzledMethod),
                                            method_getTypeEncoding(swizzledMethod));
        if (didAddMethod) {
            // 添加成功：将源方法的实现(可能是nil，也可能是父类的实现)替换到交换方法的实现
            class_replaceMethod(class,
                                swizzledSelector,
                                method_getImplementation(originalMethod),
                                method_getTypeEncoding(originalMethod));
        }
        else {
            // 添加失败：说明源方法已经有实现，直接将两个方法的实现交换即可
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

@end

@interface Jin : Stone

@end

@implementation Jin

@end

@interface Jin1 : Stone

@end

@implementation Jin1

@end

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        [Stone swizzlingWayForwardInvocation];
        
        Stone *stone = [[Stone alloc] init];
//        [stone originalMethod];
//        [stone originalMethod:@"stone"];
        
//        [Person hook];
//        Student *st = [[Student alloc] init];
//        [st sayHello];
        

        
        NSLog(@"%@", stone);
        // 只对stone实例对象的方法进行hook
//        [stone aspect_hookSelector:@selector(originalMethod:arg2:)
//                       withOptions:AspectPositionAfter | AspectOptionAutomaticRemoval
//                        usingBlock:^(id<AspectInfo> aspectInfo, NSString *a, int b) {
//            NSLog(@"aspect_hook in block %@ %d", a, b);
//        }
//                             error:nil];
//        [stone originalMethod:@"stone" arg2:30];
        

        // 对Stone类的所有实例的方法进行hook
//        [Stone aspect_hookSelector:@selector(originalMethod:arg2:)
//                       withOptions:AspectPositionAfter | AspectOptionAutomaticRemoval
//                        usingBlock:^(id<AspectInfo> aspectInfo, NSString *a, int b) {
//            NSLog(@"aspect_hook in block %@ %d", a, b);
//        }
//                             error:nil];
//        [stone originalMethod:@"stone" arg2:30];
        

//        Stone *stone1 = [[Stone alloc] init];
//        [stone1 originalMethod:@"stone1" arg2:30];

        
//        
//        [object_getClass(Stone.class) aspect_hookSelector:@selector(classoriginalMethod:arg2:)
//                                              withOptions:AspectPositionAfter | AspectOptionAutomaticRemoval
//                                               usingBlock:^(id<AspectInfo> aspectInfo, NSString *a, int b) {
//            NSLog(@"in block");
//            NSLog(@"aspect_hook %@ %d", a, b);
//            NSLog(@"aspect_hook %@", aspectInfo.arguments);
//            NSLog(@"aspect_hook %@", aspectInfo.instance);
//            NSLog(@"out block");
//        }
//                                                    error:nil];
//        [Stone classoriginalMethod:@"stone" arg2:30];
        
                [Stone aspect_hookSelector:@selector(originalMethod)
                               withOptions:AspectPositionAfter
                                usingBlock:^(id<AspectInfo> aspectInfo) {
                    NSLog(@"aspect_hook in block");
                }
                                     error:nil];       
                [stone originalMethod];
    }
    return 0;
}
