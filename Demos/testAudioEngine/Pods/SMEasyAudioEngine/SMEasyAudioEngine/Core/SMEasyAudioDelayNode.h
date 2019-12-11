//
//  SMEasyAudioDelayNode.h
//  Pods-testAudioEngine
//
//  Created by xiaoxiong on 2019/12/11.
//

#import "SMEasyAudioNode.h"

NS_ASSUME_NONNULL_BEGIN

@interface SMEasyAudioDelayNode : SMEasyAudioNode

//! range is from 0 to 100 (percentage). Default is 50.
@property (nonatomic) double wetDryMix;

//! range is from 0 to 2 seconds. Default is 1 second.
@property (nonatomic) double delayTime;

//! range is from -100 to 100. default is 50.
@property (nonatomic) double feedback;

//! range is from 10 to ($SAMPLERATE/2). Default is 15000.
@property (nonatomic) double lopassCutoff;


@end

NS_ASSUME_NONNULL_END
