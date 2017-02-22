#import "RecoderManager.h"
#import <objc/runtime.h>
#import "RecordSession.h"
#import "RecordSession_Internal.h"
#import "VideoConfiguration.h"
#import "AudioConfiguration.h"
#import "SampleBufferHolder.h"
#import "RecorderTools.h"
#import "SessionQueue.h"
#import "FilterDisplayView.h"
#import "FilterGenerator.h"

#import "SCContext.h"

#define kMinTimeBetweenAppend 0.004

static char* FocusContext = "FocusContext";
static char* ExposureContext = "ExposureContext";

@interface RecoderManager ()

@property (strong, nonatomic) AVCaptureVideoPreviewLayer *previewLayer;
@property (assign, nonatomic) SCContextType contextType;
@property (strong, nonatomic) AVCaptureStillImageOutput *stillImageOutput;
@property (strong, nonatomic) SCContext *context;
@property (strong, nonatomic) SampleBufferHolder *lastAudioBuffer;

@end

@implementation RecoderManager {
    BOOL _adjustingFocus;
    BOOL _shouldAutoresumeRecording;
    double _lastAppendedVideoTime;
    BOOL requiresFrontCameraTextureCacheCorruptionWorkaround;
    BOOL needsContinuousFocus;
}

static CGContextRef CreateContextFromPixelBuffer(CVPixelBufferRef pixelBuffer) {
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipFirst;
    
    CGContextRef ctx = CGBitmapContextCreate(CVPixelBufferGetBaseAddress(pixelBuffer), CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer), 8, CVPixelBufferGetBytesPerRow(pixelBuffer), colorSpace, bitmapInfo);
    
    CGColorSpaceRelease(colorSpace);
    
    CGContextTranslateCTM(ctx, 1, CGBitmapContextGetHeight(ctx));
    CGContextScaleCTM(ctx, 1, -1);
    
    return ctx;
}

- (id)initWithSessionPreset:(NSString *)sessionPreset cameraPosition:(AVCaptureDevicePosition)cameraPosition {
    if (self = [super initWithSessionPreset:sessionPreset cameraPosition:cameraPosition]) {
        _sessionQueue = [SessionQueue sharedInstance].sessionQueue;
        
        _initializeSessionLazily = YES;
        _resetZoomOnChangeDevice = YES;
        _maxRecordDuration = kCMTimeInvalid;
//        self.device = AVCaptureDevicePositionBack;
//        _lastVideoBuffer = [SampleBufferHolder new];
        _lastAudioBuffer = [SampleBufferHolder new];
        
        _contextType = SCContextTypeAuto;
        [self setupContextIfNeeded];
        
        _videoConfiguration = [VideoConfiguration new];
        _audioConfiguration = [AudioConfiguration new];
        
//        [_videoConfiguration addObserver:self forKeyPath:@"enabled" options:NSKeyValueObservingOptionNew context:SCRecorderVideoEnabledContext];
//        [_audioConfiguration addObserver:self forKeyPath:@"enabled" options:NSKeyValueObservingOptionNew context:SCRecorderAudioEnabledContext];
        
//#pragma clang diagnostic push
//#pragma clang diagnostic ignored "-Wdeprecated-declarations"
//        requiresFrontCameraTextureCacheCorruptionWorkaround = [[[UIDevice currentDevice] systemVersion] compare:@"6.0" options:NSNumericSearch] == NSOrderedAscending;
//#pragma clang diagnostic pop
        
        [self addAudioInputsAndOutputs];
        
        [self reconfigureVideoInput:YES audioInput:YES];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector( captureSessionDidStartRunning: ) name:AVCaptureSessionDidStartRunningNotification object:_captureSession];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionInterrupted:) name:AVAudioSessionInterruptionNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionRuntimeError:) name:AVCaptureSessionRuntimeErrorNotification object:self];
        [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(subjectAreaDidChange) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:nil];
        
        _stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
        
