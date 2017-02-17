#import "HefeFilter.h"

NSString *const kFWHefeShaderString = SHADER_STRING
(
 precision lowp float;
 
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;  //edgeBurn
 uniform sampler2D inputImageTexture3;  //hefeMap
 uniform sampler2D inputImageTexture4;  //hefeGradientMap
 uniform sampler2D inputImageTexture5;  //hefeSoftLight
 uniform sampler2D inputImageTexture6;  //hefeMetal
 
 void main()
{
    vec3 texel = texture2D(inputImageTexture, textureCoordinate).rgb;
    vec3 edge = texture2D(inputImageTexture2, textureCoordinate).rgb;
    texel = texel * edge;
    
    texel = vec3(
                 texture2D(inputImageTexture3, vec2(texel.r, .16666)).r,
                 texture2D(inputImageTexture3, vec2(texel.g, .5)).g,
                 texture2D(inputImageTexture3, vec2(texel.b, .83333)).b);
    
    vec3 luma = vec3(.30, .59, .11);
    vec3 gradSample = texture2D(inputImageTexture4, vec2(dot(luma, texel), .5)).rgb;
    vec3 final = vec3(
                      texture2D(inputImageTexture5, vec2(gradSample.r, texel.r)).r,
                      texture2D(inputImageTexture5, vec2(gradSample.g, texel.g)).g,
                      texture2D(inputImageTexture5, vec2(gradSample.b, texel.b)).b
                      );
    
    vec3 metal = texture2D(inputImageTexture6, textureCoordinate).rgb;
    vec3 metaled = vec3(
                        texture2D(inputImageTexture5, vec2(metal.r, texel.r)).r,
                        texture2D(inputImageTexture5, vec2(metal.g, texel.g)).g,
                        texture2D(inputImageTexture5, vec2(metal.b, texel.b)).b
                        );
    
    gl_FragColor = vec4(metaled, 1.0);
}
 );


@implementation Filter17

- (id)init
{
    if (!(self = [super initWithFragmentShaderFromString:kFWHefeShaderString]))
    {
        return nil;
    }
    
    return self;
}

@end

@implementation HefeFilter

- (id)init
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    Filter17 *filter = [[Filter17 alloc] init];
    [self addFilter:filter];
    
    UIImage *image = [UIImage imageNamed:@"edgeBurn"];
    imageSource1 = [[GPUImagePicture alloc] initWithImage:image];
    [imageSource1 addTarget:filter atTextureLocation:1];
    [imageSource1 processImage];
    
    UIImage *image1 = [UIImage imageNamed:@"hefeMap"];
    imageSource2 = [[GPUImagePicture alloc] initWithImage:image1];
    [imageSource2 addTarget:filter atTextureLocation:2];
    [imageSource2 processImage];
    
    UIImage *image2 = [UIImage imageNamed:@"hefeGradientMap"];
    imageSource3 = [[GPUImagePicture alloc] initWithImage:image2];
    [imageSource3 addTarget:filter atTextureLocation:3];
    [imageSource3 processImage];
    
    UIImage *image3 = [UIImage imageNamed:@"hefeSoftLight"];
    imageSource4 = [[GPUImagePicture alloc] initWithImage:image3];
    [imageSource4 addTarget:filter atTextureLocation:4];
    [imageSource4 processImage];
    
    UIImage *image4 = [UIImage imageNamed:@"hefeMetal"];
    imageSource5 = [[GPUImagePicture alloc] initWithImage:image4];
    [imageSource5 addTarget:filter atTextureLocation:5];
    [imageSource5 processImage];
    
    self.initialFilters = [NSArray arrayWithObjects:filter, nil];
    self.terminalFilter = filter;
    
    return self;
}

@end
