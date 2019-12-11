//
//  SMEasyAudioPeakLimiterNode.h
//  Pods-testAudioEngine
//
//  Created by xiaoxiong on 2019/12/11.
//

#import "SMEasyAudioNode.h"

NS_ASSUME_NONNULL_BEGIN

@interface SMEasyAudioPeakLimiterNode : SMEasyAudioNode

//! range is from 0.001 to 0.03 seconds. Default is 0.012 seconds.
@property (nonatomic) double attackTime;

//! range is from 0.001 to 0.06 seconds. Default is 0.024 seconds.
@property (nonatomic) double decayTime;

//! range is from -40dB to 40dB. Default is 0dB.
@property (nonatomic) double preGain;

@end

NS_ASSUME_NONNULL_END
