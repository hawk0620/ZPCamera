#import "GPUImageFilterGroup.h"

@interface Filter2 : GPUImageTwoInputFilter

@end

@interface LordKelvinFilter : GPUImageFilterGroup
{
    GPUImagePicture *imageSource;
}

@end
