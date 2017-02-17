//
//  UIView+frameAdjust.h
//  UU
//
//  Created by 陈浩 on 16/5/21.
//  Copyright © 2016年 陈浩. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (frameAdjust)

- (CGFloat)x;
- (void)setX:(CGFloat)x;

- (CGFloat)y;
- (void)setY:(CGFloat)y;

- (CGFloat)height;
- (void)setHeight:(CGFloat)height;

- (CGFloat)width;
- (void)setWidth:(CGFloat)width;

- (CGFloat)centerX;
- (void)setCenterX:(CGFloat)centerX;

- (CGFloat)centerY;
- (void)setCenterY:(CGFloat)centerY;

@end
