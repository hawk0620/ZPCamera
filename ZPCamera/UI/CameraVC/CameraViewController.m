#import "CameraViewController.h"
#import "CameraView.h"
#import "CameraHelper.h"

#import "RecorderTools.h"
#import "RecordSession.h"

#import "RecordSessionManager.h"
#import "PlayerViewController.h"

#import "FilterMap.h"

#import "RecoderManager.h"
#import "FilterGenerator.h"
#import "FilterDisplayView.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "TipView.h"
#import "FocusBoxLayer.h"

#define kDefaultDuration 30.0

@interface CameraViewController ()<CameraViewDelegate, RecoderManagerDelegate>

@property (nonatomic, strong) NSMutableArray *filterMaps;
@property (nonatomic, strong) NSMutableArray *lastTimeArray;
@property (nonatomic, strong) NSMutableArray *lineViewArray;
@property (nonatomic, strong) UIView *deleteSegementView;
@property (nonatomic, assign) NSInteger currentFilterIndex;

@property (nonatomic, strong) GPUImageOutput<GPUImageInput> *filter;
@property (nonatomic, strong) RecoderManager *videoCamera;
@property (nonatomic, strong) FilterDisplayView *filterView;

@property (nonatomic, strong) TipView *tipView;
@property (nonatomic, strong) FocusBoxLayer *focusBox;

@end

@implementation CameraViewController

#pragma mark - View Life Circle
- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    self.lastTimeArray = [NSMutableArray array];
    self.lineViewArray = [NSMutableArray array];
    self.filterMaps = [NSMutableArray arrayWithArray:[FilterMap filterMap]];
    
    NSString *sessionPreset = [RecorderTools bestCaptureSessionPresetCompatibleWithAllDevices];
    [self.view addSubview:self.cameraView];
    
    self.cameraView.filters = self.filterMaps;
    
    self.videoCamera = [[RecoderManager alloc] initWithSessionPreset:sessionPreset cameraPosition:AVCaptureDevicePositionBack];
    self.videoCamera.horizontallyMirrorFrontFacingCamera = YES;
    self.videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
//    self.videoCamera.horizontallyMirrorRearFacingCamera = YES;
    self.videoCamera.initializeSessionLazily = NO;
    self.videoCamera.recoderManagerDelegate = self;
    
    self.filterView = [[FilterDisplayView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight)];
    self.filterView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
    self.videoCamera.filterView = self.filterView;
    
    self.currentFilterIndex = 0;
    [self selectCellAtIndex:self.currentFilterIndex];
    [self.cameraView insertSubview:self.filterView belowSubview:self.cameraView.topContainerBar];
    
    [self triggerFlashForMode:self.cameraView.flashMode];
    [self checkDeviceSupportFlash];
    
    [self setupGesture];
    [self setupTipView];
    
    [self updateTimeRecordedLabel];
    
    self.focusBox = [[FocusBoxLayer alloc] init];
    [self.cameraView.layer addSublayer:self.focusBox];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES];
    [self prepareSession];
    self.cameraView.triggerButton.userInteractionEnabled = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.videoCamera startCameraCapture];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.videoCamera stopCameraCapture];
    self.cameraView.userInteractionEnabled = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - ViewController Helper Method
- (void)setupGesture {
    UISwipeGestureRecognizer *leftSwipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeLeftDone)];
    leftSwipeGesture.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.filterView addGestureRecognizer:leftSwipeGesture];
    
    UISwipeGestureRecognizer *rightSwipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRightDone)];
    rightSwipeGesture.direction = UISwipeGestureRecognizerDirectionRight;
    [self.filterView addGestureRecognizer:rightSwipeGesture];
    
    UITapGestureRecognizer *tapToFocusGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToFocus:)];
    [self.filterView addGestureRecognizer:tapToFocusGesture];
}

- (void)setupTipView {
    CGFloat popHeight = 35.0;
    CGRect popRect = [self.cameraView.bottomContainerBar convertRect:self.cameraView.triggerButton.frame toView:self.view];
    popRect.origin.y = popRect.origin.y - popHeight - 5;
    popRect.size.width = 140;
    popRect.size.height = popHeight;
    
    self.tipView = [[TipView alloc] initWithFrame:popRect];
    self.tipView.centerX = self.view.centerX;
    [self.view addSubview:self.tipView];
    
    [self performSelector:@selector(hideTipView) withObject:nil afterDelay:1.5];
}

