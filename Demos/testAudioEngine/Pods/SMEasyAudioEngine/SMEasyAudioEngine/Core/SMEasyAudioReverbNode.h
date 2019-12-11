//
//  SMEasyAudioReverbNode.h
//  Pods-testAudioEngine
//
//  Created by xiaoxiong on 2019/12/11.
//

#import "SMEasyAudioNode.h"

NS_ASSUME_NONNULL_BEGIN

@interface SMEasyAudioReverbNode : SMEasyAudioNode

//! range is from 0 to 100 (percentage). Default is 0.
@property (nonatomic) double dryWetMix;

//! range is from -20dB to 20dB. Default is 0dB.
@property (nonatomic) double gain;

//! range is from 0.0001 to 1.0 seconds. Default is 0.008 seconds.
@property (nonatomic) double minDelayTime;

//! range is from 0.0001 to 1.0 seconds. Default is 0.050 seconds.
@property (nonatomic) double maxDelayTime;

//! range is from 0.001 to 20.0 seconds. Default is 1.0 seconds.
@property (nonatomic) double decayTimeAt0Hz;

//! range is from 0.001 to 20.0 seconds. Default is 0.5 seconds.
@property (nonatomic) double decayTimeAtNyquist;

//! range is from 1 to 1000 (unitless). Default is 1.
@property (nonatomic) double randomizeReflections;


@end

NS_ASSUME_NONNULL_END
