//
//  GPUImageFramebuffer+Additions.h
//  ZPCamera
//
//  Created by 陈浩 on 2017/1/26.
//  Copyright © 2017年 陈浩. All rights reserved.
//

#import <GPUImage/GPUImage.h>

@interface GPUImageFramebuffer (Additions)

- (CVPixelBufferRef)gpuBufferRef;

@end