//        if (captureAsYUV && [GPUImageContext supportsFastTextureUpload])
//        {
//            BOOL supportsFullYUVRange = NO;
//            NSArray *supportedPixelFormats = videoOutput.availableVideoCVPixelFormatTypes;
//            for (NSNumber *currentPixelFormat in supportedPixelFormats)
//            {
//                if ([currentPixelFormat intValue] == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
//                {
//                    supportsFullYUVRange = YES;
//                }
//            }
//            
//            if (supportsFullYUVRange)
//            {
//                _formatType = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
////                [_stillImageOutput setOutputSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
//            }
//            else
//            {
//                _formatType = kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange;
////                [_stillImageOutput setOutputSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
//            }
//        }
//        else
//        {
//            _formatType = kCVPixelFormatType_32BGRA;
////            [_stillImageOutput setOutputSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
//        }
        
        //[videoOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
        //[self setGpuIsFullYUVRange];
        //captureAsYUV = NO;
        
        
        [_stillImageOutput setOutputSettings:@{ AVVideoCodecKey : AVVideoCodecJPEG }];
        if ( [_captureSession canAddOutput:_stillImageOutput] ) {
            [_captureSession addOutput:_stillImageOutput];
        }
        
        _previewLayer = [[AVCaptureVideoPreviewLayer alloc] init];
        _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        _previewLayer.session = _captureSession;
        _previewLayer.frame = ScreenBounds;
        
        if ( [_previewLayer respondsToSelector:@selector(connection)] ) {
            if ( [_previewLayer.connection isVideoOrientationSupported] )
                [_previewLayer.connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
        }
    }
    return self;
}

- (void)applicationDidEnterBackground:(id)sender {
    _shouldAutoresumeRecording = _isRecording;
    [self pause];
}

- (void)applicationDidBecomeActive:(id)sender {
    [self reconfigureVideoInput:self.videoConfiguration.enabled audioInput:self.audioConfiguration.enabled];
    
    if (_shouldAutoresumeRecording) {
        _shouldAutoresumeRecording = NO;
        [self record];
    }
}

- (void)sessionInterrupted:(NSNotification *)notification {
    NSNumber *interruption = [notification.userInfo objectForKey:AVAudioSessionInterruptionOptionKey];
    
    if (interruption != nil) {
        AVAudioSessionInterruptionOptions options = interruption.unsignedIntValue;
        if (options == AVAudioSessionInterruptionOptionShouldResume) {
            [self reconfigureVideoInput:NO audioInput:self.audioConfiguration.enabled];
        }
    }
}

- (void)sessionRuntimeError:(id)sender {
    if (!_captureSession.isRunning) {
        [_captureSession startRunning];
    }
}

- (void)subjectAreaDidChange {
    [self focusCenter];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (_captureSession != nil) {
        for (AVCaptureDeviceInput *input in _captureSession.inputs) {
            [_captureSession removeInput:input];
            if ([input.device hasMediaType:AVMediaTypeVideo]) {
                [self removeVideoObservers:input.device];
            }
        }
        for (AVCaptureOutput *output in _captureSession.outputs) {
            [_captureSession removeOutput:output];
        }
        _previewLayer.session = nil;
        _captureSession = nil;
    }
}

- (void)setupContextIfNeeded {
    SCContextType contextType = self.contextType;
    if (contextType == SCContextTypeAuto) {
        contextType = [SCContext suggestedContextType];
    }
    CGContextRef cgContext = nil;
    NSDictionary *options = nil;
    if (contextType == SCContextTypeCoreGraphics) {
        CVPixelBufferRef pixelBuffer = nil;
        
        cgContext = CreateContextFromPixelBuffer(pixelBuffer);
        options = @{
                    SCContextOptionsCGContextKey: (__bridge id)cgContext
                    };
    }
    
    self.context = [SCContext contextWithType:self.contextType options:options];
    
    if (cgContext != nil) {
        CGContextRelease(cgContext);
    }
}

- (void)setSession:(RecordSession *)recordSession {
    if (_session != recordSession) {
        dispatch_sync(_sessionQueue, ^{
            _session.recorder = nil;
            
            _session = recordSession;
            
            recordSession.recorder = self;
        });
    }
}

- (void)record {
    void (^block)() = ^{
        _isRecording = YES;
        self.filterView.isRecording = YES;
    };
    
    if ([RecoderManager isSessionQueue]) {
        block();
    } else {
        dispatch_sync(_sessionQueue, block);
    }
}

- (void)pause {
    [self pause:nil];
}

