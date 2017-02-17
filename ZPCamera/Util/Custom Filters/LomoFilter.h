#import "GPUImageFilterGroup.h"

@interface Filter6 : GPUImageThreeInputFilter

@end

@interface LomoFilter : GPUImageFilterGroup
{
    GPUImagePicture *imageSource1;
    GPUImagePicture *imageSource2;
}

@end
