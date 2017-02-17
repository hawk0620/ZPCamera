//
//  AVCaptureVideoDataOutput+Additions.m
//  ZPCamera
//
//  Created by 陈浩 on 2017/1/25.
//  Copyright © 2017年 陈浩. All rights reserved.
//

#import "AVCaptureVideoDataOutput+Additions.h"
#import "NSObject+Additions.h"
#import "SessionQueue.h"

@implementation AVCaptureVideoDataOutput (Additions)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self swizzleMethod:@selector(setSampleBufferDelegate:queue:) withMethod:@selector(own_setSampleBufferDelegate:queue:)];
    });
}

- (void)own_setSampleBufferDelegate:(id<AVCaptureVideoDataOutputSampleBufferDelegate>)sampleBufferDelegate queue:(dispatch_queue_t)sampleBufferCallbackQueue {
    [self own_setSampleBufferDelegate:sampleBufferDelegate queue:[SessionQueue sharedInstance].sessionQueue];
}

@end
