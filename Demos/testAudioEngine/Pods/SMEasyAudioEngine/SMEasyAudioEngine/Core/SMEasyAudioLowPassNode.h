//
//  SMEasyAudioLowPassNode.h
//  Pods-testAudioEngine
//
//  Created by xiaoxiong on 2019/12/11.
//

#import "SMEasyAudioNode.h"

NS_ASSUME_NONNULL_BEGIN

@interface SMEasyAudioLowPassNode : SMEasyAudioNode

//! range is from 10Hz to ($SAMPLERATE/2) Hz. Default is 6900 Hz.
@property (nonatomic) double cutoffFrequency;

//! range is -20dB to 40dB. Default is 0dB.
@property (nonatomic) double resonance;


@end

NS_ASSUME_NONNULL_END
