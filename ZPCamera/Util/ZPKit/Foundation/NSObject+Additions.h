//
//  NSObject+Additions.h
//  ZPCamera
//
//  Created by 陈浩 on 2017/1/25.
//  Copyright © 2017年 陈浩. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (Additions)

+ (BOOL)swizzleMethod:(SEL)originalSelector withMethod:(SEL)swizzledSelector;

@end
