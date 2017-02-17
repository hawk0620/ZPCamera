#import "GPUImageFilterGroup.h"
#import "SixInputFilter.h"

@interface Filter17 : SixInputFilter

@end

@interface HefeFilter : GPUImageFilterGroup
{
    GPUImagePicture *imageSource1;
    GPUImagePicture *imageSource2;
    GPUImagePicture *imageSource3;
    GPUImagePicture *imageSource4;
    GPUImagePicture *imageSource5;
}

@end
