//
//  CameraDelegate.h
//  Pods
//
//  Created by 陈浩 on 15/7/1.
//
#import <AVFoundation/AVFoundation.h>

@protocol CameraViewDelegate <NSObject>
@optional
/**
 *  Send to the delegate the CGPoint to set the focus
 *
 *  @param camera The camera view
 *  @param point  The focus CGPoint
 */
- (void) cameraView:(UIView *)camera focusAtPoint:(CGPoint)point;

/**
 *  Send to the delegate the CGPoint to set the expose
 *
 *  @param camera The camera view
 *  @param point  The focus CGPoint
 */
- (void) cameraView:(UIView *)camera exposeAtPoint:(CGPoint)point;

/**
 *  Tells the delegate when the camera start recording
 */

- (void)togglePhoto;
- (void) cameraViewStartRecording;

- (void) cameraViewPauseRecording;

/**
 *  Tells the delegate when the camera must be closed
 */
- (void) closeCamera;

/**
 *  Tells the delegate when the camera switch front to back (and vice versa)
 */
- (void) switchCamera;

- (void)changeCapturePhoto;

- (void)changeCaptureVideo;

/**
 *  Tells the delegate the status of the flash
 *
 *  @param flashMode The AVCaptureFlashMode of the flash
 */
- (void) triggerFlashForMode:(AVCaptureFlashMode)flashMode;

/**
 *  Trigger action to show / hide the grid
 *
 *  @param camera The grid view
 *  @param show   BOOL value to show the grid
 */
- (void) cameraView:(UIView *)camera showGridView:(BOOL)show;

/**
 *  Tells the delegate when the Library picker must be opened
 */
- (void) openLibrary;

/**
 *  Check if the camera has the Focus
 *
 *  @return BOOL value if the camera has the focus
 */
- (BOOL) cameraViewHasFocus;

/**
 *  Set the capture manager scale
 *
 *  @param scaleNum The scale value for camera manager
 */
- (void) cameraCaptureScale:(CGFloat)scaleNum;

/**
 *  Get the value of max scale
 *
 *  @return The max scale value
 */
- (CGFloat) cameraMaxScale;


- (void)toStickerLibVC;

- (void)toCapture;

- (CGRect)filterViewDone:(NSInteger)index cellFrame:(CGRect)rect;

- (void)savePhoto;

- (void)deleteSegement;

- (BOOL)confirmDeleteSegement;

- (void)finishCapture;

@end


