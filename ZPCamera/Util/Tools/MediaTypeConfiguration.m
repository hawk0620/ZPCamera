#import "MediaTypeConfiguration.h"

@implementation MediaTypeConfiguration

const NSString *SCPresetHighestQuality = @"HighestQuality";
const NSString *SCPresetMediumQuality = @"MediumQuality";
const NSString *SCPresetLowQuality = @"LowQuality";

- (id)init {
    self = [super init];
    
    if (self) {
        _enabled = YES;
    }
    
    return self;
}

- (NSDictionary *)createAssetWriterOptionsUsingSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    return nil;
}

- (void)setEnabled:(BOOL)enabled {
    if (_enabled != enabled) {
        [self willChangeValueForKey:@"enabled"];
        _enabled = enabled;
        [self didChangeValueForKey:@"enabled"];
    }
}

@end
