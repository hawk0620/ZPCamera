#import "CameraHelper.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface CameraHelper () <UIAlertViewDelegate>

@end

@implementation CameraHelper

+ (BOOL)checkAVAuthorizationStatus {
    BOOL flag;
    if (NSFoundationVersionNumber >= NSFoundationVersionNumber_iOS_7_0) {
        AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        
        if (status == AVAuthorizationStatusDenied || status == AVAuthorizationStatusRestricted) {
            flag = NO;
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:@"请在“系统设置-隐私-照相”中开启 Osho 相机权限"
                                  message:@""
                                  delegate:self
                                  cancelButtonTitle:@"确定"
                                  otherButtonTitles:nil];
            alert.tag = 233333;
            [alert show];
            
            return flag;
        } else if (status == AVAuthorizationStatusNotDetermined) {
            flag = NO;
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:nil];
            
            return flag;
        } else {
            flag = YES;
            return flag;
        }
    }
    
    return NO;
}

+ (BOOL)checkRecordPermission {
    if (NSFoundationVersionNumber >= NSFoundationVersionNumber_iOS_7_0) {
        AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
        if (status == AVAuthorizationStatusDenied || status == AVAuthorizationStatusRestricted) {
            
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:@"请在“系统设置-隐私-麦克风”中开启 Osho 麦克风权限"
                                  message:@""
                                  delegate:self
                                  cancelButtonTitle:@"确定"
                                  otherButtonTitles:nil];
            alert.tag = 233333;
            [alert show];
            
            return NO;
        } else if (status == AVAuthorizationStatusNotDetermined) {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:nil];
            
            return NO;
        } else {
            return YES;
        }
    }
    return NO;
}

+ (BOOL)checkPhotoLibrary {
    ALAuthorizationStatus status = [ALAssetsLibrary authorizationStatus];
    BOOL flag = YES;
    
    if (status == ALAuthorizationStatusDenied || status == ALAuthorizationStatusRestricted) {
        flag = NO;
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"请在“系统设置-隐私-相册”中开启 Osho 相册权限"
                              message:@""
                              delegate:self
                              cancelButtonTitle:@"确定"
                              otherButtonTitles:nil];
        alert.tag = 233333;
        [alert show];
    } else if (status == ALAuthorizationStatusAuthorized) {
        flag = YES;
    }
    return flag;
}

+ (AVCaptureFlashMode)updateFlashState:(NSUInteger)flashState flashButton:(UIButton *)flashBtn {
    if (flashState == 1) {
        UIImage *image;
        image = [UIImage imageNamed:@"Flashlight_On"];
        [flashBtn setImage:image forState:UIControlStateNormal];
        return AVCaptureFlashModeOn;
    } else if (flashState == 2) {
        UIImage *image;
        image = [UIImage imageNamed:@"Flashlight_Off"];
        [flashBtn setImage:image forState:UIControlStateNormal];
        return AVCaptureFlashModeOff;
    } else if (flashState == 0) {
        UIImage *image;
        image = [UIImage imageNamed:@"Flashlight_Auto"];
        [flashBtn setImage:image forState:UIControlStateNormal];
        return AVCaptureFlashModeAuto;
    }
    return AVCaptureFlashModeAuto;
    
}

+ (void)updateScaleState:(NSUInteger)scaleState scaleButton:(UIButton *)scaleButton {
    if (scaleState == 1) {
        [scaleButton setTitle:@"1:1" forState:UIControlStateNormal];
    } else if (scaleState == 2) {
        [scaleButton setTitle:@"16:9" forState:UIControlStateNormal];
    } else if (scaleState == 0) {
        [scaleButton setTitle:@"4:3" forState:UIControlStateNormal];
    }
}

+ (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 233333)
    {
        NSURL *settings = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        if ([[UIApplication sharedApplication] canOpenURL:settings]) {
            [[UIApplication sharedApplication] openURL:settings];
        }
    }
}

@end
