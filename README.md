
# ZPCamera
[![Build Status](https://travis-ci.org/irshadpc/ZPCamera.svg?branch=master)](https://travis-ci.org/irshadpc/ZPCamera)

An OpenSource Camera App.

# Introduction

Osho camera is my independent development of a camera App, App Store Address: point me. It supports 1: 1, 4: 3, 16: 9 multi-resolution shooting, the filter can be in the viewfinder real-time preview, the shooting process can be synthesized with the filter in real time, support for sub-shooting, support back delete and other features. The following share to share the development of this App some experience, the end of the article will give the project download address, reading this article may need a little bit AVFoundation development basis.

![Screenshot](https://github.com/irshadpc/ZPCamera/blob/master/3921d0ea-f561-11e6-92c2-ffc308d26460.jpeg?raw=true)

# 1, GLKView and GPUImageVideoCamera

The beginning of the frame view is based on GLKView, GLKView is Apple's encapsulation of OpenGL, we can use its callback function -glkView: drawInRect: done on the processed samplebuffer rendered work (samplebuffer is generated in the camera callback didOutputSampleBuffer Of the original version of the code:

```
- (CIImage *)renderImageInRect:(CGRect)rect {
    CMSampleBufferRef sampleBuffer = _sampleBufferHolder.sampleBuffer;

    if (sampleBuffer != nil) {
        UIImage *originImage = [self imageFromSamplePlanerPixelBuffer:sampleBuffer];
        if (originImage) {
           if (self.filterName && self.filterName.length > 0) {

               GPUImageOutput<GPUImageInput> *filter;
                if ([self.filterType isEqual: @"1"]) {
                    Class class = NSClassFromString(self.filterName);
                    filter = [[class alloc] init];
                } else {
                    NSBundle *bundle = [NSBundle bundleForClass:self.class];
                    NSURL *filterAmaro = [NSURL fileURLWithPath:[bundle pathForResource:self.filterName ofType:@"acv"]];
                    filter = [[GPUImageToneCurveFilter alloc] initWithACVURL:filterAmaro];
                }
                [filter forceProcessingAtSize:originImage.size];
                GPUImagePicture *pic = [[GPUImagePicture alloc] initWithImage:originImage];
                [pic addTarget:filter];
                [filter useNextFrameForImageCapture];
                [filter addTarget:self.gpuImageView];
                [pic processImage];              
                UIImage *filterImage = [filter imageFromCurrentFramebuffer];
                //UIImage *filterImage = [filter imageByFilteringImage:originImage];

                _CIImage = [[CIImage alloc] initWithCGImage:filterImage.CGImage options:nil];
            } else {
            _CIImage = [CIImage imageWithCVPixelBuffer:CMSampleBufferGetImageBuffer(sampleBuffer)];
        }
    }  
    CIImage *image = _CIImage;

    if (image != nil) {
        image = [image imageByApplyingTransform:self.preferredCIImageTransform];
        if (self.scaleAndResizeCIImageAutomatically) {
           image = [self scaleAndResizeCIImage:image forRect:rect];
        }
    }

    return image;
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    @autoreleasepool {
        rect = CGRectMultiply(rect, self.contentScaleFactor);
        glClearColor(0, 0, 0, 0);
        glClear(GL_COLOR_BUFFER_BIT);
        CIImage *image = [self renderImageInRect:rect];
        if (image != nil) {
            [_context.CIContext drawImage:image inRect:rect fromRect:image.extent];
        }
    }
}
```

This is achieved in the low-end machine frame will have a clear cardton, and ViewController on the list almost impossible to slide, although the gesture is also able to support. Because in order to achieve the sub-shot and delete delete and other functions, in this way the original intention is to expect a higher degree of customization, rather than to use GPUImageVideoCamera, after all, I have AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate these two callbacks to make an article, in order to meet the demand, So do not invade the GPUImage source code under the premise of kung fu.

How can we not destroy the GPUImageVideoCamera code? I think of two methods, the first is to create a class, and then copy the code in the GPUImageVideoCamera over, so simple and crude, the drawback is that if the future GPUImage upgrade, the code is a small disaster to maintain; then talk about the second method - inheritance, inheritance is a very elegant behavior, but its trouble is to get less than the private variables, but fortunately there is a powerful runtime, to solve this difficult problem. The following is the use of runtime to obtain private variables

```
- (AVCaptureAudioDataOutput *)gpuAudioOutput {
    Ivar var = class_getInstanceVariable([super class], "audioOutput");
    id nameVar = object_getIvar(self, var);
    return nameVar;
}
```

At this point the frame to achieve the rendering of the filter and to ensure that the list of sliding frame rate.

# 2, Real-time synthesis and GPUImage outputImageOrientation

As the name implies, the outputImageOrientation property is related to the orientation of the image. GPUImage this property is the different equipment in the viewfinder frame image direction is optimized, but this optimization will conflict with the videoOrientation, it will lead to switch the camera lead to image orientation is wrong, but also cause the video after shooting the wrong direction. The final solution is to make sure that the image output by the camera is oriented correctly, so set it to UIInterfaceOrientationPortrait instead of setting videoOrientation. The rest of the problem is how to handle the direction of the video after the shooting is complete.

First look at the real-time video synthesis, because it contains the user synthesis of CVPixelBufferRef resource processing. Or inherit GPUImageView using inheritance, which uses the runtime call private method:

```
SEL s = NSSelectorFromString(@"textureCoordinatesForRotation:");
IMP imp = [[GPUImageView class] methodForSelector:s];
GLfloat *(*func)(id, SEL, GPUImageRotationMode) = (void *)imp;
GLfloat *result = [GPUImageView class] ? func([GPUImageView class], s, inputRotation) : nil;
glVertexAttribPointer(self.gpuDisplayTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, result);
```

Go straight to the focus - CVPixelBufferRef processing, will renderTarget converted to CGImageRef object, and then use UIGraphics get CGAffineTransform processed UIImage direction, this time UIImage direction is not the normal direction, but rotated over 90 degrees of the picture, so do The purpose is to videoInput the transform attribute foreshadowed. Here is the processing code for CVPixelBufferRef:

```
int width = self.gpuInputFramebufferForDisplay.size.width;
int height = self.gpuInputFramebufferForDisplay.size.height;

renderTarget = self.gpuInputFramebufferForDisplay.gpuBufferRef;

NSUInteger paddedWidthOfImage = CVPixelBufferGetBytesPerRow(renderTarget) / 4.0;
NSUInteger paddedBytesForImage = paddedWidthOfImage * (int)height * 4;

glFinish();
CVPixelBufferLockBaseAddress(renderTarget, 0);
GLubyte *data = (GLubyte *)CVPixelBufferGetBaseAddress(renderTarget);
CGDataProviderRef ref = CGDataProviderCreateWithData(NULL, data, paddedBytesForImage, NULL);
CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
CGImageRef iref = CGImageCreate((int)width, (int)height, 8, 32, CVPixelBufferGetBytesPerRow(renderTarget), colorspace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst, ref, NULL, NO, kCGRenderingIntentDefault);

UIGraphicsBeginImageContext(CGSizeMake(height, width));
CGContextRef cgcontext = UIGraphicsGetCurrentContext();
CGAffineTransform transform = CGAffineTransformIdentity;
transform = CGAffineTransformMakeTranslation(height / 2.0, width / 2.0);
transform = CGAffineTransformRotate(transform, M_PI_2);
transform = CGAffineTransformScale(transform, 1.0, -1.0);
CGContextConcatCTM(cgcontext, transform);

CGContextSetBlendMode(cgcontext, kCGBlendModeCopy);
CGContextDrawImage(cgcontext, CGRectMake(0.0, 0.0, width, height), iref);
UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
UIGraphicsEndImageContext();
self.img = image;

CFRelease(ref);
CFRelease(colorspace);
CGImageRelease(iref);
CVPixelBufferUnlockBaseAddress(renderTarget, 0);
```

The videoInput transform property is set as follows:

```
_videoInput.transform = CGAffineTransformRotate(_videoConfiguration.affineTransform, -M_PI_2);
```
After these two directions of processing, the synthesis of small video finally the direction of normal. Here is the simplified version of the synthetic video code:

```
CIImage *image = [[CIImage alloc] initWithCGImage:img.CGImage options:nil];
CVPixelBufferLockBaseAddress(pixelBuffer, 0);
[self.context.CIContext render:image toCVPixelBuffer:pixelBuffer];
[_videoPixelBufferAdaptor appendPixelBuffer:pixelBuffer withPresentationTime:bufferTimestamp]
```

You can see the key point is still inherited from the GPUImageView this class to get the renderTarget attribute, it should be the viewfinder real-time preview of the results, I used in the initial synthesis is to use sampleBuffer UIImage, and then through the GPUImage add filters, and finally Will UIImage then CIImage, doing so will lead to shooting when the card. At that time I almost want to give up, and even want to take a good shot after the way to filter around, and finally these are not pure methods have been ban ban.

Since the filter can render in the viewfinder in real time, I think GPUImageView may be expected. After reading a lot of GPUImage source, finally in the GPUImageFramebuffer.m found a property called renderTarget. At this point, the synthesis of the function also come to an end.

# 3, On the filter

Here to share an interesting process. App has three types of filters. Based on glsl, direct use of acv as well as direct use of lookuptable. Lookuptable fact photoshop can also be exported to a picture, but the general software will be its encryption, the following simple mention how I decompile the "borrow" a part of the filter software it. Use the Hopper Disassembler software to decompile, and then through some keyword search, lucky to find a method name of the following figure.

## License

Release under the [MIT License](https://github.com/irshadpc/ZPCamera/blob/master/LICENSE).
