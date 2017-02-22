#import "PlayerViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "PresentingAnimator.h"
#import "DismissingAnimator.h"
#import "CropVideoUtil.h"
#import "IndicatorView.h"
#import "CameraHelper.h"

typedef enum {
    SaveVideo,
    ShareVideo
} VideoHandleType;

@interface PlayerViewController ()<UIViewControllerTransitioningDelegate>
@property (nonatomic, strong) AVPlayer *player;

@property (nonatomic, strong) UIView *topContainerBar;
@property (nonatomic, strong) UIView *bottomContainerBar;
@property (nonatomic, strong) UIButton *backButton;

@property (nonatomic, strong) UIImageView *photoImageView;

@property (nonatomic, strong) UIButton *shareButton;
@property (nonatomic, strong) UIButton *downloadButton;
@property (nonatomic, strong) ShareViewController *shareViewController;
@property (nonatomic, strong) UIWindow *currentWindow;
@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;

@property (nonatomic, strong) IndicatorView *indicatorView;
@property (nonatomic, strong) IndicatorView *shareIndicatorView;
@property (nonatomic, strong) NSURL *movieURL;

@property (nonatomic, strong) AVPlayerLayer *playerLayer;

@end

@implementation PlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColorFromRGB(0x1a1c1f);
    
    if (self.playType == PhotoType) {
        [self.view addSubview:self.photoImageView];
        if (self.photo) {
            self.photoImageView.image = self.photo;
        }
        
    } else {
        AVAsset *asset = _recordSession.assetRepresentingSegments;
        AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:asset];
        self.player = [[AVPlayer alloc] initWithPlayerItem:item];
        self.player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
        
        self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
        self.playerLayer.frame = self.view.layer.bounds;
        self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        [self.view.layer addSublayer:self.playerLayer];
        
        [self.player play];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:[self.player currentItem]];
        
    }
    
    [self.view addSubview:self.bottomContainerBar];
    if (self.scaleButtonState == 1) {
        CGFloat height = ceil(CGRectGetMinY(self.bottomContainerBar.frame) - ScreenWidth);
        UIView *overlayView= [[UIView alloc] initWithFrame:(CGRect){0, ScreenWidth, ScreenWidth, height}];
        overlayView.backgroundColor = UIColorFromRGBWithAlpha(0x000000, 0.95);
        [self.view addSubview:overlayView];
    }
    
    [self.bottomContainerBar addSubview:self.backButton];
    [self.bottomContainerBar addSubview:self.shareButton];
    [self.bottomContainerBar addSubview:self.downloadButton];
    [self.bottomContainerBar addSubview:self.indicatorView];
    [self.bottomContainerBar addSubview:self.shareIndicatorView];
    
    [self updateScaleViewByState:self.scaleButtonState];
    
    self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(bgViewTap:)];
    self.currentWindow = [[UIApplication sharedApplication] keyWindow];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.player pause];
    [self.playerLayer removeFromSuperlayer];
    self.player = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)bgViewTap:(UIGestureRecognizer *)gesture {
    CGPoint point = [gesture locationInView:self.view];
    point.y = point.y + (82 * kScale);
    
    if (!CGRectContainsPoint(self.shareViewController.view.frame, point)) {
        [self.shareViewController closeButtonTap];
    }
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    AVPlayerItem *p = [notification object];
    [p seekToTime:kCMTimeZero];
}

#pragma mark - override Method
- (BOOL) prefersStatusBarHidden {
    return YES;
}

- (void)updateScaleViewByState:(NSUInteger)state {
    if (state == 0) {
        self.bottomContainerBar.alpha = 1;
        self.topContainerBar.alpha = 1;
    } else if (state == 1) {
        self.bottomContainerBar.alpha = 1;
        self.topContainerBar.alpha = 1;
    } else {
        self.bottomContainerBar.alpha = 0.85;
        self.topContainerBar.alpha = 0.75;
    }
}

- (UIImageView *)photoImageView {
    if (!_photoImageView) {
        _photoImageView = [[UIImageView alloc] initWithFrame:(CGRect){0, 0, ScreenWidth, ScreenHeight}];
        _photoImageView.contentMode = UIViewContentModeScaleAspectFill;
    }
    return _photoImageView;
}

- (UIView *)bottomContainerBar {
    if ( !_bottomContainerBar ) {
        CGRect rect = (CGRect){0, 0, ScreenWidth, ScreenWidth * (4 / 3.0)};
        CGFloat newY = ceil(CGRectGetMaxY(rect));
        
        _bottomContainerBar = [[UIView alloc] initWithFrame:(CGRect){ 0, newY, ScreenWidth, ScreenHeight - newY }];
        [_bottomContainerBar setUserInteractionEnabled:YES];
        [_bottomContainerBar setBackgroundColor:UIColorFromRGB(0x1b1b23)];
    }
    return _bottomContainerBar;
}

