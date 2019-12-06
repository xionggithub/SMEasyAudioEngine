//
//  ViewController.m
//  STAudioTest
//
//  Created by xiaoxiong on 2019/11/19.
//  Copyright © 2019 xiaoxiong. All rights reserved.
//

#import "ViewController.h"
#import "SMAudioEngine.h"
@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *startBtn;
@property (weak, nonatomic) IBOutlet UIButton *stopBtn;
@property (weak, nonatomic) IBOutlet UISlider *slider;
@property (weak, nonatomic) IBOutlet UILabel *gainLabel;

@end

@implementation ViewController
{
    SMAudioEngine *_audioEngine;
    CGFloat _gain;
}
- (IBAction)startBtnClicked:(id)sender {
    [_audioEngine startPlay];
    _gain = [_audioEngine gain];
    [self updateGainValue];
    [self updateGainValueShow];
}
- (IBAction)stopBtnClicked:(id)sender {
    [_audioEngine stopPlay];
    _gain = 0;
    [self updateGainValue];
    [self updateGainValueShow];
}
- (IBAction)sliderValueChanged:(id)sender {
    UISlider *slider = (UISlider *)sender;
    _gain = slider.value;
    [self updateGainValueShow];
    [_audioEngine setGain:_gain];
}
- (void)updateGainValueShow{
    self.gainLabel.text = [NSString stringWithFormat:@"gain :%.2f",_gain];
}
- (void)updateGainValue{
    self.slider.value = _gain;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _gain = 0;
    [self updateGainValueShow];
    [self updateGainValue];
    _audioEngine = [[SMAudioEngine alloc]initEngine];
}


@end
