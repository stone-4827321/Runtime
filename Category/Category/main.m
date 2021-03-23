//
//  main.m
//  Category
//
//  Created by stone on 2020/7/14.
//

#import <Foundation/Foundation.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import "Person.h"

@interface STObject : NSObject
@end
@implementation STObject
- (void)test {}
@end

@interface STObject (Category)
- (void)testCategory;
@end
@implementation STObject (Category)
- (void)testCategory {}
@end

//获取方法列表
void methodList(Class aClass)
{
    unsigned int outCount;
    Method *methodList = class_copyMethodList(aClass, &outCount);
    for (int i = 0; i < outCount; i++) {
        Method method = methodList[i];
        //名称
        SEL sel = method_getName(method);
        const char *name = sel_getName(sel);
        //参数和返回值的类型编码
        const char *type = method_getTypeEncoding(method);
        //参数个数
        int number = method_getNumberOfArguments(method);
        //指定位置参数的类型
        for(int i = 0; i < number; i ++)
        {
            char *argumentType = method_copyArgumentType(method, i);
            //            NSLog(@"%s", argumentType);
            free(argumentType);
        }
        //返回值类型
        char *returnType = method_copyReturnType(method);
        NSLog(@"方法 %s, %s, %d, %s", name, type, number, returnType);
        //IMP imp = class_getMethodImplementation(aClass, sel);//会导致都执行一个方法
        IMP imp = method_getImplementation(method);
        ((void (*)(id, SEL))imp)([aClass new], sel);
        imp();
        free(returnType);
    }
    free(methodList);
}


int main(int argc, const char * argv[]) {
    @autoreleasepool {
        Person *p = [[Person alloc] init];
        //Student *s = [[Student alloc] init];
        [p sayHello];
        
        methodList(STObject.class);
    }
    return 0;
}
