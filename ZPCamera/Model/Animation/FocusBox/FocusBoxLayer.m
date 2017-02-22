//
//  FocusBoxLayer.m
//  ZPCamera
//
//  Created by luoo on 17/2/22.
//  Copyright © 2017年 陈浩. All rights reserved.
//

#import "FocusBoxLayer.h"

@implementation FocusBoxLayer

- (instancetype)init {
    if (self = [super init]) {
        [self setCornerRadius:45.0f];
        [self setBounds:CGRectMake(0.0f, 0.0f, 90, 90)];
        [self setBorderWidth:5.f];
        [self setBorderColor:[UIColorFromRGB(0xffffff) CGColor]];
        [self setOpacity:0];
    }
    return self;
}

- (void)drawaAtPointOfInterest:(CGPoint)point andRemove:(BOOL)remove {
    if ( remove )
        [self removeAllAnimations];
    
    if ( [self animationForKey:@"transform.scale"] == nil && [self animationForKey:@"opacity"] == nil ) {
        [CATransaction begin];
        [CATransaction setValue: (id) kCFBooleanTrue forKey: kCATransactionDisableActions];
        [self setPosition:point];
        [CATransaction commit];
        
        CABasicAnimation *scale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
        [scale setFromValue:[NSNumber numberWithFloat:1]];
        [scale setToValue:[NSNumber numberWithFloat:0.7]];
        [scale setDuration:0.8];
        [scale setRemovedOnCompletion:YES];
        
        CABasicAnimation *opacity = [CABasicAnimation animationWithKeyPath:@"opacity"];
        [opacity setFromValue:[NSNumber numberWithFloat:1]];
        [opacity setToValue:[NSNumber numberWithFloat:0]];
        [opacity setDuration:0.8];
        [opacity setRemovedOnCompletion:YES];
        
        [self addAnimation:scale forKey:@"transform.scale"];
        [self addAnimation:opacity forKey:@"opacity"];
    }
}

@end
