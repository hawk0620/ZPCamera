#import <GPUImage/GPUImage.h>
@class RecordSession;
@class VideoConfiguration;
@class AudioConfiguration;
@class FilterDisplayView;

@protocol RecoderManagerDelegate <NSObject>

- (void)didAppendVideoSampleBufferInSession:(RecordSession *__nullable)recordSession;
- (void) captureImageDidFinish:(UIImage *__nullable)image withMetadata:(NSDictionary *__nullable)metadata;
- (void) captureImageFailedWithError:(NSError *__nullable)error;
- (void)captureSessionDidStartRunning;

@end

@interface RecoderManager : GPUImageVideoCamera

@property (nonatomic, weak) FilterDisplayView *__nullable filterView;

@property (nonatomic, assign) NSInteger formatType;
@property (readonly, nonatomic) BOOL isRecording;
@property (assign, nonatomic) BOOL resetZoomOnChangeDevice;

@property (strong, nonatomic) NSString *__nullable filterName;
@property (strong, nonatomic) NSString *__nullable filterType;

@property (assign, nonatomic) BOOL initializeSessionLazily;
@property (assign, nonatomic) AVCaptureDevicePosition device;
@property (assign, nonatomic) BOOL autoSetVideoOrientation;
@property (assign, nonatomic) AVCaptureVideoOrientation videoOrientation;
@property (assign, nonatomic) CMTime maxRecordDuration;
@property (assign, nonatomic) CGFloat videoZoomFactor;

@property (readonly, nonatomic) dispatch_queue_t __nonnull sessionQueue;
@property (strong, nonatomic) RecordSession *__nullable session;

@property (readonly, nonatomic) BOOL videoEnabledAndReady;
@property (readonly, nonatomic) BOOL audioEnabledAndReady;

@property (readonly, nonatomic) VideoConfiguration  * __nonnull videoConfiguration;
@property (readonly, nonatomic) AudioConfiguration *__nonnull audioConfiguration;

@property (strong, nonatomic) AVCaptureAudioDataOutput *__nullable gpuAudioOutput;
@property (strong, nonatomic) AVCaptureDeviceInput *__nullable gpuVideoInput;

@property (weak, nonatomic) id<RecoderManagerDelegate> __nullable recoderManagerDelegate;

- (void)record;
- (void)pause;
- (void)pause:(void(^ __nullable)())completionHandler;
- (void)captureImageForDeviceOrientation:(UIDeviceOrientation)deviceOrientation;

+ (BOOL)isSessionQueue;

- (BOOL)hasMultipleCameras;

@end
