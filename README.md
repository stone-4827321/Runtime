# 概述

- Objective-C 是一门动态语言，因为它总是把一些决定性的工作从编译阶段推迟到运行时阶段。Objective-C 代码的运行不仅需要编译器，还需要运行时系统（Runtime Sytem）来执行编译后的代码（在编译期并不能决定真正调用哪个函数，只有在真正运行时才会根据函数的名称找到对应的函数来调用）。

  - 静态语言：如 C 语言，编译阶段就要决定调用哪个函数，如果函数未实现就会编译报错。
  
  - 动态语言：如 Objective-C 语言，编译阶段并不能决定真正调用哪个函数，只有函数声明而没有实现也不会报错。

- Runtime 又叫运行时，是一套底层的 C 语言 API，是 iOS 系统的核心之一。**开发者在编码过程中，可以给任意一个对象发送消息，在编译阶段只是确定了要向接收者发送这条消息，而接收者将要如何响应和处理这条消息，那就要看运行时来决定了**。

- Objective-C 在三种层面上与 Runtime 系统进行交互：

    - 通过 Objective-C 源代码：一般情况开发者只需要编写 Objective-C 代码即可，Runtime 系统自动在幕后把源代码在编译阶段转换成运行时代码，在运行时确定对应的数据结构和调用具体哪个方法；
    
    - 通过 Foundation 框架的 NSObject 类定义的方法（内省方法：对象揭示自己作为一个运行时对象的详细信息的一种能力）；

    ```objective-c
    // NSObject 和运行时相关的方法
    + (Class)class;
    - (BOOL)isKindOfClass:(Class)aClass;    // 判断是否是这个类或者这个类的子类的实例
    - (BOOL)isMemberOfClass:(Class)aClass;  // 判断是否是这个类的实例
    - (BOOL)conformsToProtocol:(Protocol *)aProtocol;
    - (BOOL)respondsToSelector:(SEL)aSelector;
    ```

    - 通过对 Runtime 库函数的直接调用。

    ```objective-c
    // 导入Runtime 函数库
    #import <objc/runtime.h> 
    #import <objc/message.h>
    ```

# 数据结构

## Class & isa

- `NSObject` 的定义：是一个结构体，包含了一个 `Class ` 类型的指针变量。

  ```objective-c
  // oc版本
  @interface NSObject <NSObject> {
      Class isa;
  }
  
  // c语言版本
  struct NSObject_IMPL {
      Class isa;
  };
  ```

- `Class` 的定义：是一个结构体，包含 `Class ` 类型的指针变量，以及方法列表、属性列表、协议列表、成员变量列表等。

  ```c++
  typedef struct objc_class *Class;
  
  struct objc_class : objc_object {
      Class superclass; // superclass指针
      cache_t cache; // 方法缓存            
      class_data_bits_t bits; // 方法列表，属性列表，协议列表，成员变量列表
  }
  
  struct objc_object {
      isa_t isa;
  }
  
  union isa_t  {
      isa_t() { }
      isa_t(uintptr_t value) : bits(value) { }
      Class cls;
      uintptr_t bits;
  }
  
  //综合以上，修改objc_class结构体
  struct objc_class  {
  		Class cls; // 继承自objc_object
      Class superclass; // superclass指针
      cache_t cache; // 方法缓存            
      class_data_bits_t bits; // 方法列表，属性列表，协议列表，成员变量列表
  }
  ```

- OC的类的信息（方法、属性、成员变量等等）分别存放在哪？

  - 实例对象的方法、属性、成员变量、协议信息等等存放在 class 类对象中；
  
  - 类方法存放在 mata-class 元类对象中；
  
  - 成员变量的具体值存放在实例对象中，因为成员变量的描述信息，如类型等，在内存中只需存储一份，所以将属性描述信息存放在类对象中，但是成员变量的值每个实例变量都不相同，所以每个实例对象存放一份。

  ![](/Users/3kmac/Desktop/我的文档/图片/isa.png)

- 如何找到执行的方法？

  - **对象的实例方法调用时，通过对象的 isa 在类中获取方法的实现。**
  
  - **类对象的类方法调用时，通过类的 isa 在元类中获取方法的实现。**
  
  - 对象的父类的实例方法调用时，会先通过对象的 isa 找到类，然后通过 superclass 找到父类，最后找到实例方法的实现进行调用。
  
  - 对象的父类的类方法调用时，会先通过类的 isa 找到元类，然后通过 superclass 找到父元类，最后找到类方法的实现进行调用。

