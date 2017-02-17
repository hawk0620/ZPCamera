//
//  NSObject+Additions.m
//  ZPCamera
//
//  Created by 陈浩 on 2017/1/25.
//  Copyright © 2017年 陈浩. All rights reserved.
//

#import "NSObject+Additions.h"
#import "objc/runtime.h"

@implementation NSObject (Additions)

+ (BOOL)swizzleMethod:(SEL)originalSelector withMethod:(SEL)swizzledSelector {
    Method originalMethod = class_getInstanceMethod(self, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(self, swizzledSelector);
    if (!originalMethod || !swizzledMethod) {
        return NO;
    }
    
    BOOL needAddMethod = class_addMethod(self, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
    
    if (needAddMethod) {
        class_replaceMethod(self, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
    
    return YES;
}

@end
