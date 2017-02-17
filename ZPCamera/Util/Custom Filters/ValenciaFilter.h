#import "GPUImageFilterGroup.h"

@interface Filter8 : GPUImageThreeInputFilter

@end

@interface ValenciaFilter : GPUImageFilterGroup
{
    GPUImagePicture *imageSource1;
    GPUImagePicture *imageSource2;
}

@end
