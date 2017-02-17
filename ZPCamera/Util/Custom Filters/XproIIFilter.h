#import "GPUImageFilterGroup.h"

@interface Filter12 : GPUImageThreeInputFilter

@end

@interface XproIIFilter : GPUImageFilterGroup
{
    GPUImagePicture *imageSource1;
    GPUImagePicture *imageSource2;
}

@end
