//
//  SMEasyAudioLowShelfNode.h
//  Pods-testAudioEngine
//
//  Created by xiaoxiong on 2019/12/11.
//

#import "SMEasyAudioNode.h"

NS_ASSUME_NONNULL_BEGIN

@interface SMEasyAudioLowShelfNode : SMEasyAudioNode
//! range is from 10Hz to 200Hz. Default is 80Hz.
@property (nonatomic) double cutoffFrequency;

//! range is -40dB to 40dB. Default is 0dB.
@property (nonatomic) double gain;

@end

NS_ASSUME_NONNULL_END
