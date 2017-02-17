//
//  NSDictionary+NSKit.h
//  Kind6Lib
//
//  Created by 陈浩 on 15/6/11.
//  Copyright (c) 2015年 陈浩. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (NSKit)

- (NSArray *)arrayForKey:(NSString *)key;

- (NSDictionary *)dictionaryForKey:(NSString *)key;

- (NSString *)stringForKey:(NSString *)key;

- (NSNumber *)numberForKey:(NSString *)key;

@end
