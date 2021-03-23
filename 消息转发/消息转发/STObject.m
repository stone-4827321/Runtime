//
//  STObject.m
//  消息转发
//
//  Created by stone on 16/8/23.
//  Copyright © 2016年 duoyi. All rights reserved.
//

#import "STObject.h"
#import <objc/runtime.h>

@interface STHelp_Test : NSObject

@end

@implementation STHelp_Test

@end



@interface STHelp : NSObject

@end

@implementation STHelp

+ (void)classMethod:(NSString *)string
{
    NSLog(@"help classMethod = %@", string);
}

- (void)instanceMethod:(NSString *)string {
    NSLog(@"help instanceMethod = %@", string);
}

- (void)test {
    NSLog(@"STProtect test");
}

@end



@interface STObject()

@end

@implementation STObject

- (void)test {
    NSLog(@"test");
}

#pragma mark - 消息动态解析

// 类方法
+ (BOOL)resolveClassMethod:(SEL)sel {
#warning 跳过消息动态解析
    return [super resolveClassMethod:sel];
    
    if (sel == @selector(classMethod:)) {
        //增加类方法
        SEL addSel = @selector(myClassMethod:);
        IMP imp = class_getMethodImplementation(object_getClass(self), addSel);
        Method method = class_getClassMethod(object_getClass(self), addSel);
        const char *types = method_getTypeEncoding(method);
        class_addMethod(object_getClass(self), sel, imp, types);

        return YES;
    }
    return [super resolveClassMethod:sel];
}

+ (void)myClassMethod:(NSString *)string {
    NSLog(@"myClassMethod = %@", string);
}


// 实例方法
+ (BOOL)resolveInstanceMethod:(SEL)sel {
#warning 跳过消息动态解析
    return [super resolveInstanceMethod:sel];
    
    if (sel == @selector(instanceMethod:)) {
        // 增加实例方法
        SEL addSel = @selector(myInstanceMethod:);
        IMP imp = class_getMethodImplementation(self.class, addSel);
        Method method = class_getInstanceMethod(self.class, addSel);
        const char *types = method_getTypeEncoding(method);
        class_addMethod(self.class, sel, imp, types);
        
        return YES;
    }
    
    return [super resolveInstanceMethod:sel];
}

- (void)myInstanceMethod:(NSString *)string {
    NSLog(@"myInstanceMethod = %@", string);
}

#pragma mark - 消息接收者重定向

// 类方法
+ (id)forwardingTargetForSelector:(SEL)sel {
#warning 跳过消息接收者重定向
    return [super forwardingTargetForSelector:sel];
    
    if (sel == @selector(classMethod:)) {
        return NSClassFromString(@"STHelp");
    }
    
    return [super forwardingTargetForSelector:sel];
}


// 实例方法
- (id)forwardingTargetForSelector:(SEL)sel {
#warning 跳过消息接收者重定向
    return [super forwardingTargetForSelector:sel];
    
    if (sel == @selector(instanceMethod:)) {
        // 将消息转给help来执行，STHelp已实现instanceMethod:方法
        STHelp *help = [[STHelp alloc] init];
        return help;
    }
    
    return [super forwardingTargetForSelector:sel];
}


#pragma mark - 消息重定向

// 类方法
+ (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    NSMethodSignature *signature = [super methodSignatureForSelector:sel];
    
    if (!signature) {
        if (sel == @selector(classMethod:)) {
            signature = [STHelp methodSignatureForSelector:sel];
        }
    }
    return signature;
}
    
+ (void)forwardInvocation:(NSInvocation *)invocation {
    SEL sel = invocation.selector;
    
    if (sel == @selector(classMethod:)) {
        //方法执行
        [invocation invokeWithTarget:[STHelp class]];
        [invocation invokeWithTarget:[STHelp class]];
    }
    else {
        [super forwardInvocation:invocation];
    }
}


// 实例方法
- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    if(sel == @selector(instanceMethod:)) {
        // 获取方法签名
        NSMethodSignature *signature = [STHelp instanceMethodSignatureForSelector:sel];
        if (signature) {
            return signature;
        }
        //signature = [NSMethodSignature signatureWithObjCTypes:"@@:@"];
    }
    
    return [super methodSignatureForSelector:sel];
}


- (void)forwardInvocation:(NSInvocation *)invocation {
    SEL sel = invocation.selector;
    if(sel == @selector(instanceMethod:)) {
        STHelp *help = [[STHelp alloc] init];
        //方法执行
        [invocation invokeWithTarget:help];
        
        // 可转发给多个对象
        STHelp *help1 = [[STHelp alloc] init];
        [invocation invokeWithTarget:help1];
    }
    else {
        [super forwardInvocation:invocation];
    }
}





@end
