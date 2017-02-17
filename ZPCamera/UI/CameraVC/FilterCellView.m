#import "FilterCellView.h"
#import "Constants.h"

@interface FilterCellView ()

@property (nonatomic, assign) CGFloat bgWidth;

@end

@implementation FilterCellView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        if (IS_IPHONE_6P) {
            self.bgWidth = 68;
        } else {
            self.bgWidth = 56;
        }
        
        [self.contentView.layer addSublayer:self.backgroundLayer];
        [self.backgroundLayer addSublayer:self.overlayLayer];
        
        [self.backgroundLayer addSublayer:self.labelBGLayer];
        [self.backgroundLayer addSublayer:self.label.layer];
    }
    return self;
}

- (UILabel *)label {
    if (!_label) {
        _label = [[UILabel alloc] initWithFrame:(CGRect){0, self.bgWidth - 14, self.bgWidth, 14}];
        _label.textAlignment = NSTextAlignmentCenter;
        _label.font = [UIFont systemFontOfSize:10];
        _label.textColor = [UIColor whiteColor];
        
    }
    return _label;
}

- (CALayer *)backgroundLayer {
    if (!_backgroundLayer) {
        _backgroundLayer = [[CALayer alloc] init];
        _backgroundLayer.frame = (CGRect){0, 0, self.bgWidth, self.bgWidth};
    }
    return _backgroundLayer;
}

- (CALayer *)overlayLayer {
    if (!_overlayLayer) {
        _overlayLayer = [[CALayer alloc] init];
        _overlayLayer.frame = (CGRect){0, 0, self.bgWidth, self.bgWidth};
        _overlayLayer.hidden = YES;
        _overlayLayer.opacity = 0.8;
        
        UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:(CGRect){0, 0, self.bgWidth, self.bgWidth} byRoundingCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(4, 4)];
        
        CAShapeLayer *maskLayer = [CAShapeLayer layer];
        maskLayer.frame = (CGRect){0, 0, self.bgWidth, self.bgWidth};
        maskLayer.path = maskPath.CGPath;
        _overlayLayer.mask = maskLayer;
    }
    return _overlayLayer;
}

- (CALayer *)labelBGLayer {
    if (!_labelBGLayer) {
        _labelBGLayer = [[CALayer alloc] init];
        _labelBGLayer.frame = (CGRect){0, self.bgWidth - 14, self.bgWidth, 14};
        _labelBGLayer.opacity = 0.8;
//        _labelBGLayer.contents = (__bridge id _Nullable)([UIImage imageNamed:@"r"].CGImage);
    }
    return _labelBGLayer;
}

//- (UIView *)bgView {
//    if (!_bgView) {
//        _bgView = [[UIView alloc] initWithFrame:(CGRect){0, self.bgWidth - 14, self.bgWidth, 14}];
//        _bgView.alpha = 0.8;
//        _bgView.backgroundColor = UIColorFromRGB(0x1a1c1f);
//    }
//    return _bgView;
//}

- (UIImageView *)dotImgView {
    if (!_dotImgView) {
        _dotImgView = [[UIImageView alloc] init];
    }
    return _dotImgView;
}

- (void)configWithFilter:(NSDictionary *)filter {
    self.label.text = filter[@"name"];
    
    NSBundle *bundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"FilterThum" ofType:@"bundle"]];
    NSString *thumPath = [bundle pathForResource:[NSString stringWithFormat:@"%@", filter[@"filter"]] ofType:@"png"];
    
    self.backgroundLayer.contents = (__bridge id _Nullable)([UIImage imageWithContentsOfFile:thumPath].CGImage);
    
    NSString *hexValue = filter[@"color"];
    unsigned int outVal;
    NSScanner* scanner = [NSScanner scannerWithString:hexValue];
    [scanner scanHexInt:&outVal];
    
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:(CGRect){0, 0, self.bgWidth, 14} byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight cornerRadii:CGSizeMake(4, 4)];
    
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.frame = (CGRect){0, 0, self.bgWidth, 14};
    maskLayer.path = maskPath.CGPath;
    self.labelBGLayer.mask = maskLayer;
    
    self.labelBGLayer.backgroundColor = [UIColorFromRGB(outVal) CGColor];
    self.overlayLayer.backgroundColor = [UIColorFromRGB(outVal) CGColor];
}

@end
