#import "FilterGenerator.h"

@implementation FilterGenerator

+ (GPUImageOutput<GPUImageInput> *)generateFilterByName:(NSString *)filterName type:(NSString *)filterType {
    GPUImageOutput<GPUImageInput> *filter;
    if ([filterType isEqual: @"1"]) {
        Class class = NSClassFromString(filterName);
        filter = [[class alloc] init];
        
    } else if([filterType isEqual: @"2"]) {
        NSBundle *bundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"Osho" ofType:@"bundle"]]; //[NSBundle bundleForClass:self.class];
        NSURL *filterURL = [NSURL fileURLWithPath:[bundle pathForResource:[NSString stringWithFormat:@"acv/%@", filterName] ofType:@"acv"]];
        filter = [[GPUImageToneCurveFilter alloc] initWithACVURL:filterURL];
        
    }
    
    return filter;
}

@end
