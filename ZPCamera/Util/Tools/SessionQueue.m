#import "SessionQueue.h"

@implementation SessionQueue

+ (instancetype)sharedInstance {
    static SessionQueue *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SessionQueue alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    if (self = [super init]) {
        _sessionQueue = dispatch_queue_create("com.ZPCamera.RecordSession", nil);
        dispatch_queue_set_specific(_sessionQueue, kRecorderRecordSessionQueueKey, "true", nil);
        dispatch_set_target_queue(_sessionQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
    }
    
    return self;
}

@end
