#import "GPUImageFilterGroup.h"
#import "SixInputFilter.h"

@interface Filter13 : SixInputFilter

@end

@interface EarlybirdFilter : GPUImageFilterGroup
{
    GPUImagePicture *imageSource1;
    GPUImagePicture *imageSource2;
    GPUImagePicture *imageSource3;
    GPUImagePicture *imageSource4;
    GPUImagePicture *imageSource5;
}

@end
