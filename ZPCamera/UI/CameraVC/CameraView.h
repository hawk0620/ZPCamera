#import <UIKit/UIKit.h>
#import "CameraDelegate.h"

static inline CGFloat filterCellWidth () {
    if (IS_IPHONE_6P) {
        return 76.0;
    } else {
        return 64.0;
    }
}

@interface CameraView : UIView

@property (nonatomic, assign) AVCaptureFlashMode flashMode;
@property (nonatomic, assign) NSUInteger flashButtonState;
@property (nonatomic, assign) NSUInteger scaleButtonState;

@property (nonatomic, weak) id <CameraViewDelegate> delegate;

@property (nonatomic, strong) UIView *topContainerBar;
@property (nonatomic, strong) UIView *bottomContainerBar;

@property (nonatomic, strong) UIButton *triggerButton;
@property (nonatomic, strong) UIButton *cameraButton;
@property (nonatomic, strong) UIButton *flashButton;
@property (nonatomic, strong) UIButton *scaleButton;

@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, strong) UIButton *finishButton;

@property (nonatomic, strong) UIButton *cameraFilterButton;

@property (nonatomic, strong) UICollectionView *filterCollectionView;
@property (nonatomic, strong) UIProgressView *progressView;

@property (nonatomic, strong) NSArray *filters;

+ (id) initWithFrame:(CGRect)frame;
+ (CameraView *)initWithCaptureSession:(AVCaptureSession *)captureSession;
- (void)defaultInterface;

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath;

@end
