#import "BrannanFilter.h"

NSString *const kFWBrannanShaderString = SHADER_STRING
(
 precision lowp float;
 
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;  //process
 uniform sampler2D inputImageTexture3;  //blowout
 uniform sampler2D inputImageTexture4;  //contrast
 uniform sampler2D inputImageTexture5;  //luma
 uniform sampler2D inputImageTexture6;  //screen
 
 mat3 saturateMatrix = mat3(
                            1.105150,
                            -0.044850,
                            -0.046000,
                            -0.088050,
                            1.061950,
                            -0.089200,
                            -0.017100,
                            -0.017100,
                            1.132900);
 
 vec3 luma = vec3(.3, .59, .11);
 
 void main()
 {
     
     vec3 texel = texture2D(inputImageTexture, textureCoordinate).rgb;
     
     vec2 lookup;
     lookup.y = 0.5;
     lookup.x = texel.r;
     texel.r = texture2D(inputImageTexture2, lookup).r;
     lookup.x = texel.g;
     texel.g = texture2D(inputImageTexture2, lookup).g;
     lookup.x = texel.b;
     texel.b = texture2D(inputImageTexture2, lookup).b;
     
     texel = saturateMatrix * texel;
     
     
     vec2 tc = (2.0 * textureCoordinate) - 1.0;
     float d = dot(tc, tc);
     vec3 sampled;
     lookup.y = 0.5;
     lookup.x = texel.r;
     sampled.r = texture2D(inputImageTexture3, lookup).r;
     lookup.x = texel.g;
     sampled.g = texture2D(inputImageTexture3, lookup).g;
     lookup.x = texel.b;
     sampled.b = texture2D(inputImageTexture3, lookup).b;
     float value = smoothstep(0.0, 1.0, d);
     texel = mix(sampled, texel, value);
     
     lookup.x = texel.r;
     texel.r = texture2D(inputImageTexture4, lookup).r;
     lookup.x = texel.g;
     texel.g = texture2D(inputImageTexture4, lookup).g;
     lookup.x = texel.b;
     texel.b = texture2D(inputImageTexture4, lookup).b;
     
     
     lookup.x = dot(texel, luma);
     texel = mix(texture2D(inputImageTexture5, lookup).rgb, texel, .5);
     
     lookup.x = texel.r;
     texel.r = texture2D(inputImageTexture6, lookup).r;
     lookup.x = texel.g;
     texel.g = texture2D(inputImageTexture6, lookup).g;
     lookup.x = texel.b;
     texel.b = texture2D(inputImageTexture6, lookup).b;
     
     gl_FragColor = vec4(texel, 1.0);
 }
 );


@implementation Filter16

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kFWBrannanShaderString]))
    {
        return nil;
    }
    
    return self;
}

@end

@implementation BrannanFilter

- (id)init
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    Filter16 *filter = [[Filter16 alloc] init];
    [self addFilter:filter];
    
    UIImage *image = [UIImage imageNamed:@"brannanProcess"];
    imageSource1 = [[GPUImagePicture alloc] initWithImage:image];
    [imageSource1 addTarget:filter atTextureLocation:1];
    [imageSource1 processImage];
    
    UIImage *image1 = [UIImage imageNamed:@"brannanBlowout"];
    imageSource2 = [[GPUImagePicture alloc] initWithImage:image1];
    [imageSource2 addTarget:filter atTextureLocation:2];
    [imageSource2 processImage];
    
    UIImage *image2 = [UIImage imageNamed:@"brannanContrast"];
    imageSource3 = [[GPUImagePicture alloc] initWithImage:image2];
    [imageSource3 addTarget:filter atTextureLocation:3];
    [imageSource3 processImage];
    
    UIImage *image3 = [UIImage imageNamed:@"brannanLuma"];
    imageSource4 = [[GPUImagePicture alloc] initWithImage:image3];
    [imageSource4 addTarget:filter atTextureLocation:4];
    [imageSource4 processImage];
    
    UIImage *image4 = [UIImage imageNamed:@"brannanScreen"];
    imageSource5 = [[GPUImagePicture alloc] initWithImage:image4];
    [imageSource5 addTarget:filter atTextureLocation:5];
    [imageSource5 processImage];
    
    self.initialFilters = [NSArray arrayWithObjects:filter, nil];
    self.terminalFilter = filter;
    
    return self;
}

@end
