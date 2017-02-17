#import "GPUImageFilterGroup.h"

@interface Filter11 : GPUImageFourInputFilter

@end

@interface SierraFilter : GPUImageFilterGroup
{
    GPUImagePicture *imageSource1;
    GPUImagePicture *imageSource2;
    GPUImagePicture *imageSource3;
}

@end
