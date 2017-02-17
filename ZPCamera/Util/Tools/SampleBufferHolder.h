#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface SampleBufferHolder : NSObject

@property (assign, nonatomic) CMSampleBufferRef sampleBuffer;

+ (SampleBufferHolder *)sampleBufferHolderWithSampleBuffer:(CMSampleBufferRef)sampleBuffer;

@end
