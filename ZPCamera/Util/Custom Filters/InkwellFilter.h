#import "GPUImageFilterGroup.h"

@interface Filter10 : GPUImageTwoInputFilter

@end

@interface InkwellFilter : GPUImageFilterGroup
{
    GPUImagePicture *imageSource;
}

@end
