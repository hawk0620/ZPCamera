//
//  GPUImageFramebuffer+Additions.m
//  ZPCamera
//
//  Created by 陈浩 on 2017/1/26.
//  Copyright © 2017年 陈浩. All rights reserved.
//

#import "GPUImageFramebuffer+Additions.h"
#import <objc/runtime.h>

@implementation GPUImageFramebuffer (Additions)

- (CVPixelBufferRef)gpuBufferRef {
    Ivar var = class_getInstanceVariable([super class], "renderTarget");
    
    ptrdiff_t offset = ivar_getOffset(var);
    unsigned char* bytes = (unsigned char *)(__bridge void*)self;
    CVPixelBufferRef bufferValue = *((CVPixelBufferRef *)(bytes+offset));
    return bufferValue;

}

@end
