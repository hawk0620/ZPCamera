#import "IndicatorView.h"
#import "BallRotate.h"

@implementation IndicatorView {
    BOOL isAnimating;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        self.hidden = YES;
    }
    return self;
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(self.bounds.size.width, self.bounds.size.height);
}

- (void)startAnimating {
    self.hidden = NO;
    isAnimating = YES;
    self.layer.speed = 1;
    [self setUpAnimation];
}

- (void)stopAnimating {
    self.hidden = YES;
    isAnimating = NO;
    self.layer.sublayers = nil;
}

- (void)setUpAnimation {
    
    CGRect animationRect = UIEdgeInsetsInsetRect(self.frame, UIEdgeInsetsMake(0, 0, 0, 0));
    CGFloat minEdge = MIN(animationRect.size.width, animationRect.size.height);
    
    self.layer.sublayers = nil;
    CGSize size = CGSizeMake(minEdge, minEdge);
    BallRotate *ballRotate = [[BallRotate alloc] init];
    [ballRotate setupAnimation:self.layer size:size color:[UIColor whiteColor]];
    
}

@end
