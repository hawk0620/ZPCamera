//
//  Constants.h
//  Records
//
//  Created by 陈浩 on 15/8/29.
//  Copyright (c) 2015年 陈浩. All rights reserved.
//

#ifndef Records_Constants_h
#define Records_Constants_h
#import <Foundation/Foundation.h>
#import "nsuserdefaults-macros.h"
#import <GPUImage/GPUImage.h>
#import "GPUImageFourInputFilter.h"
#import "UIView+frameAdjust.h"
#import "extobjc.h"
#import "ZPKit.h"

#define ScreenBounds [UIScreen mainScreen].bounds
#define ScreenHeight ScreenBounds.size.height
#define ScreenWidth ScreenBounds.size.width

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#define UIColorFromRGBWithAlpha(rgbValue, a) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:a]

#define IS_IPHONE_4 (fabs((double)[[UIScreen mainScreen]bounds].size.height - (double)480) < DBL_EPSILON)
#define IS_IPHONE_5 (fabs((double)[[UIScreen mainScreen]bounds].size.height - (double)568) < DBL_EPSILON)
#define IS_IPHONE_6 (fabs((double)[[UIScreen mainScreen]bounds].size.height - (double)667) < DBL_EPSILON)
#define IS_IPHONE_6P (fabs((double)[[UIScreen mainScreen]bounds].size.height - (double)736) < DBL_EPSILON)

#define kIOSVersion [[UIDevice currentDevice].systemVersion doubleValue]

#define dispatch_handler(x) if (x != nil) dispatch_async(dispatch_get_main_queue(), x)

#define DEGREES_TO_RADIANS(degrees)  ((3.14159265359 * degrees)/ 180)

#define kScale ScreenWidth/320.0
#define HIDDLEVIEWCONSTANT 94949

#define kFlashState @"___kFlashState___"
#define kScaleState @"___kScaleState___"
#define kRecorderRecordSessionQueueKey "RecorderRecordSessionQueue"

typedef void (^VoidResultBlock)(id object);

typedef void(^MergeCompleteBlock)(NSString*);

#endif
