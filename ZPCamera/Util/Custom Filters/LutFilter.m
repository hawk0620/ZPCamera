//
//  LutFilter.m
//  ZPCamera
//
//  Created by luoo on 17/1/24.
//  Copyright © 2017年 陈浩. All rights reserved.
//

#import "LutFilter.h"

NSString *const kLUTShaderString = SHADER_STRING
(
 precision lowp float;
 
 precision highp float;
 precision mediump float;
 
 // Uniforms
 uniform sampler2D u_texture;
 uniform sampler2D u_filter_texture;
 uniform float intensity;
 
 varying highp vec2 v_texCoord;
 
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main()
 {
     highp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     
     highp float blueColor = textureColor.b * 63.0;
     
     highp vec2 quad1;
     quad1.y = floor(floor(blueColor) / 8.0);
     quad1.x = floor(blueColor) - (quad1.y * 8.0);
     
     highp vec2 quad2;
     quad2.y = floor(ceil(blueColor) / 8.0);
     quad2.x = ceil(blueColor) - (quad2.y * 8.0);
     
     highp vec2 texPos1;
     texPos1.x = (quad1.x * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.r);
     texPos1.y = (quad1.y * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.g);
     
     highp vec2 texPos2;
     texPos2.x = (quad2.x * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.r);
     texPos2.y = (quad2.y * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.g);
     
     lowp vec4 newColor1 = texture2D(inputImageTexture2, texPos1);
     lowp vec4 newColor2 = texture2D(inputImageTexture2, texPos2);
     
     lowp vec4 newColor = mix(newColor1, newColor2, fract(blueColor));
     gl_FragColor = vec4(newColor.rgb, textureColor.w);
     
//     vec3 texel = texture2D(inputImageTexture, textureCoordinate).rgb;
//     texel = vec3(
//                  texture2D(inputImageTexture2, vec2(texel.r, .16666)).r,
//                  texture2D(inputImageTexture2, vec2(texel.g, .5)).g,
//                  texture2D(inputImageTexture2, vec2(texel.b, .83333)).b);
//     gl_FragColor = vec4(texel, 1.0);
 }
 );

@implementation GLFilter1

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kLUTShaderString]))
    {
        return nil;
    }
    
    return self;
}

@end

@implementation LutFilter

- (id)initWithImage:(UIImage *)image_
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    UIImage *image = image_;// [UIImage imageNamed:imageName];
    
    imageSource = [[GPUImagePicture alloc] initWithImage:image];
//    GLFilter1 *filter = [[GLFilter1 alloc] init];
    
    GPUImageLookupFilter *filter = [[GPUImageLookupFilter alloc] init];
    
    [self addFilter:filter];
    
    [imageSource addTarget:filter atTextureLocation:1];
    [imageSource processImage];
    
    self.initialFilters = [NSArray arrayWithObjects:filter, nil];
    self.terminalFilter = filter;
    
    return self;
}

@end
