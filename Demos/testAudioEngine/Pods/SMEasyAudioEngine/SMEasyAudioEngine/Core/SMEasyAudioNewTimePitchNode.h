//
//  SMEasyAudioNewTimePitchNode.h
//  testAudioEngine
//
//  Created by xiaoxiong on 2019/12/11.
//  Copyright © 2019 xiaoxiong. All rights reserved.
//

#import "SMEasyAudioNode.h"

NS_ASSUME_NONNULL_BEGIN

@interface SMEasyAudioNewTimePitchNode : SMEasyAudioNode

//! range is from 1/32 to 32.0. Default is 1.0.
@property (nonatomic) double rate;

//! range is from -2400 cents to 2400 cents. Default is 0.0 cents.
@property (nonatomic) double pitch;

//! range is from 3.0 to 32.0. Default is 8.0.
@property (nonatomic) double overlap;

//! value is either YES or NO. Default is YES.
@property (nonatomic) BOOL enablePeakLocking;
@end

NS_ASSUME_NONNULL_END