- (UIButton *)shareButton {
    if ( !_shareButton ) {
        _shareButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_shareButton setBackgroundColor:[UIColor clearColor]];
        [_shareButton setImage:[UIImage imageNamed:@"share"] forState:UIControlStateNormal];
        if (IS_IPHONE_4) {
            [_shareButton setFrame:(CGRect){ScreenWidth - 28 - 40, 0, 28, 28 }];
        } else {
            [_shareButton setFrame:(CGRect){ScreenWidth - 35 - 40, 0, 35, 35 }];
        }
        _shareButton.centerY = CGRectGetMidY(self.bottomContainerBar.bounds);
        [_shareButton addTarget:self action:@selector(shareTap) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _shareButton;
}

- (UIButton *)downloadButton {
    if ( !_downloadButton ) {
        _downloadButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_downloadButton setBackgroundColor:[UIColor clearColor]];
        [_downloadButton setImage:[UIImage imageNamed:@"download"] forState:UIControlStateNormal];
        [_downloadButton setImage:[UIImage imageNamed:@"check-symbol"] forState:UIControlStateSelected];
        if (IS_IPHONE_4) {
            [_downloadButton setFrame:(CGRect){0, 0, 28, 28}];
        } else {
            [_downloadButton setFrame:(CGRect){0, 0, 35, 35}];
        }
        _downloadButton.centerY = CGRectGetMidY(self.bottomContainerBar.bounds);
        _downloadButton.centerX = ScreenWidth / 2.0;
        [_downloadButton addTarget:self action:@selector(saveToCameraRoll) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _downloadButton;
}

- (UIButton *)backButton {
    if (!_backButton) {
        _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_backButton setBackgroundColor:[UIColor clearColor]];
        [_backButton setImage:[UIImage imageNamed:@"back"] forState:UIControlStateNormal];
        if (IS_IPHONE_4) {
            [_backButton setFrame:(CGRect){40, 0, 28, 28}];
        } else {
            [_backButton setFrame:(CGRect){40, 0, 35, 35}];
        }
        _backButton.centerY = CGRectGetMidY(self.bottomContainerBar.bounds);
        [_backButton addTarget:self action:@selector(backButtonDone) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _backButton;
}

- (IndicatorView *)indicatorView {
    if (!_indicatorView) {
        _indicatorView = [[IndicatorView alloc] initWithFrame:(CGRect){0, 0, 28, 28}];
        _indicatorView.centerY = CGRectGetMidY(self.bottomContainerBar.bounds);
        _indicatorView.centerX = ScreenWidth / 2.0;
    }
    return _indicatorView;
}

- (IndicatorView *)shareIndicatorView {
    if (!_shareIndicatorView) {
        _shareIndicatorView = [[IndicatorView alloc] initWithFrame:(CGRect){ScreenWidth - 35 - 40, 0, 28, 28}];
        _shareIndicatorView.centerY = CGRectGetMidY(self.bottomContainerBar.bounds);
    }
    return _shareIndicatorView;
}

- (void)backButtonDone {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)saveVideoWithAsset:(AVAsset *)asset type:(VideoHandleType)type {
    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Osho.mp4"];
    unlink([pathToMovie UTF8String]);
    NSURL *movieURL = [NSURL fileURLWithPath:pathToMovie];
    
    NSString *quality;
    if (type == ShareVideo) {
        quality = AVAssetExportPresetMediumQuality;
    } else {
        quality = AVAssetExportPresetHighestQuality;
    }
    
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:asset presetName:quality];
    exportSession.outputURL = movieURL;
    exportSession.outputFileType = AVFileTypeQuickTimeMovie;
    
    @weakify(self)
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (type == ShareVideo) {
                @strongify(self)
                
                [self.shareIndicatorView stopAnimating];
                [self.shareButton setHidden:NO];
                [self updateViewFinishExport];
                UIActivityViewController *activeViewController = [[UIActivityViewController alloc] initWithActivityItems:@[@"Osho.mp4", movieURL] applicationActivities:nil];
                //                activeViewController.excludedActivityTypes = @[UIActivityTypeAirDrop,UIActivityTypeCopyToPasteboard,UIActivityTypeAddToReadingList];
                
                [self presentViewController:activeViewController animated:YES completion:nil];
                
                UIActivityViewControllerCompletionHandler myblock = ^(NSString *type,BOOL completed){
                    [self.player play];
                    NSError *removeError = nil;
                    [[NSFileManager defaultManager] removeItemAtURL:movieURL error:&removeError];
                };
                activeViewController.completionHandler = myblock;
                
            } else {
                ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];
                [assetLibrary writeVideoAtPathToSavedPhotosAlbum:movieURL completionBlock:^(NSURL *assetURL, NSError *error){
                    @strongify(self)
                    NSError *removeError = nil;
                    [[NSFileManager defaultManager] removeItemAtURL:movieURL error:&removeError];
                    
                    [self.indicatorView stopAnimating];
                    [self updateViewFinishExport];
                    [self.downloadButton setHidden:NO];
                    
                    if (error) {
                        self.downloadButton.selected = NO;
                    } else {
                        self.downloadButton.selected = YES;
                        self.downloadButton.userInteractionEnabled = NO;
                    }
                    
                    
                }];
            }
        });
        
    }];
}


