#import <AVFoundation/AVFoundation.h>
#import "RecorderTools.h"
#define kFULL_HD (1920 x 1080)
#define kHD_READY (1280 x 720)

@implementation RecorderTools

+ (BOOL)formatInRange:(AVCaptureDeviceFormat*)format frameRate:(CMTimeScale)frameRate {
    CMVideoDimensions dimensions;
    dimensions.width = 0;
    dimensions.height = 0;
    
    return [RecorderTools formatInRange:format frameRate:frameRate dimensions:dimensions];
}

+ (BOOL)formatInRange:(AVCaptureDeviceFormat*)format frameRate:(CMTimeScale)frameRate dimensions:(CMVideoDimensions)dimensions {
    CMVideoDimensions size = CMVideoFormatDescriptionGetDimensions(format.formatDescription);
    
    if (size.width >= dimensions.width && size.height >= dimensions.height) {
        for (AVFrameRateRange *range in format.videoSupportedFrameRateRanges) {
            if (range.minFrameDuration.timescale >= frameRate && range.maxFrameDuration.timescale <= frameRate) {
                return YES;
            }
        }
    }
    
    return NO;
}

+ (CMTimeScale)maxFrameRateForFormat:(AVCaptureDeviceFormat *)format minFrameRate:(CMTimeScale)minFrameRate {
    CMTimeScale lowerTimeScale = 0;
    for (AVFrameRateRange *range in format.videoSupportedFrameRateRanges) {
        if (range.minFrameDuration.timescale >= minFrameRate && (lowerTimeScale == 0 || range.minFrameDuration.timescale < lowerTimeScale)) {
            lowerTimeScale = range.minFrameDuration.timescale;
        }
    }
    
    return lowerTimeScale;
}

+ (AVCaptureDevice *)videoDeviceForPosition:(AVCaptureDevicePosition)position {
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    for (AVCaptureDevice *device in videoDevices) {
        if (device.position == (AVCaptureDevicePosition)position) {
            return device;
        }
    }
    
    return nil;
}

+ (NSString *)captureSessionPresetForDimension:(CMVideoDimensions)videoDimension {
    if (videoDimension.width >= 1920 && videoDimension.height >= 1080) {
        return AVCaptureSessionPreset1920x1080;
    }
    if (videoDimension.width >= 1280 && videoDimension.height >= 720) {
        return AVCaptureSessionPreset1280x720;
    }
    if (videoDimension.width >= 960 && videoDimension.height >= 540) {
        return AVCaptureSessionPresetiFrame960x540;
    }
    if (videoDimension.width >= 640 && videoDimension.height >= 480) {
        return AVCaptureSessionPreset640x480;
    }
    if (videoDimension.width >= 352 && videoDimension.height >= 288) {
        return AVCaptureSessionPreset352x288;
    }
    
    return AVCaptureSessionPresetLow;
}

+ (NSString *)bestCaptureSessionPresetForDevicePosition:(AVCaptureDevicePosition)devicePosition withMaxSize:(CGSize)maxSize {
    return [RecorderTools bestCaptureSessionPresetForDevice:[RecorderTools videoDeviceForPosition:devicePosition] withMaxSize:maxSize];
}

+ (NSString *)bestCaptureSessionPresetForDevice:(AVCaptureDevice *)device withMaxSize:(CGSize)maxSize {
    CMVideoDimensions highestDeviceDimension;
    highestDeviceDimension.width = 0;
    highestDeviceDimension.height = 0;
    
    for (AVCaptureDeviceFormat *format in device.formats) {
        CMVideoDimensions dimension = CMVideoFormatDescriptionGetDimensions(format.formatDescription);
        
        if (dimension.width <= (int)maxSize.width && dimension.height <= (int)maxSize.height && dimension.width * dimension.height > highestDeviceDimension.width * highestDeviceDimension.height) {
            highestDeviceDimension = dimension;
        }
    }
    
    return [RecorderTools captureSessionPresetForDimension:highestDeviceDimension];
}

+ (NSString *)bestCaptureSessionPresetCompatibleWithAllDevices {
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];

    CMVideoDimensions highestCompatibleDimension;
    BOOL lowestSet = NO;
    
    for (AVCaptureDevice *device in videoDevices) {
        CMVideoDimensions highestDeviceDimension;
        highestDeviceDimension.width = 0;
        highestDeviceDimension.height = 0;
        
        for (AVCaptureDeviceFormat *format in device.formats) {
            CMVideoDimensions dimension = CMVideoFormatDescriptionGetDimensions(format.formatDescription);
            
            if (dimension.width * dimension.height > highestDeviceDimension.width * highestDeviceDimension.height) {
                highestDeviceDimension = dimension;
            }
        }
        
        if (!lowestSet || (highestCompatibleDimension.width * highestCompatibleDimension.height > highestDeviceDimension.width * highestDeviceDimension.height)) {
            lowestSet = YES;
            highestCompatibleDimension = highestDeviceDimension;
        }
        
    }

    return [RecorderTools captureSessionPresetForDimension:highestCompatibleDimension];
}

+ (NSArray *)assetWriterMetadata {
    AVMutableMetadataItem *creationDate = [AVMutableMetadataItem new];
    creationDate.keySpace = AVMetadataKeySpaceCommon;
    creationDate.key = AVMetadataCommonKeyCreationDate;
    creationDate.value = [[NSDate date] toISO8601];
    
    AVMutableMetadataItem *software = [AVMutableMetadataItem new];
    software.keySpace = AVMetadataKeySpaceCommon;
    software.key = AVMetadataCommonKeySoftware;
    software.value = @"SCRecorder";
    
    return @[software, creationDate];
}

@end

@implementation NSDate (RecorderTools)

+ (NSDateFormatter *)_getFormatter {
    static NSDateFormatter *dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        [dateFormatter setLocale:enUSPOSIXLocale];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];
    });

    return dateFormatter;
}

- (NSString*)toISO8601 {
    return [[NSDate _getFormatter] stringFromDate:self];
}

+ (NSDate *)fromISO8601:(NSString *)iso8601 {
    return [[NSDate _getFormatter] dateFromString:iso8601];
}

@end

