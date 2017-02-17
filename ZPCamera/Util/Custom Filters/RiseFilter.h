#import "GPUImageFilterGroup.h"

@interface Filter4 : GPUImageFourInputFilter

@end

@interface RiseFilter : GPUImageFilterGroup
{
    GPUImagePicture *imageSource1;
    GPUImagePicture *imageSource2;
    GPUImagePicture *imageSource3;
}

@end