- (void)hideTipView {
    [UIView animateWithDuration:0.2 animations:^{
        self.tipView.alpha = 0;
    } completion:^(BOOL finished) {
        self.tipView.hidden = YES;
    }];
}

- (void)setCurrentFilterIndex:(NSInteger)currentFilterIndex {
    _currentFilterIndex = currentFilterIndex;
    
    NSString *filterName = self.filterMaps[currentFilterIndex][@"filter"];
    NSString *filterType = self.filterMaps[currentFilterIndex][@"type"];
    self.videoCamera.filterName = filterName;
    self.videoCamera.filterType = filterType;
    
    [self.filter removeAllTargets];
    [self.videoCamera removeAllTargets];
    
    self.filter = [FilterGenerator generateFilterByName:filterName type:filterType];
    
    [self.videoCamera addTarget:self.filter];
    [self.filter addTarget:self.filterView];
}

- (float)getCurrentTime {
    CMTime currentTime = kCMTimeZero;
    if (self.videoCamera.session != nil) {
        currentTime = self.videoCamera.session.duration;
    }
    return CMTimeGetSeconds(currentTime);
}

- (void)checkDeviceSupportFlash {
    if (!self.videoCamera.hasFlash) {
        [self.cameraView.flashButton setEnabled:NO];
    }
}

#pragma mark - override Method
- (BOOL) prefersStatusBarHidden {
    return YES;
}

#pragma mark - Gesture Method
- (void)deselectCollectionViewAtIndex:(NSInteger)index {
    [self.cameraView collectionView:self.cameraView.filterCollectionView didDeselectItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
    [self.cameraView.filterCollectionView deselectItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0] animated:YES];
}

- (void)selectCellAtIndex:(NSInteger)currentIndex {
    [self.cameraView collectionView:self.cameraView.filterCollectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:currentIndex inSection:0]];
    [self.cameraView.filterCollectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:currentIndex inSection:0] animated:YES scrollPosition:UICollectionViewScrollPositionNone];
    
    [self.cameraView.filterCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:currentIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
}

- (void)swipeLeftDone {
    [self deselectCollectionViewAtIndex:_currentFilterIndex];
    if (self.currentFilterIndex < self.filterMaps.count - 1) {
        self.currentFilterIndex = _currentFilterIndex + 1;
        [self selectCellAtIndex:self.currentFilterIndex];
    } else {
        self.currentFilterIndex = self.filterMaps.count - 1;
        [self selectCellAtIndex:self.currentFilterIndex];
    }
}

- (void)swipeRightDone {
    [self deselectCollectionViewAtIndex:_currentFilterIndex];
    if (self.currentFilterIndex > 0) {
        self.currentFilterIndex = _currentFilterIndex - 1;
        [self selectCellAtIndex:self.currentFilterIndex];
    } else {
        self.currentFilterIndex = 0;
        [self selectCellAtIndex:self.currentFilterIndex];
    }
}

- (void)tapToFocus:(UIGestureRecognizer *)recognizer {
    CGPoint tempPoint = (CGPoint)[recognizer locationInView:self.filterView];
    CGPoint convertedFocusPoint = [self.videoCamera convertToPointOfInterestFromViewCoordinates:tempPoint];
    
    [self.focusBox drawaAtPointOfInterest:tempPoint andRemove:YES];
    
    if (self.videoCamera.focusSupported) {
        [self.videoCamera focusAtPoint:convertedFocusPoint];
    }
}

#pragma mark - Init Instance
- (CameraView *)cameraView {
    if ( !_cameraView ) {
        _cameraView = [CameraView initWithCaptureSession:self.videoCamera.captureSession];
        [_cameraView setTintColor:[UIColor whiteColor]];
        [_cameraView defaultInterface];
        [_cameraView setUserInteractionEnabled:NO];
        [_cameraView setDelegate:self];
    }
    
    return _cameraView;
}

- (void)prepareSession {
    if (self.videoCamera.session == nil) {
        RecordSession *session = [RecordSession recordSession];
        session.fileType = AVFileTypeQuickTimeMovie;
        self.videoCamera.session = session;
    }
}

