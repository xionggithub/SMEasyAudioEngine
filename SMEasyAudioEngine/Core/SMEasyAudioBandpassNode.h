//
//  SMEasyAudioBandpassNode.h
//  Pods-testAudioEngine
//
//  Created by xiaoxiong on 2019/12/11.
//

#import "SMEasyAudioNode.h"

NS_ASSUME_NONNULL_BEGIN

@interface SMEasyAudioBandpassNode : SMEasyAudioNode

//! range is from 20Hz to ($SAMPLERATE/2)Hz. Default is 5000Hz.
@property (nonatomic) double centerFrequency;

//! range is from 100 to 12000 cents. Default is 600 cents.
@property (nonatomic) double bandwidth;

@end

NS_ASSUME_NONNULL_END