- 总结：图中实线是 `super_class` 指针，虚线是 `isa` 指针。class 指类，meta-class 指基类。

  - instance 的 `isa` 指向 class，class 的 `isa` 指向 meta-class，mate-class 的 `isa` 都指向基类（Root class）的 meta-clasee，基类的 `isa` 指向自己；
  
  - class 的 `super_class` 指向父类的 class，meta-class 的 `superclass` 指向父类的 meta-class，基类的meta-class 的 `superclass` 指向基类的 class。

![](/Users/3kmac/Desktop/我的文档/图片/isa&superclass.png)

- 考试题：

  - Runtime 函数的实现：

  ```c++
  // 返回类本身
  + (Class)class {
      return self;
  }
  
  // 返回isa指针
  - (Class)class {
      return object_getClass(self);
  }
  
  // 返回isa指针
  Class object_getClass(id obj) {
      if (obj) return obj->getIsa();
      else return Nil;
  }
  
  + (BOOL)isKindOfClass:(Class)cls {
    	// 从类的isa开始上溯
      for (Class tcls = object_getClass((id)self); tcls; tcls = tcls->superclass) {
          if (tcls == cls) return YES;
      }
      return NO;
  }
  
  - (BOOL)isKindOfClass:(Class)cls {
      // 从类本身开始上溯
      for (Class tcls = [self class]; tcls; tcls = tcls->superclass) {
          if (tcls == cls) return YES;
      }
      return NO;
  }
  
  + (BOOL)isMemberOfClass:(Class)cls {
      return object_getClass((id)self) == cls;
  }
  
  - (BOOL)isMemberOfClass:(Class)cls {
      return [self class] == cls;
  }
  ```

  - `isKindOfClass` 和 `isMemberOfClass`：

  ```objective-c
  // YES, [NSObject class] -> isa = NSObject元类 -> superclass = NSObject类 = [NSObject class]
  [[NSObject class] isKindOfClass:[NSObject class]]
  // NO, [STObject class] -> isa = STObject元类 -> superclass = NSObject元类 -> superclass = NSObject类
  [[STObject class] isKindOfClass:[STObject class]];
  // YES
  [[STObject class] isKindOfClass:[NSObject class]];
  // YES, [STObject new] -> isa = STObject类 = [STObject class]
  [[STObject new] isKindOfClass:[STObject class]];
  
  // NO, [NSObject class] -> isa = NSObject元类 != [NSObject class]
  [[NSObject class] isMemberOfClass:[NSObject class]]
  // NO, [STObject class] -> isa = STObject元类 != [STObject class]
  [[STObject class] isMemberOfClass:[STObject class]]
  // NO, [STObject new] -> isa = STObject类 != [NSObject class]
  [[STObject new] isMemberOfClass:[NSObject class]]
  // YES, [STObject new] -> isa = STObject类 = [STObject class]
  [[STObject new] isMemberOfClass:[STObject class]]
  ```
  - 方法的执行：指针调用方法。

  ```objective-c
  @implementation STObject
  - (void)func {
      NSLog(@"instance func");
  }
  + (void)func {
      NSLog(@"class func");
  }
  @end
  
  // cls1 是指向STObject类对象
  id cls1 = [STObject class];
  // obj1 是cls1的地址（指针）
  void *obj1 = &cls1;
  // 等同于调用了实例方法
  [(__bridge id)obj1 func];
  // 输出 instance func
  
  // cls2 是指向STObject元类对象
  id cls2 = object_getClass([STObject class]);
  // obj2 是cls2的地址（指针）
  void *obj2 = &cls2;
  // 等同于调用了类方法
  [(__bridge id)obj2 func];
  // 输出 class func
  ```

  - 方法的查找：isa -> superclass

  ```objective-c
  @interface NSObject (Sark)
  + (void)foo;
  - (void)foo;
  @end
  
  @implementation NSObject (Sark)
  - (void)foo {
     NSLog(@"IMP: -[NSObject foo]");
  }
  @end
  // foo类方法在NSObject的元类上，但没有实现
  // foo实例方法在NSObject的类上，有对应的实现
    
  // NSObject类.isa = NSObject元类，没有找到，NSObject元类.superclass = NSObject类，找到
  [NSObject foo];
  // NSObject实例.isa = NSObject类，找到
  [[NSObject new] foo];
  
  // 如果将以上类扩展和调用都替换为自定义类STObject，则第一个方法调用会提示找不到对应方法
  // 只有在STObject类上才有对应的实现，但方法查找链为：
  // STObject类.isa = STObject元类，STObject元类.superclass = NSObject元类，NSObject元类.superclass = NSObject类，NSObject类.superclass = nil
  ```