#pragma mark - CameraManagerDelagate
- (void)updateTimeRecordedLabel {
    float currentTime = [self getCurrentTime];
    
    @weakify(self)
    dispatch_async(dispatch_get_main_queue(), ^{
        @strongify(self)
        [self.cameraView.progressView setProgress:currentTime / kDefaultDuration];
        
        if (currentTime >= kDefaultDuration) {
            [self finishCapture];
        }
    });
}

- (void)saveAndShowSession:(RecordSession *)recordSession {
    [[RecordSessionManager sharedInstance] saveRecordSession:recordSession];
    
    PlayerViewController *videoPlayer = [[PlayerViewController alloc] init];
    videoPlayer.recordSession = recordSession;
    videoPlayer.scaleButtonState = self.cameraView.scaleButtonState;
    videoPlayer.playType = VideoType;
    [self.navigationController pushViewController:videoPlayer animated:YES];
}

- (void)captureImageDidFinish:(UIImage *)image withMetadata:(NSDictionary *)metadata {
//    UIImage *newImage = [UIImage fixOrientation:image];
//    UIImage *smallImage = [UIImage getSubImage:image];
    if (!image) {
        [[[UIAlertView alloc] initWithTitle:@"抱歉，拍照出错了。" message:nil delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil] show];
        return;
    }
    
    PlayerViewController *photoPlayer = [[PlayerViewController alloc] init];
    photoPlayer.scaleButtonState = self.cameraView.scaleButtonState;
    photoPlayer.playType = PhotoType;
    
    photoPlayer.photo = image;
    [self.navigationController pushViewController:photoPlayer animated:YES];
    
}

- (void)captureImageFailedWithError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[[UIAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil] show];
    });
}

- (void)didAppendVideoSampleBufferInSession:(RecordSession *)recordSession {
    [self updateTimeRecordedLabel];
}

- (void)captureSessionDidStartRunning {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.cameraView.userInteractionEnabled = YES;
    });
}

#pragma mark - CameraViewDelegate
- (void)triggerFlashForMode:(AVCaptureFlashMode)flashMode {
    AVCaptureDevice *device = self.videoCamera.gpuVideoInput.device;
    if ( [device isFlashModeSupported:flashMode] && device.flashMode != flashMode ) {
        [self.videoCamera.inputCamera lockForConfiguration:nil];
        [self.videoCamera.inputCamera setFlashMode:flashMode];
        [self.videoCamera.inputCamera unlockForConfiguration];
    }
}

- (void)switchCamera {
    if ([self.videoCamera hasMultipleCameras]) {
        self.videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
        [self.videoCamera rotateCamera];
        
        if (self.videoCamera.cameraPosition == AVCaptureDevicePositionFront) {
            [self.cameraView.flashButton setEnabled:NO];
        } else {
            if (self.videoCamera.hasFlash) {
                [self.cameraView.flashButton setEnabled:YES];
            }
        }
    }
}

- (void)cameraViewStartRecording {
    if( ![CameraHelper checkAVAuthorizationStatus] ) {
        return;
    }
    if (![CameraHelper checkRecordPermission]) {
        return;
    }
    
    float currentTime = [self getCurrentTime];
    if (currentTime >= kDefaultDuration) {
        [self finishCapture];
        return;
    }
    
    [self.videoCamera record];
    
    if (currentTime > 0) {
        CGFloat xPosition = (currentTime / kDefaultDuration) * ScreenWidth;
        UIView *lineView = [[UIView alloc] initWithFrame:(CGRect){ceil(xPosition), 0, 1, 5}];
        lineView.backgroundColor = [UIColor blackColor];
        [self.cameraView.progressView addSubview:lineView];
        [self.lineViewArray addObject:lineView];
        
        if (self.cameraView.deleteButton.selected) {
            [self.deleteSegementView removeFromSuperview];
            self.cameraView.deleteButton.selected = !self.cameraView.deleteButton.selected;
        }
    }
    [self.lastTimeArray addObject:@(currentTime)];
    
    self.cameraView.deleteButton.hidden = NO;
    self.cameraView.finishButton.hidden = NO;
    
    [self.cameraView.scaleButton setHidden:YES];
    self.cameraView.cameraFilterButton.hidden = YES;
    self.cameraView.filterCollectionView.hidden = YES;
    self.cameraView.filterCollectionView.alpha = 0;
    self.filterView.userInteractionEnabled = NO;
    self.cameraView.flashButton.hidden = YES;
}