- (void)pause:(void(^)())completionHandler {
    _isRecording = NO;
    self.filterView.isRecording = NO;
    
    void (^block)() = ^{
        RecordSession *recordSession = _session;
        
        if (recordSession != nil) {
            if (recordSession.recordSegmentReady) {
                NSDictionary *info = nil;//[self _createSegmentInfo];
                if (recordSession.isUsingMovieFileOutput) {
                } else {
                    [recordSession endSegmentWithInfo:info completionHandler:^(RecordSessionSegment *segment, NSError *error) {
                        if (completionHandler != nil) {
                            completionHandler();
                        }
                    }];
                }
            } else {
                dispatch_handler(completionHandler);
            }
        } else {
            dispatch_handler(completionHandler);
        }
    };
    
    if ([RecoderManager isSessionQueue]) {
        block();
    } else {
        dispatch_async(_sessionQueue, block);
    }
}

- (void)beginRecordSegmentIfNeeded:(RecordSession *)recordSession {
    if (!recordSession.recordSegmentBegan) {
        NSError *error = nil;
        BOOL beginSegment = YES;
        [recordSession beginSegment:&error];
        
        if (beginSegment) {
            NSLog(@"didBeginSegmentInSession");
        }
    }
}

- (AVCaptureDeviceInput*)currentAudioDeviceInput {
    return [self currentDeviceInputForMediaType:AVMediaTypeAudio];
}

- (AVCaptureDeviceInput*)currentVideoDeviceInput {
    return [self currentDeviceInputForMediaType:AVMediaTypeVideo];
}

- (AVCaptureDeviceInput*)currentDeviceInputForMediaType:(NSString*)mediaType {
    for (AVCaptureDeviceInput* deviceInput in _captureSession.inputs) {
        if ([deviceInput.device hasMediaType:mediaType]) {
            return deviceInput;
        }
    }
    
    return nil;
}

- (CMTime)frameDurationFromConnection:(AVCaptureConnection *)connection {
    AVCaptureDevice *device = [self currentVideoDeviceInput].device;
    
    if ([device respondsToSelector:@selector(activeVideoMaxFrameDuration)]) {
        return device.activeVideoMinFrameDuration;
    }
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return connection.videoMinFrameDuration;
#pragma clang diagnostic pop
}

- (void)checkRecordSessionDuration:(RecordSession *)recordSession {
    CMTime currentRecordDuration = recordSession.duration;
    CMTime suggestedMaxRecordDuration = _maxRecordDuration;
    
    if (CMTIME_IS_VALID(suggestedMaxRecordDuration)) {
        if (CMTIME_COMPARE_INLINE(currentRecordDuration, >=, suggestedMaxRecordDuration)) {
            _isRecording = NO;
            self.filterView.isRecording = NO;
            
            dispatch_async(_sessionQueue, ^{
                [recordSession endSegmentWithInfo:nil completionHandler:^(RecordSessionSegment *segment, NSError *error) {
                }];
            });
        }
    }
}

- (void)appendVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer toRecordSession:(RecordSession *)recordSession duration:(CMTime)duration connection:(AVCaptureConnection *)connection completion:(void(^)(BOOL success))completion {
    
    @autoreleasepool {
        CMTime time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
        
        CVPixelBufferRef pixelBuffer = [recordSession createPixelBuffer];
        
        if (pixelBuffer == nil) {
            completion(NO);
            return;
        }
        
        UIImage *img = self.filterView.img;
        if (!img.CGImage) {
            return;
        }
        
        CIImage *image = [[CIImage alloc] initWithCGImage:img.CGImage options:nil];
        
        CVPixelBufferLockBaseAddress(pixelBuffer, 0);
        
        [self.context.CIContext render:image toCVPixelBuffer:pixelBuffer];
        
        [recordSession appendVideoPixelBuffer:pixelBuffer atTime:time duration:duration completion:^(BOOL success) {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
            CVPixelBufferRelease(pixelBuffer);
            
            completion(success);
        }];

    }
    
}

