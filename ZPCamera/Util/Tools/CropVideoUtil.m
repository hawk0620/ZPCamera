#import "CropVideoUtil.h"

@implementation CropVideoUtil

+ (void)cropPureVideoWithURL:(AVAsset *)asset scaleType:(NSInteger)scaleType completeBlock:(MergeCompleteBlock)block {
    NSString* docFolder = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString* outputPath = [docFolder stringByAppendingPathComponent:@"pureVideo.mp4"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:outputPath])
        [[NSFileManager defaultManager] removeItemAtPath:outputPath error:nil];
    
    UIImageOrientation videoOrientation = UIImageOrientationDown;//[self getVideoOrientationFromAsset:asset];
    // input clip
    AVAssetTrack *clipVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo]objectAtIndex:0];
    
    
    // make it square
    AVMutableVideoComposition* videoComposition = [AVMutableVideoComposition videoComposition];
//    videoComposition.renderSize = CGSizeMake(clipVideoTrack.naturalSize.height, clipVideoTrack.naturalSize.height);
    videoComposition.frameDuration = CMTimeMake(1, 30);
    
    AVMutableVideoCompositionInstruction *instruction =[AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(60, 30) );
    
    // rotate to portrait
    AVMutableVideoCompositionLayerInstruction* transformer =[AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:clipVideoTrack];
//    CGAffineTransform t1 = CGAffineTransformMakeTranslation(0,-80);
    //    CGAffineTransform t2 = CGAffineTransformRotate(t1, M_PI_2);
    
    CGRect cropRect = CGRectZero;
    CGSize naturalSize = CGSizeMake(clipVideoTrack.naturalSize.height, clipVideoTrack.naturalSize.width);
    
    if (scaleType == 1) {
        cropRect = CGRectMake(0, 0, naturalSize.width, naturalSize.width);
    } else if (scaleType == 2) {
        cropRect = CGRectMake(0, 0, naturalSize.width, naturalSize.height);
    } else if (scaleType == 0) {
        CGFloat height = 0;
        if (IS_IPHONE_4) {
            height = (ScreenWidth * (4 / 3.0)) * (4 / 3.0);
        } else {
            height = naturalSize.height * (3.0 / 4.0);
        }
        
        cropRect = CGRectMake(0, 0, naturalSize.width, height);
    };
    
    CGFloat cropOffX = cropRect.origin.x;
    CGFloat cropOffY = cropRect.origin.y;
    CGFloat cropWidth = cropRect.size.width;
    CGFloat cropHeight = cropRect.size.height;
    videoComposition.renderSize = CGSizeMake(cropWidth, cropHeight);
    
    CGAffineTransform t1 = CGAffineTransformIdentity;
    CGAffineTransform t2 = CGAffineTransformIdentity;
    
    switch (videoOrientation) {
        case UIImageOrientationUp:
            t1 = CGAffineTransformMakeTranslation(naturalSize.height - cropOffX, 0 - cropOffY );
            t2 = CGAffineTransformRotate(t1, M_PI_2 );
            break;
        case UIImageOrientationDown:
            t1 = CGAffineTransformMakeTranslation(0 - cropOffX, naturalSize.height - cropOffY ); // not fixed width is the real height in upside down
            t2 = CGAffineTransformRotate(t1, - M_PI_2 );
            break;
        case UIImageOrientationRight:
            t1 = CGAffineTransformMakeTranslation(0 - cropOffY, 0 - cropOffX );
            t2 = CGAffineTransformRotate(t1, 0 );
            break;
        case UIImageOrientationLeft:
            t1 = CGAffineTransformMakeTranslation(naturalSize.width - cropOffX, naturalSize.height - cropOffY );
            t2 = CGAffineTransformRotate(t1, M_PI );
            break;
        default:
            NSLog(@"no supported orientation has been found in this video");
            break;
    }
    
    CGAffineTransform finalTransform = t2;
    [transformer setTransform:finalTransform atTime:kCMTimeZero];
    instruction.layerInstructions = [NSArray arrayWithObject:transformer];
    videoComposition.instructions = [NSArray arrayWithObject: instruction];
    
    NSURL *outputURL = [NSURL fileURLWithPath:outputPath];
    
    // export
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetHighestQuality];
    exporter.videoComposition = videoComposition;
    exporter.outputURL=outputURL;
    exporter.outputFileType=AVFileTypeQuickTimeMovie;
    
    [exporter exportAsynchronouslyWithCompletionHandler:^(void){
        if (exporter.status == AVAssetExportSessionStatusCompleted) {
            block(outputPath);
        } else {
            block(@"");
        }
    }];
}

+ (UIImageOrientation)getVideoOrientationFromAsset:(AVAsset *)asset
{
    AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    CGSize size = [videoTrack naturalSize];
    CGAffineTransform txf = [videoTrack preferredTransform];
    
    if (size.width == txf.tx && size.height == txf.ty)
        return UIImageOrientationLeft; //return UIInterfaceOrientationLandscapeLeft;
    else if (txf.tx == 0 && txf.ty == 0)
        return UIImageOrientationRight; //return UIInterfaceOrientationLandscapeRight;
    else if (txf.tx == 0 && txf.ty == size.width)
        return UIImageOrientationDown; //return UIInterfaceOrientationPortraitUpsideDown;
    else
        return UIImageOrientationUp;  //return UIInterfaceOrientationPortrait;
}

@end