- (void)togglePhoto {
    float currentTime = [self getCurrentTime];
    if (currentTime > 0) {
        return;
    }
    
    if( ![CameraHelper checkAVAuthorizationStatus] ) {
        return;
    }
    
    self.cameraView.triggerButton.userInteractionEnabled = NO;
    [self.videoCamera captureImageForDeviceOrientation:UIDeviceOrientationPortrait];
}

- (void)cameraViewPauseRecording {
    [self.videoCamera pause];
}

- (void)deleteSegement {
    float currentTime = [self getCurrentTime];
    if (currentTime > 0) {
        CGFloat xPosition = (currentTime / kDefaultDuration) * ScreenWidth;
        CGFloat theLastTime = [[self.lastTimeArray lastObject] floatValue];
        CGFloat lastXPosition = (theLastTime / kDefaultDuration) * ScreenWidth;
        CGFloat deleteSegmentWidth = ceil(xPosition - lastXPosition);
        self.deleteSegementView = [[UIView alloc] initWithFrame:(CGRect){ceil(lastXPosition), 0, deleteSegmentWidth, 5}];
        self.deleteSegementView.backgroundColor = UIColorFromRGB(0xea4e57);
        [self.cameraView.progressView addSubview:self.deleteSegementView];
    }
}

- (BOOL)confirmDeleteSegement {
    NSUInteger segemntsCount = self.videoCamera.session.segments.count;
    
    if (segemntsCount > 0) {
        [self.videoCamera.session removeSegmentAtIndex:(segemntsCount - 1) deleteFile:YES];
        
        [self.deleteSegementView removeFromSuperview];
        CGFloat theLastTime = [[self.lastTimeArray lastObject] floatValue];
        [self.cameraView.progressView setProgress:(theLastTime / kDefaultDuration) animated:YES];
        [self.lastTimeArray removeLastObject];
        [[self.lineViewArray lastObject] removeFromSuperview];
        [self.lineViewArray removeLastObject];
        
        BOOL hasElement = (self.lastTimeArray.count > 0);
        if (!hasElement) {
            self.cameraView.cameraFilterButton.hidden = NO;
            [self.cameraView.scaleButton setHidden:NO];
            self.filterView.userInteractionEnabled = YES;
            self.cameraView.flashButton.hidden = NO;
        }
        return hasElement;
    }
    
    return NO;
}

- (void)handleStopButtonTapped {
    @weakify(self)
    [self.videoCamera pause:^{
        @strongify(self)
        [self saveAndShowSession:self.videoCamera.session];
    }];
}

- (void)finishCapture {
    [self handleStopButtonTapped];
}

- (CGRect)filterViewDone:(NSInteger)index cellFrame:(CGRect)rect {
    CGRect visibleRect = rect;
    
    CGRect cellFrameInSuperview = [self.cameraView.filterCollectionView convertRect:visibleRect toView:self.cameraView];
    
    if (cellFrameInSuperview.origin.x < 0) {
        visibleRect.origin.x = (visibleRect.origin.x - (filterCellWidth() / 2.0) < 0) ? 0 : visibleRect.origin.x - (filterCellWidth() / 2.0);
    } else if (cellFrameInSuperview.origin.x + filterCellWidth() > ScreenWidth) {
        visibleRect.origin.x = visibleRect.origin.x + (filterCellWidth() / 2.0);
    }
    
    self.currentFilterIndex = index;
    return visibleRect;
}

#pragma mark - UIApplicationNotification
- (void)applicationWillResignActive:(NSNotification *)notification {
    [self.videoCamera stopCameraCapture];
}
- (void)applicationDidEnterBackground:(NSNotification *)notification {
    [self.videoCamera stopCameraCapture];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    //[CameraHelper checkAVAuthorizationStatus];
    //[CameraHelper checkRecordPermission];
    [self.videoCamera startCameraCapture];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