- (void)_handleVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer withSession:(RecordSession *)recordSession connection:(AVCaptureConnection *)connection {
    if (!recordSession.videoInitializationFailed && !_videoConfiguration.shouldIgnore) {
        if (!recordSession.videoInitialized) {
            NSError *error = nil;
            NSDictionary *settings = [self.videoConfiguration createAssetWriterOptionsUsingSampleBuffer:sampleBuffer];
            
            CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
            [recordSession initializeVideo:settings formatDescription:formatDescription error:&error];
            NSLog(@"INITIALIZED VIDEO");
        }
        
        if (!self.audioEnabledAndReady || recordSession.audioInitialized || recordSession.audioInitializationFailed) {
            [self beginRecordSegmentIfNeeded:recordSession];
            
            if (_isRecording && recordSession.recordSegmentReady) {
                CMTime duration = [self frameDurationFromConnection:connection];
                
                double timeToWait = kMinTimeBetweenAppend - (CACurrentMediaTime() - _lastAppendedVideoTime);
                
                if (timeToWait > 0) {
                    [NSThread sleepForTimeInterval:timeToWait];
                }
                BOOL isFirstVideoBuffer = !recordSession.currentSegmentHasVideo;
                [self appendVideoSampleBuffer:sampleBuffer toRecordSession:recordSession duration:duration connection:connection completion:^(BOOL success) {
                    _lastAppendedVideoTime = CACurrentMediaTime();
                    if (success) {
                        if (self.recoderManagerDelegate && [self.recoderManagerDelegate respondsToSelector:@selector(didAppendVideoSampleBufferInSession:)]) {
                            [self.recoderManagerDelegate didAppendVideoSampleBufferInSession:recordSession];
                        }
                        
                        [self checkRecordSessionDuration:recordSession];
                    } else {
                    }
                }];
                
                if (isFirstVideoBuffer && !recordSession.currentSegmentHasAudio) {
                    CMSampleBufferRef audioBuffer = self.lastAudioBuffer.sampleBuffer;
                    if (audioBuffer != nil) {
                        CMTime lastAudioEndTime = CMTimeAdd(CMSampleBufferGetPresentationTimeStamp(audioBuffer), CMSampleBufferGetDuration(audioBuffer));
                        CMTime videoStartTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
                        // If the end time of the last audio buffer is after this video buffer, we need to re-use it,
                        // since it was skipped on the last cycle to wait until the video becomes ready.
                        if (CMTIME_COMPARE_INLINE(lastAudioEndTime, >, videoStartTime)) {
                            [self _handleAudioSampleBuffer:audioBuffer withSession:recordSession];
                        }
                    }
                }
            }
        } else {
        }
    }
}

- (void)_handleAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer withSession:(RecordSession *)recordSession {
    if (!recordSession.audioInitializationFailed && !_audioConfiguration.shouldIgnore) {
        if (!recordSession.audioInitialized) {
            NSError *error = nil;
            NSDictionary *settings = [self.audioConfiguration createAssetWriterOptionsUsingSampleBuffer:sampleBuffer];
            CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
            [recordSession initializeAudio:settings formatDescription:formatDescription error:&error];
            NSLog(@"INITIALIZED AUDIO");
        }
        
        if (!self.videoEnabledAndReady || recordSession.videoInitialized || recordSession.videoInitializationFailed) {
            [self beginRecordSegmentIfNeeded:recordSession];
            
            if (_isRecording && recordSession.recordSegmentReady && (!self.videoEnabledAndReady || recordSession.currentSegmentHasVideo)) {
                [recordSession appendAudioSampleBuffer:sampleBuffer completion:^(BOOL success) {
                    if (success) {
                        [self checkRecordSessionDuration:recordSession];
                    } else {
                    }
                }];
            } else {
            }
        }
    }
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    [super captureOutput:captureOutput didOutputSampleBuffer:sampleBuffer fromConnection:connection];
    
    if (captureOutput == videoOutput) {
//        _lastVideoBuffer.sampleBuffer = sampleBuffer;
        if (_videoConfiguration.shouldIgnore) {
            return;
        }
        
    } else if (captureOutput == self.gpuAudioOutput) {
        self.lastAudioBuffer.sampleBuffer = sampleBuffer;
        
        if (_audioConfiguration.shouldIgnore) {
            return;
        }
    }
    
    if (!_initializeSessionLazily || _isRecording) {
        RecordSession *recordSession = _session;
        if (recordSession != nil) {
            if (captureOutput == videoOutput) {
                [self _handleVideoSampleBuffer:sampleBuffer withSession:recordSession connection:connection];
            } else if (captureOutput == self.gpuAudioOutput) {
                [self _handleAudioSampleBuffer:sampleBuffer withSession:recordSession];
            }
        }
    }
}

