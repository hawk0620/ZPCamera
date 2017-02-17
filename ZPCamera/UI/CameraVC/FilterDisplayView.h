#import <GPUImage/GPUImage.h>

@interface FilterDisplayView : GPUImageView

@property (nonatomic, assign) BOOL isRecording;
@property (nonatomic, strong) UIImage *img;
@property (nonatomic, assign) CGImageRef imgRef;

@property (nonatomic, strong) GLProgram *gpuDisplayProgram;
@property (nonatomic, strong) GPUImageFramebuffer *gpuInputFramebufferForDisplay;
@property (nonatomic, assign) GLint gpuDisplayInputTextureUniform;
@property (nonatomic, assign) GLfloat gpuBackgroundColorRed;
@property (nonatomic, assign) GLfloat gpuBackgroundColorGreen;
@property (nonatomic, assign) GLfloat gpuBackgroundColorBlue;
@property (nonatomic, assign) GLfloat gpuBackgroundColorAlpha;
@property (nonatomic, assign) CGSize gpuInputImageSize;

@property (nonatomic, assign) GLint gpuDisplayPositionAttribute;
@property (nonatomic, assign) GLint gpuDisplayTextureCoordinateAttribute;

@end
