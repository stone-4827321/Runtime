//
//  main.m
//  动态创建类
//
//  Created by stone on 2021/1/25.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

void sayHello(id self, SEL _cmd, NSString *name)
{
    NSLog(@"hello %@ %@", self, name);
}

NSNumber *ageGetter(id self, SEL _cmd) {
    Ivar ivar = class_getInstanceVariable([self class], "_age");
    return object_getIvar(self, ivar);
}

void ageSetter(id self, SEL _cmd, NSNumber *newAge) {
    Ivar ivar = class_getInstanceVariable([self class], "_age");
    object_setIvar(self, ivar, [newAge copy]);
}


void createClass() {
    // 查询类是否已经被注册
    Class aClass = objc_lookUpClass("Stone");
    if (aClass) {
        return;
    }
    
    // 动态创建类
    aClass = objc_allocateClassPair([NSObject class], "Stone", 0);
    
    // 增加实例变量_name
    class_addIvar(aClass, "_name", sizeof(NSString *), log(sizeof(NSString *)), "@\"NSString\"");
    
    // 增加属性，必须再实现setter和getter方法，通用做法是动态添加方法和实例变量，将属性的setter和getter方法对应到实例变量上
    objc_property_attribute_t type = {"T", "@\"NSNumber\""};
    objc_property_attribute_t code = { "&", "" };
    objc_property_attribute_t atomicity = { "N", "" };
    objc_property_attribute_t ivarName = { "V", "_age"};
    objc_property_attribute_t attrs[] = {type, code, atomicity, ivarName};
    class_addProperty(aClass, "age", attrs, 4);
    
    class_addIvar(aClass, "_age", sizeof(NSNumber *), log(sizeof(NSNumber *)), "@\"NSNumber\"");
    class_addMethod(aClass, NSSelectorFromString(@"ageSetter"), (IMP)ageSetter, "v24@0:8@16");
    class_addMethod(aClass, NSSelectorFromString(@"ageGetter"), (IMP)ageGetter, "@16@0:8");
    
    // 增加方法
    class_addMethod(aClass, NSSelectorFromString(@"sayHello"), (IMP)sayHello, "v24@0:8@16");
    
    // 增加block方法
    IMP block_imp = imp_implementationWithBlock(^(id obj, NSString *str) {
        NSLog(@"hello block %@", str);
    });
    class_addMethod(aClass, NSSelectorFromString(@"block"), block_imp, "v24@0:8@16");
    
    // 注册
    objc_registerClassPair(aClass);
    
    // 运行
    id aInstance = [[aClass alloc] init];
    
    // 设置和获取实例变量1
    Ivar ivar = class_getInstanceVariable(aClass, "_name");
    object_setIvar(aInstance, ivar, @"stone");
    NSString *name = object_getIvar(aInstance, ivar);
    NSLog(@"name = %@",name);
    
    // 设置和获取实例变量2，只能mrc模式下使用
    NSString *setting = @"yuanyuan";
    object_setInstanceVariable(aInstance, "_name", setting);
    NSString *getting;
    object_getInstanceVariable(aInstance, "_name", (void *)&getting);
    NSLog(@"name = %@", getting);
    
    // 设置和获取实例变量3
    [aInstance setValue:@"jin" forKey:@"name"];
    name = [aInstance valueForKey:@"name"];
    NSLog(@"name = %@", name);
    
    // 设置和获取属性1
    [aInstance performSelector:NSSelectorFromString(@"ageSetter") withObject:@(30)];
    NSNumber *age = [aInstance performSelector:NSSelectorFromString(@"ageGetter")];
    NSLog(@"age = %@", age);

    // 设置和获取属性2
    [aInstance setValue:@(31) forKey:@"age"];
    age = [aInstance valueForKey:@"age"];
    NSLog(@"age = %@", age);
    
    // 执行方法1
    SEL sel = NSSelectorFromString(@"sayHello");
    [aInstance performSelector:sel withObject:@"stone"];
    // 执行方法2
    IMP imp = [aInstance methodForSelector:sel];
    void (*function)(id, SEL, NSString *) = (void (*)(id, SEL, NSString *))imp;
    function(aInstance, sel, @"yuan");
    
    sel = NSSelectorFromString(@"block");
    [aInstance performSelector:sel withObject:@"stone"];
    
    sel = NSSelectorFromString(@"block");
    imp = [aInstance methodForSelector:sel];
    void (*blockFunction)(id, SEL, NSString *) = (void (*)(id, SEL, NSString *))imp;
    blockFunction(aInstance, sel, @"yuan");
        
    // 销毁
    aInstance = nil;
    objc_disposeClassPair(aClass);
}


int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // insert code here...
        NSLog(@"Hello, World!");
        createClass();
    }
    return 0;
}
