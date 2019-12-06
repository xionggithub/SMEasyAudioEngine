

#import "SMTypes.h"


AudioStreamBasicDescription const SMAudioDescription = {
    .mFormatID          = kAudioFormatLinearPCM,
    .mFormatFlags       = kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked | kAudioFormatFlagIsNonInterleaved,
    .mChannelsPerFrame  = 2,
    .mBytesPerPacket    = sizeof(float),
    .mFramesPerPacket   = 1,
    .mBytesPerFrame     = sizeof(float),
    .mBitsPerChannel    = 8 * sizeof(float),
    .mSampleRate        = 0,
};

AudioStreamBasicDescription SMAudioDescriptionWithChannelsAndRate(int channels, double rate) {
    AudioStreamBasicDescription description = SMAudioDescription;
    description.mChannelsPerFrame = channels;
    description.mSampleRate = rate;
    return description;
}

SMChannelSet SMChannelSetDefault = {0, 1};
