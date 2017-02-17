//
//  UIView+Additions.m
//  ZPCamera
//
//  Created by luoo on 17/2/5.
//  Copyright © 2017年 陈浩. All rights reserved.
//

#import "UIView+Additions.h"

@implementation UIView (Additions)

- (UIImage *)screenShotWithRect:(CGRect)aRect {
    CGFloat scale = 4;
    if (IS_IPHONE_4) {
        scale = 3;
    }
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(ScreenWidth*scale, scale*ScreenHeight), YES, scale);
    
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    CGImageRef imageRef = viewImage.CGImage;
    
    CGRect rect = CGRectMake(aRect.origin.x, aRect.origin.y*scale, aRect.size.width*scale, aRect.size.height*scale);//这里可以设置想要截图的区域
    //        CGRect rect = aRect;
    CGImageRef imageRefRect =CGImageCreateWithImageInRect(imageRef, rect);
    UIImage *sendImage = [[UIImage alloc] initWithCGImage:imageRefRect];
    
    CGImageRelease(imageRefRect);
    
    return sendImage;
}


@end