## Ivar & Property

- **Ivar 成员变量**为在类声明和类扩展  @interface 或者类实现 @implementation 后面的大括号中声明的变量。

- Runtime 使用 `ivar_t` 结构体表示成员变量。

  ```c++
  typedef struct ivar_t *Ivar;
  struct ivar_t {
      int32_t *offset; // 偏移
      const char *name; // 名称
      const char *type; // 类型编码
  };   
  ```

- **Property 属性**为在类声明和类扩展 @interface 中通过 `@property` 定义的变量。

  - 属性是对成员变量的封装，会被编译器转换成了成员变量，并且自动添加了 `Set` 和 `Get` 方法。

- Runtime 使用 `property_t` 结构体表示属性。

- ```c++
  typedef struct property_t *objc_property_t;
  struct property_t {
      const char *name; // 名称
      const char *attributes; // 特性字符串，包含类型，变量名称，修饰符标记等
  };
  ```

- 特性字符串的键和值

  ```objective-c
  @property (nonatomic, strong) NSString *name;
  attributes -> T@"NSString",&,N,V_name
  ```

  | key  | value       | 说明                    |
  | ---- | ----------- | ----------------------- |
  | T    | @"NSString" | 属性的类型              |
  | &    |             | strong/retain           |
  | W    |             | weak                    |
  | N    |             | copy                    |
  | N    |             | nonatomic               |
  | G    |             | 自定义的getter          |
  | S    |             | 自定义的setter          |
  | R    |             | readonly                |
  | V    | _name       | 属性对应的实例变量_name |

### 内存布局

- Ivar 和 Property 属性决定了对象的内存大小。

  ```objective-c
  @interface STObject : NSObject
  {
      int age;         //4个字节
      BOOL sex;        //1个字节
      NSString* name;  //8个字节的指针地址
      short lifeTime;      //2个字节
      NSString* style;    //8个字节的指针地址
  }
  @end
  
  Class class = objc_getClass("STObject");
  unsigned int count;
  Ivar* ivars =class_copyIvarList(objc_getClass("STObject"), &count);
  for (unsigned int i = 0; i < count; i++) {
      Ivar ivar = ivars[i];
      ptrdiff_t offset = ivar_getOffset(ivar);
      NSLog(@"%s = %td",ivar_getName(ivar),offset);
  }
  free(ivars);
  NSLog(@"总字节 = %lu",class_getInstanceSize(objc_getClass("STObject")));
  
  /* 输出
  int age = 8
  BOOL sex = 12
  NSString *name = 16
  short lifeTime = 24
  NSString *style = 32
  总字节 = 40
  */
  ```

  - 内存偏移顺序为：h文件的 ivar -> m文件的 ivar -> h文件的 property 基本类型 -> m文件的 property 对象类型。
  
  - 第一个成员变量的偏移地址总是8，因为从内存中 0-8 的位置是 isa 指针。

- 有三种方式来获取一个对象（类型）的内存大小。

    - `sizeof`：计算类型所占用的内存空间；
    
    - `class_getInstanceSize`：创建对象申请的内存大小；
    
    - `malloc_size`：系统为该对象实际开辟的内存大小。

    ```
    sizeof(STObject.class) -> 8
    class_getInstanceSize(STObject.class) -> 40
    malloc_size((__bridge const void *)([[STObject alloc] init])) -> 48
    ```

