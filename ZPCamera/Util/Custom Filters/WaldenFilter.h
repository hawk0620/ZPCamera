#import "GPUImageFilterGroup.h"

@interface Filter7 : GPUImageThreeInputFilter

@end

@interface WaldenFilter : GPUImageFilterGroup
{
    GPUImagePicture *imageSource1;
    GPUImagePicture *imageSource2;
}

@end
