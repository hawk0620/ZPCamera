#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
@import UIKit;

@interface CameraHelper : NSObject

+ (BOOL)checkAVAuthorizationStatus;

+ (BOOL)checkRecordPermission;

+ (BOOL)checkPhotoLibrary;

+ (AVCaptureFlashMode)updateFlashState:(NSUInteger)flashState flashButton:(UIButton *)flashBtn;

+ (void)updateScaleState:(NSUInteger)scaleState scaleButton:(UIButton *)scaleButton;

@end
