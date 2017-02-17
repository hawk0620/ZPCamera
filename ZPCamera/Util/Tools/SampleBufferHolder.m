#import "SampleBufferHolder.h"

@implementation SampleBufferHolder

- (void)dealloc {
    if (_sampleBuffer != nil) {
        CFRelease(_sampleBuffer);
    }
}

- (void)setSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    if (_sampleBuffer != nil) {
        CFRelease(_sampleBuffer);
        _sampleBuffer = nil;
    }
    
    _sampleBuffer = sampleBuffer;
    
    if (sampleBuffer != nil) {
        CFRetain(sampleBuffer);
    }
}

+ (SampleBufferHolder *)sampleBufferHolderWithSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    SampleBufferHolder *sampleBufferHolder = [SampleBufferHolder new];
    
    sampleBufferHolder.sampleBuffer = sampleBuffer;
    
    return sampleBufferHolder;
}

@end
