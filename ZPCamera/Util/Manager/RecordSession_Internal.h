#import "RecordSession.h"
#import "VideoConfiguration.h"
#import "AudioConfiguration.h"
@class RecoderManager;

@interface RecordSession() {
    AVAssetWriter *_assetWriter;
    AVAssetWriterInput *_videoInput;
    AVAssetWriterInput *_audioInput;
    NSMutableArray *_segments;
    BOOL _audioInitializationFailed;
    BOOL _videoInitializationFailed;
    BOOL _recordSegmentReady;
    BOOL _currentSegmentHasVideo;
    BOOL _currentSegmentHasAudio;
    
    int _currentSegmentCount;
    CMTime _timeOffset;
    CMTime _lastTimeAudio;
    CMTime _currentSegmentDuration;
    CMTime _sessionStartTime;
    
    VideoConfiguration *_videoConfiguration;
    AudioConfiguration *_audioConfiguration;
    
    AVAssetWriterInputPixelBufferAdaptor *_videoPixelBufferAdaptor;
    CMTime _lastTimeVideo;
    
    dispatch_queue_t _audioQueue;
    
    // Used when the fastRecordMethod is enabled
    AVCaptureMovieFileOutput *_movieFileOutput;
}

@property (weak, nonatomic) RecoderManager *recorder;

@property (readonly, nonatomic) BOOL videoInitialized;
@property (readonly, nonatomic) BOOL audioInitialized;
@property (readonly, nonatomic) BOOL videoInitializationFailed;
@property (readonly, nonatomic) BOOL audioInitializationFailed;
@property (readonly, nonatomic) BOOL recordSegmentReady;
@property (readonly, nonatomic) BOOL currentSegmentHasAudio;
@property (readonly, nonatomic) BOOL currentSegmentHasVideo;
@property (readonly, nonatomic) BOOL isUsingMovieFileOutput;

- (void)initializeVideo:(NSDictionary *)videoOptions formatDescription:(CMFormatDescriptionRef)formatDescription error:(NSError **)error;
- (void)initializeAudio:(NSDictionary *)audioOptions formatDescription:(CMFormatDescriptionRef)formatDescription error:(NSError **)error;

- (CVPixelBufferRef)createPixelBuffer;

- (void)appendVideoPixelBuffer:(CVPixelBufferRef)videoSampleBuffer atTime:(CMTime)time duration:(CMTime)duration completion:(void(^)(BOOL success))completion;

- (void)appendAudioSampleBuffer:(CMSampleBufferRef)audioSampleBuffer completion:(void(^)(BOOL success))completion;


- (void)beginRecordSegmentUsingMovieFileOutput:(AVCaptureMovieFileOutput *)movieFileOutput error:(NSError **)error delegate:(id<AVCaptureFileOutputRecordingDelegate>)delegate;

- (void)notifyMovieFileOutputIsReady;

- (void)appendRecordSegmentUrl:(NSURL *)url info:(NSDictionary *)info error:(NSError *)error completionHandler:(void(^)(RecordSessionSegment *segment, NSError* error))completionHandler;

@end
