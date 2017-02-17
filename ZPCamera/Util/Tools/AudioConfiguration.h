#import <Foundation/Foundation.h>
#import "MediaTypeConfiguration.h"

#define kSCAudioConfigurationDefaultBitrate 128000
#define kSCAudioConfigurationDefaultNumberOfChannels 2
#define kSCAudioConfigurationDefaultSampleRate 44100
#define kSCAudioConfigurationDefaultAudioFormat kAudioFormatMPEG4AAC

@interface AudioConfiguration : MediaTypeConfiguration

/**
 Set the sample rate of the audio
 If set to 0, the original sample rate will be used.
 If options has been changed, this property will be ignored
 */
@property (assign, nonatomic) int sampleRate;

/**
 Set the number of channels
 If set to 0, the original channels number will be used.
 If options is not nil, this property will be ignored
 */
@property (assign, nonatomic) int channelsCount;

/**
 Must be like kAudioFormat* (example kAudioFormatMPEGLayer3)
 If options is not nil, this property will be ignored
 */
@property (assign, nonatomic) int format;

/**
 The audioMix to apply.
 
 Only used in SCAssetExportSession.
 */
@property (strong, nonatomic) AVAudioMix *__nullable audioMix;

@end
