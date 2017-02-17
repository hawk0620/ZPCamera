#import "GPUImageFilterGroup.h"

@interface Filter3 : GPUImageFourInputFilter

@end

@interface AmaroFilter : GPUImageFilterGroup
{
    GPUImagePicture *imageSource1;
    GPUImagePicture *imageSource2;
    GPUImagePicture *imageSource3;
}

@end
