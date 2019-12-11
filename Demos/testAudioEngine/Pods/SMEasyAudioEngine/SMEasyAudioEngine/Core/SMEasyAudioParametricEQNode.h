//
//  SMEasyAudioParametricEQNode.h
//  Pods-testAudioEngine
//
//  Created by xiaoxiong on 2019/12/11.
//

#import "SMEasyAudioNode.h"

NS_ASSUME_NONNULL_BEGIN

@interface SMEasyAudioParametricEQNode : SMEasyAudioNode

//! range is from 20Hz to ($SAMPLERATE/2) Hz. Default is 2000 Hz.
@property (nonatomic) double centerFrequency;

//! range is from 0.1Hz to 20Hz. Default is 1.0Hz.
@property (nonatomic) double qFactor;

//! range is from -20dB to 20dB. Default is 0dB.
@property (nonatomic) double gain;

@end

NS_ASSUME_NONNULL_END
