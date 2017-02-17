//
//  NSDictionary+NSKit.m
//  Kind6Lib
//
//  Created by 陈浩 on 15/6/11.
//  Copyright (c) 2015年 陈浩. All rights reserved.
//

#import "NSDictionary+NSKit.h"
#import "NSString+NSKit.h"

@implementation NSDictionary (NSKit)

- (NSArray *)arrayForKey:(NSString *)key
{
    return [self objectForKey:key verifyClass:[NSArray class]];
}

- (NSDictionary *)dictionaryForKey:(NSString *)key
{
    return [self objectForKey:key verifyClass:[NSDictionary class]];
}

- (NSString *)stringForKey:(NSString *)key
{
    return [self objectForKey:key verifyClass:[NSString class]];
}

- (NSNumber *)numberForKey:(NSString *)key
{
    id object = [self objectForKey:key];
    if ([object isKindOfClass:[NSString class]])
    {
        return [NSString stringToNumber:key];
    }else
    {
        return [self objectForKey:key verifyClass:[NSNumber class]];
    }
    
}

#pragma mark - Private

- (id)objectForKey:(NSString *)key verifyClass:(__unsafe_unretained Class)aClass
{
    id object = [self objectForKey:key];
    if ([object isKindOfClass:aClass]) {
        return object;
    }
    else if([object isKindOfClass:[NSString class]] && [aClass isSubclassOfClass:[NSNumber class]])
    {
        //如果要求的是NSNumber，传递过来的值是NSString. 做特殊转换
        return [NSNumber numberWithInt:[object intValue]];
    }
    else if ([object isKindOfClass:[NSNumber class]] && [aClass isSubclassOfClass:[NSString class]])
    {
        return [NSString stringWithFormat:@"%d", [object intValue]];
    }
    
    return [aClass new];
}

@end
