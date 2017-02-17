#import "CameraView.h"
#import "CameraHelper.h"
#import "FilterCellView.h"

#define previewFrame(y) (CGRect){0, y, ScreenWidth, ScreenWidth}

#define OneOneFrame (CGRect){0, 0, ScreenWidth, ScreenWidth}
#define FourThreeFrame (CGRect){0, 0, ScreenWidth, ScreenWidth * (4 / 3.0)}
#define SixteenNineFrame (CGRect){0, 0, ScreenWidth, ScreenHeight}

#define kThemeCellIdentifier @"kThemeCellIdentifier"

static NSString *CellThemeIdentifier = @"CellThemeIdentifier";
static NSString *CellItemIdentifier = @"CellItemIdentifier";

@interface CameraView () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, strong) CALayer *overlayLayer;

@property (nonatomic, strong) UIView *cameraContainerView;
@property (nonatomic, strong) UIView *videoContainerView;

@property (nonatomic, strong) UIView *topView;
@property (nonatomic, strong) UIView *bottomView;

@end

@implementation CameraView

+ (id)initWithFrame:(CGRect)frame {
    return [[self alloc] initWithFrame:frame captureSession:nil];
}

+ (CameraView *) initWithCaptureSession:(AVCaptureSession *)captureSession {
    return [[self alloc] initWithFrame:[[UIScreen mainScreen] bounds] captureSession:captureSession];
}

- (id) initWithFrame:(CGRect)frame captureSession:(AVCaptureSession *)captureSession {
    if (self = [super initWithFrame:frame]) {
        [self setBackgroundColor:[UIColor blackColor]];

        self.flashButtonState = [defaults_object(kFlashState) integerValue];
        self.scaleButtonState = [defaults_object(kScaleState) integerValue];
        self.tintColor = [UIColor whiteColor];
    }
    
    return self;
}

- (void)defaultInterface {
    [self addSubview:self.topContainerBar];
    [self addSubview:self.bottomContainerBar];
    [self.layer insertSublayer:self.overlayLayer above:self.bottomContainerBar.layer];
    [self addSubview:self.progressView];
    [self addSubview:self.filterCollectionView];
    
    [self addSubview:self.topView];
    [self addSubview:self.bottomView];
    
    [self.topView addSubview:self.cameraButton];
    [self.topView addSubview:self.flashButton];
    [self.topView addSubview:self.scaleButton];

    [self.bottomView addSubview:self.triggerButton];
    [self.bottomView addSubview:self.deleteButton];
    [self.bottomView addSubview:self.finishButton];
    [self.bottomView addSubview:self.cameraFilterButton];
    
    [self updateScaleViewByState:self.scaleButtonState];
    [self setConstraint];
}

#pragma mark - Containers
- (UIView *)topContainerBar {
    if ( !_topContainerBar ) {
        _topContainerBar = [[UIView alloc] initWithFrame:(CGRect){ 0, 0, ScreenWidth, 48 }];
        _topContainerBar.layer.contents = (__bridge id _Nullable)([UIImage imageNamed:@"gradient"].CGImage);
//        [_topContainerBar setBackgroundColor:UIColorFromRGB(0x0e0e13)];
    }
    return _topContainerBar;
}

- (UIView *) bottomContainerBar {
    if ( !_bottomContainerBar ) {
        CGFloat newY = ceil(CGRectGetMaxY(FourThreeFrame));
        _bottomContainerBar = [[UIView alloc] initWithFrame:(CGRect){ 0, newY, ScreenWidth, ScreenHeight - newY }];
        [_bottomContainerBar setUserInteractionEnabled:YES];
        [_bottomContainerBar setBackgroundColor:UIColorFromRGB(0x1b1b23)];
    }
    return _bottomContainerBar;
}

- (UIView *)topView {
    if (!_topView) {
        _topView = [[UIView alloc] initWithFrame:(CGRect){ 0, 0, ScreenWidth, 48 }];
    }
    return _topView;
}

- (UIView *)bottomView {
    if (!_bottomView) {
        CGFloat newY = ceil(CGRectGetMaxY(FourThreeFrame));
        _bottomView = [[UIView alloc] initWithFrame:(CGRect){ 0, newY, ScreenWidth, ScreenHeight - newY }];
    }
    return _bottomView;
}