- (void)handelVideo:(VideoHandleType)type {
    [self.player pause];
    if (self.scaleButtonState == 2) {
        [self saveVideoWithAsset:_recordSession.assetRepresentingSegments type: type];
    } else {
        @weakify(self)
        [CropVideoUtil cropPureVideoWithURL:_recordSession.assetRepresentingSegments scaleType:self.scaleButtonState completeBlock:^(NSString *urlString) {
            @strongify(self)
            AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:urlString]];
            [self saveVideoWithAsset:asset type: type];
        }];
    }
}

- (void)updateViewWhenExport {
    [self.player pause];
    if (!self.downloadButton.selected) {
        self.downloadButton.enabled = NO;
    }
    self.backButton.enabled = NO;
    self.shareButton.enabled = NO;
}

- (void)updateViewFinishExport {
    [self.player play];
    self.downloadButton.enabled = YES;
    self.backButton.enabled = YES;
    self.shareButton.enabled = YES;
}

- (UIImage *)getSaveImage {
    CGRect rect;
    UIImage *image;
    if (self.scaleButtonState == 1) {
        rect = (CGRect){0, 0, ScreenWidth, ScreenWidth};
        image = [self.view screenShotWithRect:rect];
        
    } else if (self.scaleButtonState == 0) {
        rect = (CGRect){0, 0, ScreenWidth, ScreenWidth * (4 / 3.0)};
        image = [self.view screenShotWithRect:rect];
        
    } else {
        image = self.photo;
    }
    return image;
}

- (void)saveToCameraRoll {
    if ( ![CameraHelper checkPhotoLibrary] ) {
        return;
    }
    
    if (self.playType == PhotoType) {
        UIImage *image = [self getSaveImage];
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        [library writeImageDataToSavedPhotosAlbum:UIImageJPEGRepresentation(image, 1) metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
            if (error) {
                self.downloadButton.selected = NO;
            } else {
                self.downloadButton.selected = YES;
                self.downloadButton.userInteractionEnabled = NO;
            }
        }];
        
        
    } else {
        [self updateViewWhenExport];
        [self.indicatorView startAnimating];
        [self.downloadButton setHidden:YES];
        
        [self handelVideo:SaveVideo];
    }
}

- (void)shareTap {
    if (self.playType == PhotoType) {
        UIImage *image = [self getSaveImage];
        
        NSData *imageData = UIImageJPEGRepresentation(image, 1);
        float size = (float)imageData.length/1024.0f/1024.0f;
        float compressValue = 0.3 / size;
        NSData *finalData = UIImageJPEGRepresentation(image, compressValue);
        image = [UIImage imageWithData:finalData];
        
        self.shareViewController = [[ShareViewController alloc] initWithTitleText:@"分享给您的朋友" sampleFile:nil];
        self.shareViewController.photo = image;
        self.shareViewController.transitioningDelegate = self;
        self.shareViewController.modalPresentationStyle = UIModalPresentationCustom;
        [self presentViewController:self.shareViewController animated:YES completion:NULL];

    } else {
        [self updateViewWhenExport];
        [self.shareIndicatorView startAnimating];
        [self.shareButton setHidden:YES];
        [self handelVideo:ShareVideo];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UIViewControllerTransitioningDelegate
- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source
{
    [self.currentWindow addGestureRecognizer:self.tapGesture];
    return [PresentingAnimator new];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    [self.currentWindow removeGestureRecognizer:self.tapGesture];
    return [DismissingAnimator new];
}

- (void)applicationWillResignActive:(NSNotification *)notification {
    [self.player pause];
}
- (void)applicationDidEnterBackground:(NSNotification *)notification {
    [self.player pause];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    [self.player play];
}

@end
