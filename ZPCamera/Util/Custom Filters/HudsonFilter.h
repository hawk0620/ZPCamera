#import "GPUImageFilterGroup.h"

@interface Filter5 : GPUImageFourInputFilter

@end

@interface HudsonFilter : GPUImageFilterGroup
{
    GPUImagePicture *imageSource1;
    GPUImagePicture *imageSource2;
    GPUImagePicture *imageSource3;
}

@end
