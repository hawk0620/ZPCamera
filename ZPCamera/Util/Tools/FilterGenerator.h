#import <Foundation/Foundation.h>

@interface FilterGenerator : NSObject

+ (GPUImageOutput<GPUImageInput> *)generateFilterByName:(NSString *)filterName type:(NSString *)filterType;

@end
