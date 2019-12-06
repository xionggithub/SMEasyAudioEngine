#import "SMAudioEngine.h"

#import "SMAudioEngine.h"

const int SMVideoBitRate = (1048576/2.f);  // 512k
const int SMAudioBitRate = 32000;    // 32k
const int SMAudioSampleRate = 44100; // 44k
const float SMAudioSampleRateInverse = 1.0/44100.0; // 44k
const int SMVideoFps = 25;
const int SMAudioChannelNum = 2;     // 双声道
const int SMAudioPreferredSampleRate = 44100; // 48000;

const float SMAudioIOBufferDurationSmall = 0.0058f;
const float SMAudioIOBufferDurationLarge = 0.0232f;


@interface SMAudioEngine()
@property (strong, nonatomic) AERenderer * renderer;
@property (strong, nonatomic) AEAudioUnitOutput* ioOutput;
@property (strong, nonatomic) AEAudioUnitInputModule* ioInput;
@end



static void audioProcessRenderCallback(__unsafe_unretained SMAudioEngine * self, const AERenderContext * _Nonnull context);

@implementation SMAudioEngine
{
    @public
    BOOL _isBuildinPhone;
    BOOL _isBuildinBluetooth;
}

#pragma mark - 生命周期
- (instancetype)initEngine{
    if ( self = [super init] ) {
        NSError *error = [self setupAudioEngine];
        if (error) {
            return nil;
        }
    }
    return self;
}


#pragma mark - 设置AudioEngine
- (NSError*)setupAudioEngine {
    _renderer = nil;
    
    // 1. 创建Render, 默认的采样率: 44100, 代码@feiwang维护
    _renderer = [AERenderer new];
    self.ioOutput = [[AEAudioUnitOutput alloc] initWithRenderer:_renderer];
    [self.ioOutput setup:nil];
    self.ioInput = self.ioOutput.inputModule;

    // 这个地方存在内存泄漏
    // 通常情况下 block 是存在周期很短, 它会"短时间强制引用"self, 但是由于释放的早, 因此也不会造成什么内存泄漏
    // 但是: _renderer.block 的实现方式打破了这个假设, 它通过 AEManagedValue 来管理, 会一直活着, 直到 _renderer 自己挂了,
    // 或者 block被修改
    // 因此需要在__finish函数中破除这个逻辑
    // _renderer 内部包含Context, 会有大量的内存缓存, 必须及时释放
    __weak typeof(self)weakSelf = self;
    _renderer.block = ^(const AERenderContext * _Nonnull context) {
        __strong typeof(self)strongSelf = weakSelf;
        // self 要么被释放，要么使使用完毕再释放
        if (strongSelf) {
            audioProcessRenderCallback(strongSelf, context);
        }
    };
    
    return nil;
}


// 和startPlayBack类似,和pause交替使用
-(void)startPlay {
    // 1. 重新设置AudioSession
    [self __setupAudioSession:AVAudioSessionCategoryPlayAndRecord];
    if (!self.renderer) {
        NSLog(@"AudioEngine not initialized");
        return;
    }
    // 3. 启动Render流程
    if (!self.ioOutput.running) {
        [self __start];
    } else {
        NSLog(@"Multi Start of AudioUnit");
    }
    NSLog(@"startRecord end");
}




//  区分主动pause和被动pause
//  主动pause的, 不需要考虑自动重启
- (void)stopPlay {
    // 1. 暂停输出
    if (self.ioOutput.running) {
        [self __stop];
    } else {
        printf("Multi Stop of AudioUnit\n");
    }
}


- (void) __finish {
    
    if (_renderer != nil) {
        // 1. 暂停
        [self stopPlay];
        
        // _renderer的block似乎对当前的SMAudioEngine存在引用, 因为这个地方的block被会_renderer长期保留, 除非被替换
        self.renderer.block = ^(const AERenderContext * _Nonnull context) {};
        self.renderer.block = nil;
        _renderer = nil;
        _ioOutput = nil;
        _ioInput = nil;
    }
}


- (void)setGain:(CGFloat)gain{
    if (self.ioInput) {
        [self.ioInput setInputGain:gain];
    }
}
- (CGFloat)gain{
    return self.ioInput.inputGain;
}
- (BOOL)isRunning {
    // 离线处理，不存在isRunning判断的需求
    // 实时处理，ioOutput有效
    return self.ioOutput.running;
}

- (NSTimeInterval)currentTime {
    return 0;
}
-(void)__start {
    //标记音频播放状态
    //对输入降幅 处理 以防输入被截幅度 后面使用的时候在升幅度还原
    [self.ioInput setInputGain:0.3548];
    NSError* error;
    [self.ioInput start:&error];
    if (error != nil) {
        NSLog(@"Error: %@", error);
    }
    // ioOutput开始读取数据时， input应该处于ready状态
    [self.ioOutput start:&error];
    if (error != nil) {
        NSLog(@"Error: %@", error);
    }
}

-(void)__stop {
    
    [self.ioOutput stop];
    [self.ioInput stop];
}



