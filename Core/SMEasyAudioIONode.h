//
//  SMEasyAudioIONode.h
//  SMAudioEngine
//
//  Created by 熊先提 on 2017/8/20.
//  Copyright © 2017年 熊先提. All rights reserved.
//

#import "SMEasyAudioNode.h"

@interface SMEasyAudioIONode : SMEasyAudioNode
@property (nonatomic ,assign) BOOL enableInput;

- (void) setAudioUnitStreamFormat:(AudioStreamBasicDescription) inputElementFormat outputElementFormat:(AudioStreamBasicDescription)outputElementFormat;

@end