- 结构体的内存对齐规则：

    - 第一个成员的首地址为0；
    
    - 每个成员的首地址是自身大小的整数倍；
    
    - 结构体的内存总大小是其成员中所含最大类型的整数倍。

    ![](https://tva1.sinaimg.cn/large/008eGmZEgy1gnewweaw1wj307n0ardfp.jpg)

- iOS 系统的内存对齐规则：

    - 结构体的内存总大小是16字节的整数倍。

## Method & SEL & IMP

- 每个类都对应有一个 `class_ro_t` 结构体和一个 `class_rw_t` 结构体。编译结束之后，类的方法就已经存储在 `class_ro_t` 里面的 `baseMethodList` 变量中了；当运行完 Runtime的 `realizeClass` 方法之后，会将 `baseMethodList` 拷贝到 `class_rw_t` 的 `methods` 变量中，并将各种分类的方法拷贝到 `methods` 中。**这样类的所有方法就都聚集在 `class_rw_t` 的 `methods` 变量中了。**

- Runtime 使用 `method_t` 结构体来表示方法。

  ```c++
  typedef struct method_t *Method;
  struct method_t {
      SEL name;
      const char *types;
      IMP imp;
  }   
  
  typedef struct objc_selector *SEL;
  typedef void (*IMP)(void /* id, SEL, ... */ );
  ```
  - **SEL** 是选择器或选择子，代表方法在 Runtime 期间的标识符。

  - **IMP** 是一个函数指针，指向方法最终实现的首地址。

  - types 表示类型编码，通过字符串拼接的方式将返回值和参数拼接成一个字符串，来代表函数返回值及参数。

    > 当方法为 `- (void)setName:(NSString *)name` 时，类型编码返回为 `v24@0:8@16`
    >
    > - v24 代表返回值为 void，偏移量为24；
    > - @0 代表第一个参数 self，偏移量为0；
    > - :8 代表第二个参数 _cmd，偏移量为8；
    > - @16 代表第三个参数 name，偏移量为16；
    >
    > 参考：https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html#//apple_ref/doc/uid/TP40008048-CH100-SW1

- **一个类（Class）持有一个分发表，在运行期分发消息，表中的每一个实体代表一个方法（Method），它的名字叫做选择子（SEL），可用于快速查询，对应着一种方法实现（IMP）。通过 SEL 快速准确地获得对应的 IMP，取得 IMP 后，就获得了执行这个方法的代码。**

  > 使用分发表之前会优先去缓存中获取 IMP，缓存会存储最近使用过的方法，若没找到就会使用分发表查询。

- 三者之间的互相转换：

  ```objective-c
  SEL sel = @selector(methodName);
  SEL sel = NSSelectorFromString(@"methodName");
  SEL sel = sel_registerName("methodName");
  
  IMP imp = [aInstance methodForSelector:sel];
  IMP imp = [aClass instanceMethodForSelector:sel];
  IMP imp = class_getMethodImplementation(cls, sel);
  
  Method method = class_getInstanceMethod(cls, sel);
  Method method = class_getClassMethod(cls, sel);
  
  SEL sel = method_getName(method);
  IMP imp = method_getImplementation(method);
  ```

- 获取方法地址直接调用，提高效率：
  ```objective-c
  Stone *object = [[Stone alloc] init];
  
  // 无参无返回
  SEL sel1 = NSSelectorFromString(@"test1");
  IMP imp1 = [object methodForSelector:sel1];
  imp1();
  
  // 有参无返回
  SEL sel2 = NSSelectorFromString(@"test2:");
  IMP imp2 = class_getMethodImplementation(Stone.class, sel2);
  void (*test2)(id, SEL, NSString *) = (void (*)(id, SEL, NSString *))imp2;
  test2(object, sel2, @"stone");
  
  // 无参有返回
  SEL sel3 = NSSelectorFromString(@"test3");
  IMP imp3 = [object methodForSelector:sel3];
  NSString *(*test3)(id, SEL) = (NSString * (*)(id, SEL))imp3;
  NSString *string1 = test3(object, sel3);
  
  // 有参有返回
  SEL sel4 = NSSelectorFromString(@"test4:");
  IMP imp4 = [object methodForSelector:sel4];
  NSString *(*test4)(id, SEL, NSString *) = (NSString * (*)(id, SEL, NSString *))imp4;
  NSString *string2 = test4(object, sel3, @"stone");  
  ```

- 使用 `super` 关键词调用方法的时候，查找方法的实现是跳过本类从父类的方法列表中开始查找实现方法。**尽管执行的是父类的方法，但是方法的调用者（消息的发送者）依旧是当前类**。

  ```objective-c
  NSLog(@"super class = %@",NSStringFromClass([super class]));
  NSLog(@"self class = %@",NSStringFromClass([self class]));
  
  // super class = Student
  // self class = Student
  ```

# 应用

## 动态创建类

- 查询类是否已经被注册。

  ```objective-c
  // 查询类是否已经被注册
  Class aClass = objc_lookUpClass("Stone");
  if (aClass) {
      return;
  }
  ```

- 注册类，添加成员变量，属性（不推荐），方法等。

  - 增加属性还必须再实现 setter 和 getter 方法，通用做法是动态添加方法和实例变量，将属性的 setter 和 getter 方法对应到实例变量上。

  ```objective-c
  // 动态创建类
  aClass = objc_allocateClassPair(NSObject.class, "Stone", 0);
  
  // 增加成员变量
  class_addIvar(aClass, "_name", sizeof(NSString *), log(sizeof(NSString *)), @encode(NSString *));
  
  // 增加方法
  void sayHello(id self, SEL _cmd, NSString *name) {
      NSLog(@"hello %@ %@", self, name);
  }
  class_addMethod(aClass, NSSelectorFromString(@"sayHello"), (IMP)sayHello, "v@:@");
  
  // 增加block方法
  void (^block)(id, NSString *) = ^(id object, NSString *string) {
      NSLog(@"block:%@", string);
  };
  IMP block_imp = imp_implementationWithBlock(block);
  class_addMethod(aClass, NSSelectorFromString(@"block"), block_imp, "v@:@");
  
  // 注册
  objc_registerClassPair(aClass);
  ```

- 设置和获取成员变量的值，调用方法。

  ```objective-c
  // 创建实例
  id aInstance = [[aClass alloc] init];
  
  // 设置和获取实例变量
  Ivar ivar = class_getInstanceVariable(aClass, "_name");
  object_setIvar(aInstance, ivar, @"stone");
  NSString *name = object_getIvar(aInstance, ivar);
  NSLog(@"name = %@",name);
      
  // 调用方法
  SEL sel = NSSelectorFromString(@"sayHello");
  IMP imp = [aInstance methodForSelector:sel];
  void (*function)(id, SEL, NSString *) = (void (*)(id, SEL, NSString *))imp;
  function(aInstance, sel, @"yuan");
  
  // 调用block方法
  sel = NSSelectorFromString(@"block");
  imp = [aInstance methodForSelector:sel];
  void (*blockFunction)(id, SEL, NSString *) = (void (*)(id, SEL, NSString *))imp;
  blockFunction(aInstance, sel, @"stone");
  ```

- 使用完毕后进行销毁

  ```objective-c
  // 销毁
  aInstance = nil;
  objc_disposeClassPair(aClass);
  ```

## 分类 Category

- 分类主要有3个作用：

  - 将类的实现分散到多个不同文件或多个不同框架中，既可以减少单个文件的体积，又可以按需加载所需的 分类；
  
  - 创建对私有方法的前向引用（只要知道对象支持的某个方法的名称，即使该对象所在的类的接口中没有该方法的声明，也可以调用该方法。不过这么做编译器会报错，但是只要新建一个该类的类别，在类别.h文件中写上原始类该方法的声明，类别.m文件中什么也不写，就可以正常调用私有方法了）；
  
  - 声明私有方法（定义在 .m 文件中的类扩展方法为私有的）；

- **实现原理**：将分类中的方法，属性，协议数据放在 `category_t` 结构体中，在运行时会将结构体内的列表拷贝到类对象的列表中。

    ```c++
    struct _category_t {
    	const char *name;
    	struct _class_t *cls;
    	const struct _method_list_t *instance_methods; //实例方法
    	const struct _method_list_t *class_methods;    //类方法
    	const struct _protocol_list_t *protocols;			 //协议
    	const struct _prop_list_t *properties;			   //属性
    };
    ```

- 同名方法执行顺序：

    > 运行时在查找方法的时候是按照方法列表的顺序查找的，它只要一找到对应名字的方法，就会停止查找而去执行。

    - 多个分类中的同一方法：最后被编译的分类中的方法会被调用。

        > 多个分类中的方法共存于类的方法列表中，最后被编译的分类中的方法排在列表的前面。
        >
        > 父类的分类和子类的分类的执行顺序也只依赖于编译顺序。
        >
        > 最后被编译表示在 buildPhases->Compile Sources 排在后面的实现文件。

    - 分类和主类中的同一方法：分类中的方法会被调用。

        > 分类和主类中的方法共存于类的方法列表中，分类的方法排在列表的前面。

    - `+ (void)load` 方法：调用顺序为父主类->子主类->先编译的分类->后编译的分类。

    - `+ (void)initialize` 方法：只有分类中的方法会被调用。

- 分类可以添加属性，但因为 `category_t` 结构体中并不存在成员变量，所以并不会自动生成成员变量及 set/get 方法。成员变量是存放在实例对象中的，并且编译的那一刻就已经决定好了，而分类是在运行时才去加载的，无法在程序运行时将分类的成员变量中添加到实例对象的结构体中。

  - 编译后的类已经注册在 Runtime 中，类结构体中的 objc_ivar_list 实例变量的链表和 instance_size 实例变量的内存大小已经确定，同时 Runtime 会调用 `class_setIvarLayout` 和 `class_setWeakIvarLayout` 来处理 strong 和 weak 引用。
  
  - 可以借助**关联对象**来实现：

  ```objective-c
  @interface NSObject (AssociatedObject)
  @property (nonatomic, strong) id associatedObject;
  @end
  @implementation NSObject (AssociatedObject)
  @dynamic associatedObject;
  //设置
  - (void)setAssociatedObject:(id)object {
       objc_setAssociatedObject(self, @selector(associatedObject), object, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  }
  //获取
  - (id)associatedObject {
      return objc_getAssociatedObject(self, @selector(associatedObject));
  }
  ```

  - 内存管理策略：
  
    - ` OBJC_ASSOCIATION_ASSIGN = 0` = `@property (assign)` /`@property (unsafe_unretained)`
    
    - `OBJC_ASSOCIATION_RETAIN_NONATOMIC = 1`  = `@property (nonatomic, strong)`
    
    - `OBJC_ASSOCIATION_COPY_NONATOMIC = 3` = `@property (nonatomic, copy)`
    
    - `OBJC_ASSOCIATION_RETAIN = 01401` = `@property (atomic, strong)`
    
    - `OBJC_ASSOCIATION_COPY = 01403`  = `@property (atomic, copy)`

  - 关联对象并不是放在了原来的对象里面，而是维护了一个全局的 map 用来存放每一个对象及其对应关联属性表格。

- 扩展 Extension 和 分类 Category 的区别：

  - Category 原则上只能增加方法；Extension 不仅可以增加方法，还可以增加实例变量或者属性（默认是 @private 类型的，作用范围只能在自身类，而不是子类或其他地方）；
  
  - Extension 中声明的方法没被实现，编译器会警告；Category 中的方法没被实现编译器是不会有任何警告的。这是因为类扩展是在编译阶段被添加到类中，而类别是在运行时添加到类中。

## 方法交换 Method swizzling

- **Method swizzling 的原理是改变在方法映射表中 `SEL` 与 `IMP` 的对应关系。**

  ```objective-c
  + (void)load {
      //保证只swizzling一次
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
  
  - (void)st_originalMethod {
      // 执行被替换方法
      [self st_originalMethod];
      NSLog(@"st_originalMethod");
  }
  ```

- **swizzling 应该只在 `+load` 中完成**。

  - 在 Objective-C 的运行时中，每个类有两个方法都会自动调用。`+load` 是在一个类被初始装载时调用，`+initialize` 是在应用第一次调用该类的类方法或实例方法前调用的，是懒加载的；
  
  - 子类、父类和分类中的 `+load` 方法的实现是被区别对待的，即分类中的 `+load` 方法并不会对主类中的 `+load` 方法造成覆盖。

- **swizzling 应该只在 dispatch_once 中完成**。

  -  确保代码只会被执行一次。

## 消息转发

- Objective-C 的方法调用都是类似 `[receiver selector]` 的形式，是一个运行时消息发送过程：

    - 第一步：**编译阶段**
      `[receiver selector]` 方法被编译器转化为 `objc_msgSend(id _Nullable self, SEL _Nonnull op, ...)`。

      > 消息发送的方法还有 `objc_msgSendSuper` （发送给父类）、`objc_msgSend_stret` （返回值为结构体），`objc_msgSendSuper_stret`（发送给父类，返回值为结构体） 等。

    - 第二步：**运行时阶段**
    
      - 检测 selector 是不是要忽略；
      
      - 检测 target 是不是 nil；
      
      - 按 **cache -> methodLists -> 父类的 cache -> 父类的 methodLists** 的顺序查找对应的 IMP，找到就进行方法执行。
    > 说明：编译阶段确定了要向哪个接收者发送消息，而运行时阶段决定了接收者如何响应消息。

- **当对象无法响应消息，即未查找到消息的 IMP 时，该消息的 IMP 会统一指向 `_objc_msgForward`，由此启动启动消息转发的流程：**

    1. **消息动态解析**
    2. **消息接收者重定向（快速转发）**
    3. **消息重定向（完整转发）**

    ![](/Users/3kmac/Desktop/我的文档/图片/消息转发流程.png)

- **消息动态解析**：动态添加方法，以处理这条消息。

    ```objective-c
    // 实例方法
    + (BOOL)resolveInstanceMethod:(SEL)sel {
        if (sel == @selector(instanceMethod:)) {
            // 动态增加实例方法
            SEL addSel = @selector(myInstanceMethod:);
            IMP imp = class_getMethodImplementation(self.class, addSel);
            Method method = class_getInstanceMethod(self.class, addSel);
            const char *types = method_getTypeEncoding(method);
            class_addMethod(self.class, sel, imp, types);
            
            return YES;
        }
        
        return [class_getSuperclass(self) resolveInstanceMethod:sel];
    }
    
    // 动态增加的方法
    - (void)myInstanceMethod:(NSString *)string {
        NSLog(@"myInstanceMethod = %@", string);
    }
    ```

- **消息接收者重定向**：让其他接收者处理这条消息。

    ```objective-c
    - (id)forwardingTargetForSelector:(SEL)sel {
        if (sel == @selector(instanceMethod:)) {
            // 将消息转给STHelp对象来执行，STHelp已实现instanceMethod:方法
            STHelp *help = [[STHelp alloc] init];
            return help;
        }
        
        return [super forwardingTargetForSelector:sel];
    }
    ```

- **消息重定向**：

    - 获取方法签名 `NSMethodSignature`，封装方法的返回值类型信息以及参数类型信息；
    
    - 利用 `NSMethodSignature` 对象中的信息，封装成 `NSInvocation` 对象，包含保存了方法所属的对象、方法名称、参数和返回值等。

    ```objective-c
    - (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {  
        if(sel == @selector(instanceMethod:)) {
            // 获取方法签名，如STHelp未实现instanceMethod:则返回nil
            NSMethodSignature *signature = [STHelp instanceMethodSignatureForSelector:sel];
            if (signature ) {
          	    return signature;
            }
        }
        
        return [super methodSignatureForSelector:sel];
    }
    
    - (void)forwardInvocation:(NSInvocation *)invocation {
        SEL sel = invocation.selector;
        if(sel == @selector(instanceMethod:)) {
            STHelp *help = [[STHelp alloc] init];
            // 方法执行
            [invocation invokeWithTarget:help];
          
            // 可转发给多个对象
            STHelp *help1 = [[STHelp alloc] init];
            [invocation invokeWithTarget:help1];
          	// 不做处理，抛出异常
          	//[self doesNotRecognizeSelector:invocation.selector];
        }
        else {
            [super forwardInvocation:invocation];
        }
    }
    ```

    > 接收者重定向 `forwardingTargetForSelector` 只能将消息转发给一个对象。
    >
    > 消息重定向 `forwardInvocation` 可以将消息同时转发给任意多个对象，实现类似**多继承**或者**转发中心**的功能。

- 以上都是针对实例方法的消息转发，当处理类方法时，对应的系统函数依次为：

    ```objective-c
    + (BOOL)resolveClassMethod:(SEL)sel;
    + (id)forwardingTargetForSelector:(SEL)sel;
    + (NSMethodSignature *)methodSignatureForSelector:(SEL)sel
    + (void)forwardInvocation:(NSInvocation *)invocation
    ```

## AOP工具——Aspects

- AOP编程（面向切面编程） 是带有一定侵入性的编程方式，**可以通过预编译方式和运行期动态代理实现在不修改源代码的情况下给程序动态统一添加功能的一种技术**。

- Aspects 是利用消息转发机制实现方法交换的工具。

  - 新建一个 `aspects_originalSelector` 指向原来的 `originalSelector` 的方法实现；
  
  - 原来的 `originalSelector` 指向 `_objc_msgForward` 的方法实现；
  
  - 侵入方法实现在 `__ASPECTS_ARE_BEING_CALLED__` 中，原来的 `forwardInvacation` 指向 `__ASPECTS_ARE_BEING_CALLED__`。

  - 调用过程：`originalSelector` -> `_objc_msgForward` -> `forwardInvacation` -> `__ASPECTS_ARE_BEING_CALLED__`。