// 尽量少关注这些变化
// Session设置完毕之后, 再添加这些Notification
- (void)__addAudioSessionRouteChangeNotification {
    // 防止重复添加(TODO), 是否合适呢?
    [self __removeAudioSessionRouteChangeNotification];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(audioRouteChangedNotification:)
                                                 name:AVAudioSessionRouteChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(audioUnitOutputDidChangeSampleRateNotification:)
                                                 name:AEAudioUnitOutputDidChangeSampleRateNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(audioSessionInterruptionNotification:)
                                                 name:AVAudioSessionInterruptionNotification
                                               object:nil];
    
   
    
    
}

// Session使用完毕, 取消这些Notification
- (void)__removeAudioSessionRouteChangeNotification {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVAudioSessionRouteChangeNotification
                                                  object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AEAudioUnitOutputDidChangeSampleRateNotification
                                                  object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVAudioSessionInterruptionNotification
                                                  object: nil];
   
}

-(AVAudioSessionRouteDescription*)audioRoute {
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    AVAudioSessionRouteDescription *currentRoute = audioSession.currentRoute;
    return currentRoute;
}

-(void)audioRouteChangedNotification:(NSNotification*)notification {
    AVAudioSessionRouteDescription *audioRoute = [self audioRoute];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self updateHeadphoneStatus: audioRoute];
    }];
}

-(void)applicationDidBecomeActive:(NSNotification*)notification {
    
    if(self.renderer == nil){
        return;
    }
}

-(void)audioUnitOutputDidChangeSampleRateNotification:(NSNotification*)notification {
    
}

-(void)audioSessionInterruptionNotification:(NSNotification*)notification {
    
    NSInteger type = [notification.userInfo[AVAudioSessionInterruptionTypeKey] integerValue];
    if ( type == AVAudioSessionInterruptionTypeBegan ) {
    } else if ( type == AVAudioSessionInterruptionTypeEnded ){
    }
    
}


- (void)updateHeadphoneStatus:(AVAudioSessionRouteDescription *)audioRoute {
    if (!audioRoute) {
        audioRoute = [AVAudioSession sharedInstance].currentRoute;
    }
    // 是否有外部输入输出
    NSString* outputPortType = audioRoute.outputs.firstObject.portType;
    _isBuildinPhone = [AVAudioSessionPortBuiltInReceiver isEqualToString: outputPortType]
    || [AVAudioSessionPortBuiltInSpeaker isEqualToString: outputPortType];
    _isBuildinBluetooth = ([AVAudioSessionPortBuiltInMic isEqualToString:outputPortType]||[AVAudioSessionPortBluetoothLE isEqualToString:outputPortType]||[AVAudioSessionPortBluetoothHFP isEqualToString:outputPortType]||[AVAudioSessionPortBluetoothA2DP isEqualToString:outputPortType]);
}

-(void) __setupAudioSession:(NSString*)category {
    
    AVAudioSession* audioSession = [AVAudioSession sharedInstance];

    // 2. 默认发送到Speaker
    [self __addAudioSessionRouteChangeNotification];

    
    NSError *error = nil;
    if (@available(iOS 10.0, *)) {
        [audioSession setCategory:category
                      withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker|AVAudioSessionCategoryOptionAllowBluetooth|AVAudioSessionCategoryOptionAllowBluetoothA2DP
                            error:&error];
    } else {
        [audioSession setCategory:category
                      withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker|AVAudioSessionCategoryOptionAllowBluetooth
                            error:&error];
    }
    
    
    // 3. 这个不要随便修改, 否则可能造成较大的inputLatency
    
    [audioSession setMode:AVAudioSessionModeDefault error:&error];
    if (error) {
        NSLog(@"%@", error);
    }
    
    // 4. 设置期待的IOBuffer Latency
    // 在实时录制阶段，设置小一点，减少“回音“延迟
    // 在播放阶段，由于添加了特效等，计算的实时性不够，因此期望设置一个高一点的延迟
    [audioSession setPreferredIOBufferDuration:SMAudioIOBufferDurationSmall error:nil];

    // 5. 设置期待的输入采样率
    [audioSession setPreferredSampleRate: SMAudioPreferredSampleRate error:&error];
    if (error) {
        NSLog(@"%@", error);
    }
    
    // 6. 激活Session(同步操作，会影响其他的Audio Session)
    [audioSession setActive:YES error:&error];
    if (error) {
        NSLog(@"%@", error);
    }
    
    [self updateHeadphoneStatus: audioSession.currentRoute];
    
}


@end
static void audioProcessRenderCallback(__unsafe_unretained SMAudioEngine * self,
                                       const AERenderContext * _Nonnull context) {
    
    // 输入信号
    BOOL silenceVoiceOutput = self->_isBuildinPhone;

    if (self.ioInput && !silenceVoiceOutput){
        AEModuleProcess(self.ioInput, context);
    }
    int count = AEBufferStackCount(context->stack);
    if (count > 1) {
        AEBufferStackMix(context->stack, count);
    }
    count = AEBufferStackCount(context->stack);
    if (count > 0) {
        AERenderContextOutput(context, 1);
    } else {
        NSLog(@"No Audio Frame available....");
    }
}

