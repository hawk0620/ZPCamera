#import "BallRotate.h"

@implementation BallRotate

- (CALayer *)layerWithSize:(CGSize)size color:(UIColor *)color {
    CAShapeLayer *layer = [[CAShapeLayer alloc] init];
    UIBezierPath *path = [[UIBezierPath alloc] init];
//    CGFloat lineWidth = 2.0;
    
    [path addArcWithCenter:CGPointMake(size.width / 2.0, size.height / 2.0) radius:(size.width / 2.0) startAngle:0 endAngle:(2 * M_PI) clockwise:NO];
    layer.fillColor = [color CGColor];
    layer.backgroundColor = nil;
    layer.path = [path CGPath];
    layer.frame = CGRectMake(0, 0, size.width, size.height);
    return layer;
}

- (void)setupAnimation:(CALayer *)layer size:(CGSize)size color:(UIColor *)color {
    CGFloat circleSize = size.width / 5.0;
    for (int i = 0; i < 5; i++) {
        CGFloat factor = i * 1.0 / 5.0;
        CALayer *circle = [self layerWithSize:CGSizeMake(circleSize, circleSize) color:color];
        
        CAAnimationGroup *animation = [self rotateAnimation:factor x:layer.bounds.size.width / 2.0 y:layer.bounds.size.height / 2.0 size:(CGSize){size.width - circleSize, size.height - circleSize}];
        circle.frame = CGRectMake(0, 0, circleSize, circleSize);
        [circle addAnimation:animation forKey:@"animation"];
        [layer addSublayer:circle];
    }
}

- (CAAnimationGroup *)rotateAnimation:(CGFloat)rate
                                    x:(CGFloat)x
                                    y:(CGFloat)y
                                 size:(CGSize)size {
    CFTimeInterval duration = 1.5;
    CGFloat fromScale = 1 - rate;
    CGFloat toScale = 0.2 + rate;
    CAMediaTimingFunction *timeFunc = [CAMediaTimingFunction functionWithControlPoints:0.5 :0.15 + rate :0.25 :1.0];
    
    CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scaleAnimation.duration = duration;
    scaleAnimation.repeatCount = HUGE;
    scaleAnimation.fromValue = @(fromScale);
    scaleAnimation.toValue = @(toScale);
    
    CAKeyframeAnimation *positionAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    positionAnimation.duration = duration;
    positionAnimation.repeatCount = HUGE;
    positionAnimation.path = [[UIBezierPath bezierPathWithArcCenter:(CGPoint){x, y} radius:size.width / 2.0 startAngle:3 * M_PI * 0.5 endAngle: 3 * M_PI * 0.5 + 2 * M_PI clockwise:YES] CGPath];
    
    CAAnimationGroup *animation = [[CAAnimationGroup alloc] init];
    animation.animations = @[scaleAnimation, positionAnimation];
    animation.timingFunction = timeFunc;
    animation.duration = duration;
    animation.repeatCount = HUGE;
    animation.removedOnCompletion = NO;
    
    return animation;
}

@end

