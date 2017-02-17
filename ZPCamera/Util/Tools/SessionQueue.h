#import <Foundation/Foundation.h>

@interface SessionQueue : NSObject

@property (readonly, nonatomic) dispatch_queue_t __nonnull sessionQueue;

+ (instancetype __nonnull)sharedInstance;

@end
