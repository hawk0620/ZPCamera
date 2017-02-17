#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface CropVideoUtil : NSObject

+ (void)cropPureVideoWithURL:(AVAsset *)asset scaleType:(NSInteger)scaleType completeBlock:(MergeCompleteBlock)block;

@end
