//
//  SMEasyAudioHighShelfNode.h
//  Pods-testAudioEngine
//
//  Created by xiaoxiong on 2019/12/11.
//

#import "SMEasyAudioNode.h"

NS_ASSUME_NONNULL_BEGIN

@interface SMEasyAudioHighShelfNode : SMEasyAudioNode

//! range is from 10000Hz to ($SAMPLERATE/2) Hz. Default is 10000 Hz.
@property (nonatomic) double cutoffFrequency;

//! range is -40dB to 40dB. Default is 0dB.
@property (nonatomic) double gain;

@end

NS_ASSUME_NONNULL_END
