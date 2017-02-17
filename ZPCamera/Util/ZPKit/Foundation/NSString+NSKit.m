//
//  NSString+NSKit.m
//  Kind6Lib
//
//  Created by 陈浩 on 15/6/11.
//  Copyright (c) 2015年 陈浩. All rights reserved.
//

#import "NSString+NSKit.h"

@implementation NSString (NSKit)

+ (NSNumber *)stringToNumber:(NSString *)numberString {
    
    if (!numberString) {
        return [NSNumber numberWithInt:0];
    }
    
    NSString *value = numberString;
    if (![numberString isKindOfClass:[NSString class]]) {
        value = [numberString description];
    }
    
    if ([value isEqualToString:@""]) {
        
        return [NSNumber numberWithInt:0];
    }else{
        
        NSNumberFormatter *fmt = [[NSNumberFormatter alloc] init];
        [fmt setNumberStyle:NSNumberFormatterDecimalStyle];
        NSNumber * myNumber = [fmt numberFromString:value];
        return myNumber;
    }
}

@end
