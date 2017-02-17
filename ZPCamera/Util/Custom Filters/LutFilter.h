//
//  LutFilter.h
//  ZPCamera
//
//  Created by luoo on 17/1/24.
//  Copyright © 2017年 陈浩. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GLFilter1 : GPUImageTwoInputFilter



@end


@interface LutFilter : GPUImageFilterGroup
{
    GPUImagePicture *imageSource ;
}

- (id)initWithImage:(UIImage *)image_;

@end
