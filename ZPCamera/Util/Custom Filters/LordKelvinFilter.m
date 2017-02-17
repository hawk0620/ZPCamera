NSString *const kFWLordKelvinShaderString = SHADER_STRING
(
 precision lowp float;
 
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main()
 {
     vec3 texel = texture2D(inputImageTexture, textureCoordinate).rgb;
     
     vec2 lookup;
     lookup.y = .5;
     
     lookup.x = texel.r;
     texel.r = texture2D(inputImageTexture2, lookup).r;
     
     lookup.x = texel.g;
     texel.g = texture2D(inputImageTexture2, lookup).g;
     
     lookup.x = texel.b;
     texel.b = texture2D(inputImageTexture2, lookup).b;
     
     gl_FragColor = vec4(texel, 1.0);
 }
 );

#import "LordKelvinFilter.h"

@implementation Filter2

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kFWLordKelvinShaderString]))
    {
        return nil;
    }
    
    return self;
}

@end

@implementation LordKelvinFilter

- (id)init
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    UIImage *image = [UIImage imageNamed:@"kelvinMap.png"];
    
    imageSource = [[GPUImagePicture alloc] initWithImage:image];
    Filter2 *filter = [[Filter2 alloc] init];
    
    [self addFilter:filter];
    [imageSource addTarget:filter atTextureLocation:1];
    [imageSource processImage];
    
    self.initialFilters = [NSArray arrayWithObjects:filter, nil];
    self.terminalFilter = filter;
    
    return self;
}

@end
