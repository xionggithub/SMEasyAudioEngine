#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <TheAmazingAudioEngine/TheAmazingAudioEngine.h>


@interface SMAudioEngine : NSObject
- (instancetype)initEngine;
- (void)startPlay;
- (void)stopPlay;
- (void)setGain:(CGFloat)gain;
- (CGFloat)gain;
@end
