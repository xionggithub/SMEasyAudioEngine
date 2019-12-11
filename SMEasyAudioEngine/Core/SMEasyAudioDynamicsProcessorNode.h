//
//  SMEasyAudioDynamicsProcessorNode.h
//  Pods-testAudioEngine
//
//  Created by xiaoxiong on 2019/12/11.
//

#import "SMEasyAudioNode.h"

NS_ASSUME_NONNULL_BEGIN

@interface SMEasyAudioDynamicsProcessorNode : SMEasyAudioNode

//! range is from -40dB to 20dB. Default is -20dB.
@property (nonatomic) double threshold;

//! range is from 0.1dB to 40dB. Default is 5dB.
@property (nonatomic) double headRoom;

//! range is from 1 to 50 (rate). Default is 2.
@property (nonatomic) double expansionRatio;

// Value is in dB.
@property (nonatomic) double expansionThreshold;

//! range is from 0.0001 to 0.2. Default is 0.001.
@property (nonatomic) double attackTime;

//! range is from 0.01 to 3. Default is 0.05.
@property (nonatomic) double releaseTime;

//! range is from -40dB to 40dB. Default is 0dB.
@property (nonatomic) double masterGain;

@property (nonatomic, readonly) double compressionAmount;
@property (nonatomic, readonly) double inputAmplitude;
@property (nonatomic, readonly) double outputAmplitude;

@end

NS_ASSUME_NONNULL_END
