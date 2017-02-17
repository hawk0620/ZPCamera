#import "InkwellFilter.h"

NSString *const kFWInkWellShaderString = SHADER_STRING
(
 precision lowp float;
 
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main()
 {
     vec3 texel = texture2D(inputImageTexture, textureCoordinate).rgb;
     texel = vec3(dot(vec3(0.3, 0.6, 0.1), texel));
     texel = vec3(texture2D(inputImageTexture2, vec2(texel.r, .16666)).r);
     gl_FragColor = vec4(texel, 1.0);
 }
 );

@implementation Filter10

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kFWInkWellShaderString]))
    {
        return nil;
    }
    
    return self;
}

@end

@implementation InkwellFilter

- (id)init
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    UIImage *image = [UIImage imageNamed:@"inkwellMap"];
    
    imageSource = [[GPUImagePicture alloc] initWithImage:image];
    Filter10 *filter = [[Filter10 alloc] init];
    
    [self addFilter:filter];
    [imageSource addTarget:filter atTextureLocation:1];
    [imageSource processImage];
    
    self.initialFilters = [NSArray arrayWithObjects:filter, nil];
    self.terminalFilter = filter;
    
    return self;
}

@end
