//
//  SMEasyAudioVarispeedNode.h
//  Pods-testAudioEngine
//
//  Created by xiaoxiong on 2019/12/11.
//

#import "SMEasyAudioNode.h"

NS_ASSUME_NONNULL_BEGIN

@interface SMEasyAudioVarispeedNode : SMEasyAudioNode

//! documented range is from 0.25 to 4.0, but empircal testing shows it to be 0.25 to 2.0. Default is 1.0.
@property (nonatomic) double playbackRate;

//! range is from -2400 to 2400. Default is 0.0.
@property (nonatomic) double playbackCents;

@end

NS_ASSUME_NONNULL_END
