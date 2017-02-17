#import "FilterDisplayView.h"
#import <objc/runtime.h>
#import "GPUImageFramebuffer+Additions.h"

@implementation FilterDisplayView {
    
    CVPixelBufferRef renderTarget;
    GLfloat imageVertices[8];
}

- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex;
{
    @weakify(self)
    runSynchronouslyOnVideoProcessingQueue(^{
        @strongify(self)
        [GPUImageContext setActiveShaderProgram:self.gpuDisplayProgram];
        
        SEL selector = NSSelectorFromString(@"setDisplayFramebuffer");
        if ([self respondsToSelector:selector]) {
            ((void (*)(id, SEL))[self methodForSelector:selector])(self, selector);
        }
        
        SEL s = NSSelectorFromString(@"textureCoordinatesForRotation:");
        IMP imp = [[GPUImageView class] methodForSelector:s];
        GLfloat *(*func)(id, SEL, GPUImageRotationMode) = (void *)imp;
        GLfloat *result = [GPUImageView class] ? func([GPUImageView class], s, inputRotation) : nil;
        
        glClearColor(self.gpuBackgroundColorRed, self.gpuBackgroundColorGreen, self.gpuBackgroundColorBlue, self.gpuBackgroundColorAlpha);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        
        glActiveTexture(GL_TEXTURE4);
        glBindTexture(GL_TEXTURE_2D, [self.gpuInputFramebufferForDisplay texture]);
        glUniform1i(self.gpuDisplayInputTextureUniform, 4);
        
        glVertexAttribPointer(self.gpuDisplayPositionAttribute, 2, GL_FLOAT, 0, 0, imageVertices);
        glVertexAttribPointer(self.gpuDisplayTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0,
                              result);
        
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        
        SEL s2 = NSSelectorFromString(@"presentFramebuffer");
        if ([self respondsToSelector:s2]) {
            ((void (*)(id, SEL))[self methodForSelector:s2])(self, s2);
        }
        
//        if (self.isRecording) {
        
        int width = self.gpuInputFramebufferForDisplay.size.width;//_sizeInPixels.width;
        int height = self.gpuInputFramebufferForDisplay.size.height;//_sizeInPixels.height;
        
        renderTarget = self.gpuInputFramebufferForDisplay.gpuBufferRef;
        
        NSUInteger paddedWidthOfImage = CVPixelBufferGetBytesPerRow(renderTarget) / 4.0;
        NSUInteger paddedBytesForImage = paddedWidthOfImage * (int)height * 4;
        
        //            NSInteger dataLength = width * height * 4;
        
        glFinish();
        //        CFRetain(renderTarget);
        CVPixelBufferLockBaseAddress(renderTarget, 0);
        GLubyte *data = (GLubyte *)CVPixelBufferGetBaseAddress(renderTarget);
        //                    GLubyte *data = (GLubyte*)malloc(dataLength * sizeof(GLubyte));
        
        //                    glPixelStorei(GL_PACK_ALIGNMENT, 4);
        //                    glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, data);
        
        CGDataProviderRef ref = CGDataProviderCreateWithData(NULL, data, paddedBytesForImage, NULL);
        
        CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
        //                    CGImageRef iref = CGImageCreate(width, height, 8, 32, width * 4, colorspace, kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast,
        //                                                    ref, NULL, true, kCGRenderingIntentDefault);
        CGImageRef iref = CGImageCreate((int)width, (int)height, 8, 32, CVPixelBufferGetBytesPerRow(renderTarget), colorspace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst, ref, NULL, NO, kCGRenderingIntentDefault);
        
        UIGraphicsBeginImageContext(CGSizeMake(height, width));
        CGContextRef cgcontext = UIGraphicsGetCurrentContext();
        
        CGAffineTransform transform = CGAffineTransformIdentity;
        transform = CGAffineTransformMakeTranslation(height / 2.0, width / 2.0);
                transform = CGAffineTransformRotate(transform, M_PI_2);
        transform = CGAffineTransformScale(transform, 1.0, -1.0);
        //        transform = CGAffineTransformMake(1, 0, 0, -1, 0, height);
        
        CGContextConcatCTM(cgcontext, transform);
        
        CGContextSetBlendMode(cgcontext, kCGBlendModeCopy);
        CGContextDrawImage(cgcontext, CGRectMake(-width / 2, -height / 2, width, height), iref);
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        self.img = image;
        
        
        //                    free(data);
        CFRelease(ref);
        CFRelease(colorspace);
        CGImageRelease(iref);
        CVPixelBufferUnlockBaseAddress(renderTarget, 0);
//        }
        
        
        [self.gpuInputFramebufferForDisplay unlock];
        self.gpuInputFramebufferForDisplay = nil;
    });
}

