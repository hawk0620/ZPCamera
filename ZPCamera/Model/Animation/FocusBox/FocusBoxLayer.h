//
//  FocusBoxLayer.h
//  ZPCamera
//
//  Created by luoo on 17/2/22.
//  Copyright © 2017年 陈浩. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface FocusBoxLayer : CALayer

- (void)drawaAtPointOfInterest:(CGPoint)point andRemove:(BOOL)remove;

@end
