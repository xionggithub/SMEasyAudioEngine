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
// -2400 -> 2400, 1.0
- (void)setNewTimePitch:(Float32)pitchShift;
- (Float32)getNewTimePitch;
@end

NS_ASSUME_NONNULL_END