- (void)recalculateViewGeometry;
{
    runSynchronouslyOnVideoProcessingQueue(^{
        CGFloat heightScaling, widthScaling;
        
        CGSize currentViewSize = self.bounds.size;
        
        //    CGFloat imageAspectRatio = inputImageSize.width / inputImageSize.height;
        //    CGFloat viewAspectRatio = currentViewSize.width / currentViewSize.height;
        
        CGRect insetRect = AVMakeRectWithAspectRatioInsideRect(self.gpuInputImageSize, self.bounds);
        
        switch(self.fillMode)
        {
            case kGPUImageFillModeStretch:
            {
                widthScaling = 1.0;
                heightScaling = 1.0;
            }; break;
            case kGPUImageFillModePreserveAspectRatio:
            {
                widthScaling = insetRect.size.width / currentViewSize.width;
                heightScaling = insetRect.size.height / currentViewSize.height;
            }; break;
            case kGPUImageFillModePreserveAspectRatioAndFill:
            {
                //            CGFloat widthHolder = insetRect.size.width / currentViewSize.width;
                widthScaling = currentViewSize.height / insetRect.size.height;
                heightScaling = currentViewSize.width / insetRect.size.width;
            }; break;
        }
        
        imageVertices[0] = -widthScaling;
        imageVertices[1] = -heightScaling;
        imageVertices[2] = widthScaling;
        imageVertices[3] = -heightScaling;
        imageVertices[4] = -widthScaling;
        imageVertices[5] = heightScaling;
        imageVertices[6] = widthScaling;
        imageVertices[7] = heightScaling;
    });
    
    //    static const GLfloat imageVertices[] = {
    //        -1.0f, -1.0f,
    //        1.0f, -1.0f,
    //        -1.0f,  1.0f,
    //        1.0f,  1.0f,
    //    };
}

- (GLint)gpuDisplayInputTextureUniform {
    Ivar var = class_getInstanceVariable([super class], "displayInputTextureUniform");
    ptrdiff_t offset = ivar_getOffset(var);
    unsigned char* bytes = (unsigned char *)(__bridge void*)self;
    GLint intValue = *((GLint *)(bytes+offset));
    return intValue;
}

- (GLfloat)gpuBackgroundColorRed {
    Ivar var = class_getInstanceVariable([super class], "backgroundColorRed");
    ptrdiff_t offset = ivar_getOffset(var);
    unsigned char* bytes = (unsigned char *)(__bridge void*)self;
    GLfloat floatValue = *((GLfloat *)(bytes+offset));
    return floatValue;
}

- (GLfloat)gpuBackgroundColorBlue {
    Ivar var = class_getInstanceVariable([super class], "backgroundColorBlue");
    ptrdiff_t offset = ivar_getOffset(var);
    unsigned char* bytes = (unsigned char *)(__bridge void*)self;
    GLfloat floatValue = *((GLfloat *)(bytes+offset));
    return floatValue;
}

- (GLfloat)gpuBackgroundColorGreen {
    Ivar var = class_getInstanceVariable([super class], "backgroundColorGreen");
    ptrdiff_t offset = ivar_getOffset(var);
    unsigned char* bytes = (unsigned char *)(__bridge void*)self;
    GLfloat floatValue = *((GLfloat *)(bytes+offset));
    return floatValue;
}

- (GLfloat)gpuBackgroundColorAlpha {
    Ivar var = class_getInstanceVariable([super class], "backgroundColorAlpha");
    ptrdiff_t offset = ivar_getOffset(var);
    unsigned char* bytes = (unsigned char *)(__bridge void*)self;
    GLfloat floatValue = *((GLfloat *)(bytes+offset));
    return floatValue;
}

- (GPUImageFramebuffer *)gpuInputFramebufferForDisplay {
    Ivar var = class_getInstanceVariable([super class], "inputFramebufferForDisplay");
    id nameVar = object_getIvar(self, var);
    return nameVar;
}

- (GLint)gpuDisplayPositionAttribute {
    Ivar var = class_getInstanceVariable([super class], "displayPositionAttribute");
    ptrdiff_t offset = ivar_getOffset(var);
    unsigned char* bytes = (unsigned char *)(__bridge void*)self;
    GLint intValue = *((GLint *)(bytes+offset));
    return intValue;
}

- (GLint)gpuDisplayTextureCoordinateAttribute {
    Ivar var = class_getInstanceVariable([super class], "displayTextureCoordinateAttribute");
    ptrdiff_t offset = ivar_getOffset(var);
    unsigned char* bytes = (unsigned char *)(__bridge void*)self;
    GLint intValue = *((GLint *)(bytes+offset));
    return intValue;
}

- (GLProgram *)gpuDisplayProgram {
    Ivar var = class_getInstanceVariable([super class], "displayProgram");
    id nameVar = object_getIvar(self, var);
    return nameVar;
}

- (CGSize)gpuInputImageSize {
    Ivar var = class_getInstanceVariable([super class], "inputImageSize");
    ptrdiff_t offset = ivar_getOffset(var);
    unsigned char* bytes = (unsigned char *)(__bridge void*)self;
    CGSize size = *((CGSize *)(bytes+offset));
    return size;
}


@end