- (UICollectionView *)filterCollectionView {
    if (!_filterCollectionView) {
        CGFloat newY = CGRectGetMaxY(FourThreeFrame);
        CGFloat height = ScreenWidth * (1 / 3.0);
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.minimumLineSpacing = 0;
        [layout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
        
        _filterCollectionView = [[UICollectionView alloc] initWithFrame:(CGRect){0, newY - height, ScreenWidth, filterCellWidth()} collectionViewLayout:layout];
        _filterCollectionView.delegate = self;
        _filterCollectionView.dataSource = self;
        _filterCollectionView.alwaysBounceHorizontal = YES;
        _filterCollectionView.backgroundColor = [UIColor clearColor];
        _filterCollectionView.showsHorizontalScrollIndicator = NO;
        [_filterCollectionView registerClass:[FilterCellView class] forCellWithReuseIdentifier:kThemeCellIdentifier];
        UIEdgeInsets inset = _filterCollectionView.contentInset;
        inset.left = 8;
        _filterCollectionView.contentInset = inset;
        _filterCollectionView.hidden = YES;
        _filterCollectionView.alpha = 0;
        _filterCollectionView.centerY = _overlayLayer.position.y;
    }
    return _filterCollectionView;
}

- (UIView *)cameraContainerView {
    CGFloat newY = CGRectGetMaxY(FourThreeFrame);
    if (!_cameraContainerView) {
        _cameraContainerView = [[UIView alloc] initWithFrame:(CGRect){ 0, 0, ScreenWidth, ScreenHeight - newY }];
    }
    return _cameraContainerView;
}

- (UIView *)videoContainerView {
    CGFloat newY = CGRectGetMaxY(FourThreeFrame);
    if (!_videoContainerView) {
        _videoContainerView = [[UIView alloc] initWithFrame:(CGRect){ ScreenWidth, 0, ScreenWidth, ScreenHeight - newY }];
    }
    return _videoContainerView;
}

- (CALayer *)overlayLayer {
    if (!_overlayLayer) {
        CGFloat newY = CGRectGetMaxY(FourThreeFrame);
        CGFloat height = ScreenWidth * (1 / 3.0);
        _overlayLayer = [[CALayer alloc] init];
        _overlayLayer.frame = (CGRect){ 0, newY - height, ScreenWidth, height };
        _overlayLayer.hidden = YES;
        _overlayLayer.backgroundColor = UIColorFromRGBWithAlpha(0x000000, 0.85).CGColor;
    }
    return _overlayLayer;
}

#pragma mark - Buttons
- (UIButton *)triggerButton {
    if ( !_triggerButton ) {
        _triggerButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_triggerButton setBackgroundColor:[UIColor clearColor]];
        [_triggerButton setImage:[UIImage imageNamed:@"icon"] forState:UIControlStateNormal];
        
        if (IS_IPHONE_4) {
            [_triggerButton setFrame:(CGRect){ 0, 0, 36, 36 }];
        } else if (IS_IPHONE_5 || IS_IPHONE_6) {
            [_triggerButton setFrame:(CGRect){ 0, 0, 75, 75 }];
        } else if (IS_IPHONE_6P) {
            [_triggerButton setFrame:(CGRect){ 0, 0, 90, 90 }];
        }
        
        [_triggerButton setCenter:(CGPoint){ CGRectGetMidX(self.videoContainerView.bounds), CGRectGetMidY(self.videoContainerView.bounds) }];
        
        UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(captureVideoToggle:)];
        longPressGesture.cancelsTouchesInView = NO;
        [_triggerButton addGestureRecognizer:longPressGesture];
        
        [_triggerButton addTarget:self action:@selector(triggerAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _triggerButton;
}

- (UIButton *) cameraButton {
    if ( !_cameraButton ) {
        _cameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_cameraButton setBackgroundColor:[UIColor clearColor]];
        [_cameraButton setImage:[UIImage imageNamed:@"CameraFlip"] forState:UIControlStateNormal];
        [_cameraButton setFrame:(CGRect){ScreenWidth-38-10, 5, 38, 38 }];
        
        [_cameraButton addTarget:self action:@selector(changeCamera:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _cameraButton;
}

- (UIButton *)flashButton {
    if ( !_flashButton ) {
        _flashButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_flashButton setBackgroundColor:[UIColor clearColor]];
        
        self.flashMode = [CameraHelper updateFlashState:self.flashButtonState flashButton:_flashButton];
        [_flashButton setFrame:(CGRect){ 10, 5, 38, 38 }];
        [_flashButton setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
        [_flashButton addTarget:self action:@selector(flashTriggerAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _flashButton;
}

- (UIButton *)scaleButton {
    if (!_scaleButton) {
        _scaleButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_scaleButton setFrame:(CGRect){ CGRectGetMaxX(_flashButton.frame) + 5, 5, 20, 20 }];
        _scaleButton.layer.borderWidth = 1;
        _scaleButton.layer.borderColor = [UIColor whiteColor].CGColor;
        [CameraHelper updateScaleState:self.scaleButtonState scaleButton:_scaleButton];
        _scaleButton.titleLabel.font = [UIFont systemFontOfSize:8];
        _scaleButton.centerY = _topContainerBar.centerY;
        [_scaleButton setEnlargeEdgeWithTop:7 right:7 bottom:7 left:7];
        [_scaleButton addTarget:self action:@selector(scaleAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _scaleButton;
}

- (UIButton *)deleteButton {
    if ( !_deleteButton ) {
        _deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_deleteButton setImage:[UIImage imageNamed:@"tag-with-cancel"] forState:UIControlStateNormal];
        [_deleteButton setImage:[UIImage imageNamed:@"delete-button"] forState:UIControlStateSelected];
        
        if (IS_IPHONE_4) {
            [_deleteButton setFrame:(CGRect){38*kScale, (CGRectGetMaxY(_bottomContainerBar.bounds) - 30)/2.0, 30, 30 }];
        } else {
            [_deleteButton setFrame:(CGRect){38*kScale, (CGRectGetMaxY(_bottomContainerBar.bounds) - 45)/2.0, 45, 45 }];
        }
        
        [_deleteButton setHidden:YES];
        [_deleteButton addTarget:self action:@selector(deleteButtonDone:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _deleteButton;
}

- (UIButton *)cameraFilterButton {
    if (!_cameraFilterButton) {
        _cameraFilterButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_cameraFilterButton setImage:[UIImage imageNamed:@"filtericon"] forState:UIControlStateNormal];
        [_cameraFilterButton setFrame:(CGRect){ScreenWidth - 30*2, (CGRectGetMaxY(_bottomContainerBar.bounds) - 30)/2.0, 30, 30 }];
        [_cameraFilterButton addTarget:self action:@selector(filterButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cameraFilterButton;
}

- (UIButton *)finishButton {
    if (!_finishButton) {
        _finishButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_finishButton setImage:[UIImage imageNamed:@"checked"] forState:UIControlStateNormal];
        if (IS_IPHONE_4) {
            [_finishButton setFrame:(CGRect){ScreenWidth - 38 - 30, (CGRectGetMaxY(_bottomContainerBar.bounds) - 30)/2.0, 30, 30 }];
        } else {
            [_finishButton setFrame:(CGRect){ScreenWidth - 38 - 45, (CGRectGetMaxY(_bottomContainerBar.bounds) - 45)/2.0, 45, 45 }];
        }
        
        [_finishButton setHidden:YES];
        [_finishButton addTarget:self action:@selector(finishCaptureAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _finishButton;
}

- (UIProgressView *)progressView {
    if (!_progressView) {
        //_progressView = [[UIProgressView alloc] initWithFrame:(CGRect){ -1, CGRectGetMinY(self.bottomContainerBar.frame), ScreenWidth + 2, 5 }];
        _progressView =  [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
//        _progressView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        _progressView.translatesAutoresizingMaskIntoConstraints = NO;
        _progressView.progressTintColor = UIColorFromRGB(0xf7f7f7);
        _progressView.trackTintColor = UIColorFromRGB(0x2d2d2d);
    }
    return _progressView;
}

#pragma mark - Actions
- (void)updateScaleViewByState:(NSUInteger)state {
    if (state == 0) {
        self.overlayLayer.hidden = YES;
        self.bottomContainerBar.alpha = 1;
        self.topContainerBar.alpha = 1;
        
    } else if (state == 1) {
        self.overlayLayer.hidden = NO;
        self.bottomContainerBar.alpha = 1;
        self.topContainerBar.alpha = 1;
        
    } else {
        self.overlayLayer.hidden = YES;
        self.bottomContainerBar.alpha = 0.85;
        self.topContainerBar.alpha = 0.75;
        
    }
}

- (void)finishCaptureAction:(UIButton *)button {
    if (_delegate && [_delegate respondsToSelector:@selector(finishCapture)]) {
        [_delegate finishCapture];
    }
}

- (void) flashTriggerAction:(UIButton *)button {
    self.flashButtonState ++;
    if (self.flashButtonState == 3) {
        self.flashButtonState = 0;
    }
    defaults_set_object(kFlashState, [NSNumber numberWithInteger:self.flashButtonState]);
    
    if ( [_delegate respondsToSelector:@selector(triggerFlashForMode:)] ) {
        [button setSelected:!button.isSelected];
        [_delegate triggerFlashForMode: [CameraHelper updateFlashState:self.flashButtonState flashButton:button] ];
    }
}

- (void)scaleAction:(UIButton *)button {
    self.scaleButtonState ++;
    if (self.scaleButtonState == 3) {
        self.scaleButtonState = 0;
    }
    defaults_set_object(kScaleState, [NSNumber numberWithInteger:self.scaleButtonState]);
    [CameraHelper updateScaleState:self.scaleButtonState scaleButton:button];
    
    [self updateScaleViewByState:self.scaleButtonState];
}

- (void)filterButtonAction:(UIButton *)button {
    if (self.filterCollectionView.hidden) {
        self.filterCollectionView.hidden = NO;
        [UIView animateWithDuration:0.3 animations:^{
            self.filterCollectionView.alpha = 1;
        } completion:^(BOOL finished) {
        }];
        
    } else {
        [UIView animateWithDuration:0.3 animations:^{
            self.filterCollectionView.alpha = 0;
        } completion:^(BOOL finished) {
            self.filterCollectionView.hidden = YES;
        }];
    }
}

- (void)changeCamera:(UIButton *)button {
    [button setSelected:!button.isSelected];
//    if ( button.isSelected && self.flashButton.isSelected ) {
//        [self flashTriggerAction:self.flashButton];
//    }
//    [self.flashButton setEnabled:!button.isSelected];
    if ( [self.delegate respondsToSelector:@selector(switchCamera)] ) {
        [self.delegate switchCamera];
    }
}

- (void)triggerAction:(UIButton *)button {
    if ( [_delegate respondsToSelector:@selector(togglePhoto)] )
        [_delegate togglePhoto];
}

- (void)captureVideoToggle:(UIGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        if ( [_delegate respondsToSelector:@selector(cameraViewStartRecording)] ) {
            [_delegate cameraViewStartRecording];
//            [self.triggerButton setImage:[UIImage imageNamed:@"icon_dim"] forState:UIControlStateNormal];
        }
        
    } else {
        if (recognizer.state == UIGestureRecognizerStateCancelled || recognizer.state == UIGestureRecognizerStateFailed || recognizer.state == UIGestureRecognizerStateEnded) {
            if ( [_delegate respondsToSelector:@selector(cameraViewStartRecording)] ) {
                [_delegate cameraViewPauseRecording];
//                [self.triggerButton setImage:[UIImage imageNamed:@"icon"] forState:UIControlStateNormal];
            }
        }
    }
}

- (void)deleteButtonDone:(UIButton *)button {
    button.selected = !button.selected;

    if (button.selected) {
        if (_delegate && [_delegate respondsToSelector:@selector(deleteSegement)]) {
            [_delegate deleteSegement];
        }
    } else {
        if (_delegate && [_delegate respondsToSelector:@selector(confirmDeleteSegement)]) {
            BOOL result = [_delegate confirmDeleteSegement];
            if (result) {
                self.deleteButton.hidden = NO;
            } else {
                self.finishButton.hidden = YES;
                self.deleteButton.hidden = YES;
            }
        }
    }
}

- (void)setConstraint {
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.progressView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1 constant:-1]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.bottomContainerBar attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.progressView attribute:NSLayoutAttributeTop multiplier:1 constant:5]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.progressView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1 constant:ScreenWidth + 2]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.progressView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1 constant:5]];
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.filters.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    FilterCellView * cell = [collectionView dequeueReusableCellWithReuseIdentifier:kThemeCellIdentifier forIndexPath:indexPath];
    [cell configWithFilter:self.filters[indexPath.item]];
    
    if (cell.selected) {
        cell.overlayLayer.hidden = NO;
    } else {
        cell.overlayLayer.hidden = YES;
    }
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(filterCellWidth(), filterCellWidth());
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    FilterCellView *cell = (FilterCellView *)[collectionView cellForItemAtIndexPath:indexPath];
    cell.overlayLayer.hidden = NO;
    
    if (_delegate && [_delegate respondsToSelector:@selector(filterViewDone:cellFrame:)]) {
        CGRect visibleRect = [_delegate filterViewDone:indexPath.item cellFrame:cell.frame];
        [collectionView scrollRectToVisible:visibleRect animated:YES];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    FilterCellView *cell = (FilterCellView *)[collectionView cellForItemAtIndexPath:indexPath];
    cell.overlayLayer.hidden = YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

@end
