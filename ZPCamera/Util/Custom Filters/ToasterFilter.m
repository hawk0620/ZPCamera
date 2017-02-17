#import "ToasterFilter.h"

NSString *const kFWToasterShaderString = SHADER_STRING
(
 precision lowp float;
 
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2; //toasterMetal
 uniform sampler2D inputImageTexture3; //toasterSoftlight
 uniform sampler2D inputImageTexture4; //toasterCurves
 uniform sampler2D inputImageTexture5; //toasterOverlayMapWarm
 uniform sampler2D inputImageTexture6; //toasterColorshift
 
 void main()
 {
     lowp vec3 texel;
     mediump vec2 lookup;
     vec2 blue;
     vec2 green;
     vec2 red;
     lowp vec4 tmpvar_1;
     tmpvar_1 = texture2D (inputImageTexture, textureCoordinate);
     texel = tmpvar_1.xyz;
     lowp vec4 tmpvar_2;
     tmpvar_2 = texture2D (inputImageTexture2, textureCoordinate);
     lowp vec2 tmpvar_3;
     tmpvar_3.x = tmpvar_2.x;
     tmpvar_3.y = tmpvar_1.x;
     texel.x = texture2D (inputImageTexture3, tmpvar_3).x;
     lowp vec2 tmpvar_4;
     tmpvar_4.x = tmpvar_2.y;
     tmpvar_4.y = tmpvar_1.y;
     texel.y = texture2D (inputImageTexture3, tmpvar_4).y;
     lowp vec2 tmpvar_5;
     tmpvar_5.x = tmpvar_2.z;
     tmpvar_5.y = tmpvar_1.z;
     texel.z = texture2D (inputImageTexture3, tmpvar_5).z;
     red.x = texel.x;
     red.y = 0.16666;
     green.x = texel.y;
     green.y = 0.5;
     blue.x = texel.z;
     blue.y = 0.833333;
     texel.x = texture2D (inputImageTexture4, red).x;
     texel.y = texture2D (inputImageTexture4, green).y;
     texel.z = texture2D (inputImageTexture4, blue).z;
     mediump vec2 tmpvar_6;
     tmpvar_6 = ((2.0 * textureCoordinate) - 1.0);
     mediump vec2 tmpvar_7;
     tmpvar_7.x = dot (tmpvar_6, tmpvar_6);
     tmpvar_7.y = texel.x;
     lookup = tmpvar_7;
     texel.x = texture2D (inputImageTexture5, tmpvar_7).x;
     lookup.y = texel.y;
     texel.y = texture2D (inputImageTexture5, lookup).y;
     lookup.y = texel.z;
     texel.z = texture2D (inputImageTexture5, lookup).z;
     red.x = texel.x;
     green.x = texel.y;
     blue.x = texel.z;
     texel.x = texture2D (inputImageTexture6, red).x;
     texel.y = texture2D (inputImageTexture6, green).y;
     texel.z = texture2D (inputImageTexture6, blue).z;
     lowp vec4 tmpvar_8;
     tmpvar_8.w = 1.0;
     tmpvar_8.xyz = texel;
     gl_FragColor = tmpvar_8;
 }
 );

@implementation Filter15

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kFWToasterShaderString]))
    {
        return nil;
    }
    
    return self;
}

@end

@implementation ToasterFilter

- (id)init
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    Filter15 *filter = [[Filter15 alloc] init];
    [self addFilter:filter];
    
    UIImage *image = [UIImage imageNamed:@"toasterMetal"];
    imageSource1 = [[GPUImagePicture alloc] initWithImage:image];
    [imageSource1 addTarget:filter atTextureLocation:1];
    [imageSource1 processImage];
    
    UIImage *image1 = [UIImage imageNamed:@"toasterSoftLight"];
    imageSource2 = [[GPUImagePicture alloc] initWithImage:image1];
    [imageSource2 addTarget:filter atTextureLocation:2];
    [imageSource2 processImage];
    
    UIImage *image2 = [UIImage imageNamed:@"toasterCurves"];
    imageSource3 = [[GPUImagePicture alloc] initWithImage:image2];
    [imageSource3 addTarget:filter atTextureLocation:3];
    [imageSource3 processImage];
    
    UIImage *image3 = [UIImage imageNamed:@"toasterOverlayMapWarm"];
    imageSource4 = [[GPUImagePicture alloc] initWithImage:image3];
    [imageSource4 addTarget:filter atTextureLocation:4];
    [imageSource4 processImage];
    
    UIImage *image4 = [UIImage imageNamed:@"toasterColorShift"];
    imageSource5 = [[GPUImagePicture alloc] initWithImage:image4];
    [imageSource5 addTarget:filter atTextureLocation:5];
    [imageSource5 processImage];
    
    self.initialFilters = [NSArray arrayWithObjects:filter, nil];
    self.terminalFilter = filter;
    
    return self;
}

@end