- (void)captureImageForDeviceOrientation:(UIDeviceOrientation)deviceOrientation {
    AVCaptureConnection *videoConnection = [_stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    if (!videoConnection) {
        NSError *error = [NSError errorWithDomain:@"ZPCamera" code:-1 userInfo:@{ NSLocalizedFailureReasonErrorKey : @"cameraimage.noconnection"}];
        
        if ([_recoderManagerDelegate respondsToSelector:@selector(captureImageFailedWithError:)]) {
            [_recoderManagerDelegate captureImageFailedWithError:error];
        }
        return;
    }
    
    if ( [videoConnection isVideoOrientationSupported] ) {
        switch (deviceOrientation) {
            case UIDeviceOrientationPortraitUpsideDown:
                [videoConnection setVideoOrientation:AVCaptureVideoOrientationPortraitUpsideDown];
                break;
                
            case UIDeviceOrientationLandscapeLeft:
                [videoConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
                break;
                
            case UIDeviceOrientationLandscapeRight:
                [videoConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
                break;
                
            default:
                [videoConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
                break;
        }
    }
    
    [videoConnection setVideoScaleAndCropFactor:1];
    
    __weak AVCaptureSession *captureSessionBlock = _captureSession;
    __weak id<RecoderManagerDelegate>delegateBlock = _recoderManagerDelegate;
    
    [_stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        [captureSessionBlock stopRunning];
        
        if ( imageDataSampleBuffer != NULL ) {
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            UIImage *image = [[UIImage alloc] initWithData:imageData];
            UIImage *newImage;
            BOOL isFront = NO;
            
            if (self.cameraPosition == AVCaptureDevicePositionFront) {
                isFront = YES;
                newImage = [UIImage imageWithCGImage:[image CGImage] scale:1 orientation:UIImageOrientationLeftMirrored];
               
                UIGraphicsBeginImageContextWithOptions(newImage.size, false, newImage.scale);
                [newImage drawInRect:(CGRect){0,0,newImage.size.width,newImage.size.height}];
                newImage = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
               
            } else {
                isFront = NO;
                newImage = [UIImage imageWithCGImage:[image CGImage] scale:1 orientation:[image imageOrientation]];
            }
            
            GPUImageOutput<GPUImageInput> *filter = [FilterGenerator generateFilterByName:self.filterName type:self.filterType];
            GPUImagePicture *pic = [[GPUImagePicture alloc] initWithImage:newImage];
            [pic addTarget:filter];
            
            [pic processImage];
            [filter useNextFrameForImageCapture];
            UIImage *colorBlendFilterImage;
            if (isFront) {
                colorBlendFilterImage = [filter imageFromCurrentFramebuffer];
            } else {
                colorBlendFilterImage = [filter imageFromCurrentFramebufferWithOrientation:[image imageOrientation]];
            }
            
            if ( [delegateBlock respondsToSelector:@selector(captureImageDidFinish:withMetadata:)] ) {
                [delegateBlock captureImageDidFinish:colorBlendFilterImage withMetadata:nil];
            }
           
        } else if ( error ) {
            if ( [delegateBlock respondsToSelector:@selector(captureImageFailedWithError:)] )
               [delegateBlock captureImageFailedWithError:error];
        }
    }];
}

- (void)setGpuIsFullYUVRange {
    Ivar var  = class_getInstanceVariable([self class], "isFullYUVRange");
    object_setIvar(self, var, @(NO));
}

- (AVCaptureAudioDataOutput *)gpuAudioOutput {
    Ivar var = class_getInstanceVariable([super class], "audioOutput");
    id nameVar = object_getIvar(self, var);
    return nameVar;
}

- (AVCaptureDeviceInput *)gpuVideoInput {
    Ivar var = class_getInstanceVariable([super class], "videoInput");
    id nameVar = object_getIvar(self, var);
    return nameVar;
}

- (AVCaptureDevice*)audioDevice {
    if (!self.audioConfiguration.enabled) {
        return nil;
    }
    
    return [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
}

- (AVCaptureDevice*)videoDevice {
    if (!self.videoConfiguration.enabled) {
        return nil;
    }
    
    return [RecorderTools videoDeviceForPosition:_device];
}

- (AVCaptureConnection*)videoConnection {
    for (AVCaptureConnection * connection in videoOutput.connections) {
        for (AVCaptureInputPort * port in connection.inputPorts) {
            if ([port.mediaType isEqual:AVMediaTypeVideo]) {
                return connection;
            }
        }
    }
    return nil;
}

- (void)configureVideoStabilization {
    AVCaptureConnection *videoConnection = [self videoConnection];
    if ([videoConnection isVideoStabilizationSupported]) {
        if ([videoConnection respondsToSelector:@selector(setPreferredVideoStabilizationMode:)]) {
            videoConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeStandard;
        }
    }
}

- (void)configureDevice:(AVCaptureDevice*)newDevice mediaType:(NSString*)mediaType error:(NSError**)error {
    AVCaptureDeviceInput *currentInput = [self currentDeviceInputForMediaType:mediaType];
    
    if (currentInput) {
        [self addVideoObservers:currentInput.device];
        [self configureVideoStabilization];
    }
}

- (void)reconfigureVideoInput:(BOOL)shouldConfigureVideo audioInput:(BOOL)shouldConfigureAudio {
    if (_captureSession != nil) {
        [_captureSession beginConfiguration];
        
        NSError *videoError = nil;
        if (shouldConfigureVideo) {
            [self configureDevice:[self videoDevice] mediaType:AVMediaTypeVideo error:&videoError];
        }
        
        if (shouldConfigureAudio) {
            [self audioDevice];
        }
        
        [_captureSession commitConfiguration];
    }
}

- (void)setDevice:(AVCaptureDevicePosition)device {
    [self willChangeValueForKey:@"device"];
    
    _device = device;
    if (_resetZoomOnChangeDevice) {
        self.videoZoomFactor = 1;
    }
    if (_captureSession != nil) {
        [self reconfigureVideoInput:self.videoConfiguration.enabled audioInput:NO];
    }
    
    [self didChangeValueForKey:@"device"];
}

- (CGFloat)videoZoomFactor {
    AVCaptureDevice *device = [self videoDevice];
    
    if ([device respondsToSelector:@selector(videoZoomFactor)]) {
        return device.videoZoomFactor;
    }
    
    return 1;
}

- (void)setVideoZoomFactor:(CGFloat)videoZoomFactor {
    AVCaptureDevice *device = [self videoDevice];
    
    if ([device respondsToSelector:@selector(videoZoomFactor)]) {
        NSError *error;
        if ([device lockForConfiguration:&error]) {
            if (videoZoomFactor <= device.activeFormat.videoMaxZoomFactor) {
                device.videoZoomFactor = videoZoomFactor;
            } else {
                NSLog(@"Unable to set videoZoom: (max %f, asked %f)", device.activeFormat.videoMaxZoomFactor, videoZoomFactor);
            }
            
            [device unlockForConfiguration];
        } else {
            NSLog(@"Unable to set videoZoom: %@", error.localizedDescription);
        }
    }
}

- (void)addVideoObservers:(AVCaptureDevice*)videoDevice {
    [videoDevice addObserver:self forKeyPath:@"adjustingFocus" options:NSKeyValueObservingOptionNew context:FocusContext];
    [videoDevice addObserver:self forKeyPath:@"adjustingExposure" options:NSKeyValueObservingOptionNew context:ExposureContext];
}

- (void)removeVideoObservers:(AVCaptureDevice*)videoDevice {
    [videoDevice removeObserver:self forKeyPath:@"adjustingFocus"];
    [videoDevice removeObserver:self forKeyPath:@"adjustingExposure"];
}

- (BOOL)audioEnabledAndReady {
    return !_audioConfiguration.shouldIgnore;
}

- (BOOL)videoEnabledAndReady {
    return !_videoConfiguration.shouldIgnore;
}

- (BOOL)isAdjustingFocus {
    return _adjustingFocus;
}

- (void)setAdjustingExposure:(BOOL)adjustingExposure {
    if (_isAdjustingExposure != adjustingExposure) {
        [self willChangeValueForKey:@"isAdjustingExposure"];
        _isAdjustingExposure = adjustingExposure;
        [self didChangeValueForKey:@"isAdjustingExposure"];
    }
}

- (void)setAdjustingFocus:(BOOL)adjustingFocus {
    if (_adjustingFocus != adjustingFocus) {
        [self willChangeValueForKey:@"isAdjustingFocus"];
        _adjustingFocus = adjustingFocus;
        [self didChangeValueForKey:@"isAdjustingFocus"];
    }
}

+ (BOOL)isSessionQueue {
    return dispatch_get_specific(kRecorderRecordSessionQueueKey) != nil;
}

- (void)captureSessionDidStartRunning:(NSNotification *)notification
{
    if ( [_recoderManagerDelegate respondsToSelector:@selector(captureSessionDidStartRunning)] )
        [_recoderManagerDelegate captureSessionDidStartRunning];
}

#pragma mark - Camera Support Method
- (BOOL)hasMultipleCameras {
    return [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count] > 1 ? YES : NO;
}

- (BOOL)hasFlash {
    return _gpuVideoInput.device.hasFlash;
}

- (BOOL)exposureSupported {
    return [self.currentVideoDeviceInput device].isExposurePointOfInterestSupported;
}

- (BOOL)focusSupported {
    return [self currentVideoDeviceInput].device.isFocusPointOfInterestSupported;
}

- (CGPoint)focusPointOfInterest {
    return [self.currentVideoDeviceInput device].focusPointOfInterest;
}

- (CGPoint)convertToPointOfInterestFromViewCoordinates:(CGPoint)viewCoordinates {
    return [self.previewLayer captureDevicePointOfInterestForPoint:viewCoordinates];
}

#pragma mark - Focus And Exposure
- (void)applyPoint:(CGPoint)point continuousMode:(BOOL)continuousMode {
    AVCaptureDevice *device = [self.currentVideoDeviceInput device];
    AVCaptureFocusMode focusMode = continuousMode ? AVCaptureFocusModeContinuousAutoFocus : AVCaptureFocusModeAutoFocus;
    AVCaptureExposureMode exposureMode = continuousMode ? AVCaptureExposureModeContinuousAutoExposure : AVCaptureExposureModeAutoExpose;
    AVCaptureWhiteBalanceMode whiteBalanceMode = continuousMode ? AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance : AVCaptureWhiteBalanceModeAutoWhiteBalance;
    
    NSError *error;
    if ([device lockForConfiguration:&error]) {
        BOOL focusing = NO;
        BOOL adjustingExposure = NO;
        
        if (device.isFocusPointOfInterestSupported) {
            device.focusPointOfInterest = point;
        }
        if ([device isFocusModeSupported:focusMode]) {
            device.focusMode = focusMode;
            focusing = YES;
        }
        
        if (device.isExposurePointOfInterestSupported) {
            device.exposurePointOfInterest = point;
        }
        
        if ([device isExposureModeSupported:exposureMode]) {
            device.exposureMode = exposureMode;
            adjustingExposure = YES;
        }
        
        if ([device isWhiteBalanceModeSupported:whiteBalanceMode]) {
            device.whiteBalanceMode = whiteBalanceMode;
        }
        
        device.subjectAreaChangeMonitoringEnabled = !continuousMode;
        
        [device unlockForConfiguration];
        
        if (focusMode != AVCaptureFocusModeContinuousAutoFocus && focusing) {
            [self setAdjustingFocus:YES];
        }
        
        if (exposureMode != AVCaptureExposureModeContinuousAutoExposure && adjustingExposure) {
            [self setAdjustingExposure:YES];
        }
    }
}

- (void)focusAtPoint:(CGPoint)point {
    [self applyPoint:point continuousMode:NO];
}

- (void)continuousFocusAtPoint:(CGPoint)point {
    [self applyPoint:point continuousMode:YES];
}

- (void)focusCenter {
    needsContinuousFocus = YES;
    [self focusAtPoint:CGPointMake(0.5, 0.5)];
}

- (void)focusDidComplete {
    [self setAdjustingFocus:NO];
    
    if (needsContinuousFocus) {
        needsContinuousFocus = NO;
        [self continuousFocusAtPoint:self.focusPointOfInterest];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == FocusContext) {
        BOOL isFocusing = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
        if (isFocusing) {
            [self setAdjustingFocus:YES];
        } else {
            [self focusDidComplete];
        }
    } else if (context == ExposureContext) {
        BOOL isAdjustingExposure = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
        
        [self setAdjustingExposure:isAdjustingExposure];
    }
}

@end
