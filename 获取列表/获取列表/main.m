//
//  main.m
//  Runtime类与对象
//
//  Created by stone on 16/8/22.
//  Copyright © 2016年 duoyi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STObject.h"
#import <objc/runtime.h>

void baseFuncion(Class aClass)
{
    const char *chr = class_getName(aClass);
    NSLog(@"%s",chr);
    
    BOOL isMetaClass = class_isMetaClass(aClass);
    NSLog(@"%d",isMetaClass);
    
    Class superClass = class_getSuperclass(aClass);
    NSLog(@"%@",superClass);
    
    int version = class_getVersion(aClass);
    NSLog(@"%d",version);
    
    size_t size = class_getInstanceSize(aClass);
    NSLog(@"%zu",size);
}

//获取实例变量列表
void ivarList(Class aClass)
{
    unsigned int outCount;
    Ivar *ivarList = class_copyIvarList(aClass, &outCount);
    for (int i = 0; i < outCount; i++) {
        Ivar ivar = ivarList[i];
        
        //名称
        const char *name = ivar_getName(ivar);
        //类型
        const char *type = ivar_getTypeEncoding(ivar);
        //偏移量
        ptrdiff_t offset = ivar_getOffset(ivar);
        NSLog(@"%s, %s, %td",name, type, offset);
    }
    free(ivarList);
}


//获取属性列表
void propertyList(Class aClass)
{
    unsigned int outCount;
    objc_property_t *propertyList = class_copyPropertyList(aClass, &outCount);
    for (int i = 0; i < outCount; i++)
    {
        objc_property_t property = propertyList[i];
        
        //名称
        const char *name = property_getName(property);
        //特性字符串
        const char *attributes = property_getAttributes(property);
        
        NSLog(@"%s, %s", name, attributes);
        
        unsigned int outCount1;
        //获取特性列表
        objc_property_attribute_t *attributeList = property_copyAttributeList(property, &outCount1);
        for(int j = 0; j < outCount1; j++)
        {
            objc_property_attribute_t propertyAttribute = attributeList[j];
            NSLog(@"%s, %s", propertyAttribute.name, propertyAttribute.value);
        }
        free(attributeList);
    }
    free(propertyList);
}


//获取方法列表
void methodList(Class aClass)
{
    unsigned int outCount;
    Method *methodList = class_copyMethodList(aClass, &outCount);
    for(int i = 0; i < outCount; i++)
    {
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
        
        NSLog(@"%s, %s, %d, %s", name, type, number, returnType);
        free(returnType);
    }
    free(methodList);
}

//获取类列表
void classList()
{
    int numClasses;
    Class * classes = NULL;
    
    numClasses = objc_getClassList(NULL, 0);
    if (numClasses > 0) {
        //只能在MRC下运行
//        classes = malloc(sizeof(Class) * numClasses);
        numClasses = objc_getClassList(classes, numClasses);
        
        NSLog(@"number of classes: %d", numClasses);
        
        for (int i = 0; i < numClasses; i++) {
            
            Class cls = classes[i];
            NSLog(@"class name: %s", class_getName(cls));
        }
        
        free(classes);
    }
}

//获取协议列表
void protocolList()
{
    unsigned int outCount;
    __unsafe_unretained Protocol **protocolList = objc_copyProtocolList(&outCount);
    for (int i = 0; i < outCount; i++)
    {
        Protocol *protocol = protocolList[i];

        //名称
        const char *name = protocol_getName(protocol);

        NSLog(@"%s", name);
    }

    free(protocolList);
}

//获取框架列表
void imageNamesList()
{
    NSLog(@"!%s", class_getImageName(NSObject.class));

    unsigned int outCount;
    char **imageNames = (char **)objc_copyImageNames(&outCount);
    for (int i = 0; i < outCount; i++)
    {
        //名称
        char *name = imageNames[i];
        NSLog(@"%s", name);
    }
    
    //获取框架中所有的类名
    char *name = imageNames[outCount-1];
    char **classNames = (char **)objc_copyClassNamesForImage(name, &outCount);
    for (int i = 0; i < outCount; i++)
    {
        //名称
        char *name = classNames[i];
        NSLog(@"!%s", name);
    }
}


#pragma mark - MAIN

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        ivarList([STObject class]);
    }
    return 0;
}


