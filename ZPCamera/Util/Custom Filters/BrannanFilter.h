#import "GPUImageFilterGroup.h"
#import "SixInputFilter.h"

@interface Filter16 : SixInputFilter

@end

@interface BrannanFilter : GPUImageFilterGroup
{
    GPUImagePicture *imageSource1;
    GPUImagePicture *imageSource2;
    GPUImagePicture *imageSource3;
    GPUImagePicture *imageSource4;
    GPUImagePicture *imageSource5;
}

@end
