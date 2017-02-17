//
//  UIImage+Resize.h
//  Weshot
//
//  Created by weshot.cc on 14/12/14.
//  Copyright (c) 2014年 weshot.cc. All rights reserved.
//

@import UIKit;

@interface UIImage (Resize)

+ (UIImage *)getSubImage:(UIImage *) image;
+ (UIImage *)fixOrientation:(UIImage *)srcImg;



- (UIImage *)croppedImage:(CGRect)bounds;
- (UIImage *)thumbnailImage:(NSInteger)thumbnailSize
          transparentBorder:(NSUInteger)borderSize
               cornerRadius:(NSUInteger)cornerRadius
       interpolationQuality:(CGInterpolationQuality)quality;
- (UIImage *)resizedImage:(CGSize)newSize
     interpolationQuality:(CGInterpolationQuality)quality;
- (UIImage *)resizedImageWithContentMode:(UIViewContentMode)contentMode
                                  bounds:(CGSize)bounds
                    interpolationQuality:(CGInterpolationQuality)quality;

@end
