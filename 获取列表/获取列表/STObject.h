//
//  STObject.h
//  Runtime类与对象
//
//  Created by stone on 16/8/22.
//  Copyright © 2016年 duoyi. All rights reserved.
//

#import "STObjectSuper.h"

@protocol STObjectDelegate

@end

@interface STObject : STObjectSuper

@property (nonatomic, copy) NSString *name;

@property (nonatomic, strong) NSArray *list;

//@property (nonatomic, weak) id <STObjectDelegate> delegate;

- (void)test;

@end

