

#ifdef __cplusplus
extern "C" {
#endif

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>


/*!
 *
 *
 *  This is 32-bit floating-point, non-interleaved stereo PCM.
 */
extern const AudioStreamBasicDescription SMAudioDescription;

/*!
 * Get the TASM audio description at a given sample rate
 *
 * @param channels Number of channels
 * @param rate The sample rate
 * @return The audio description
 */
AudioStreamBasicDescription SMAudioDescriptionWithChannelsAndRate(int channels, double rate);

/*!
 * File types
 */
typedef NS_ENUM(NSInteger, SMAudioFileType) {
    SMAudioFileTypeAIFFFloat32, //!< 32-bit floating point AIFF (AIFC)
    SMAudioFileTypeAIFFInt16,   //!< 16-bit signed little-endian integer AIFF
    SMAudioFileTypeWAVInt16,    //!< 16-bit signed little-endian integer WAV
    SMAudioFileTypeM4A,         //!< AAC in an M4A container
};

/*!
 * Channel set
 */
typedef struct {
    int firstChannel; //!< The index of the first channel of the set
    int lastChannel;  //!< The index of the last channel of the set
} SMChannelSet;
    
extern SMChannelSet SMChannelSetDefault; //!< A default, stereo channel set

/*!
 * Create an SMChannelSet
 *
 * @param firstChannel The first channel
 * @param lastChannel The last channel
 * @returns An initialized SMChannelSet structure
 */
static inline SMChannelSet SMChannelSetMake(int firstChannel, int lastChannel) {
    return (SMChannelSet) {firstChannel, lastChannel};
}
    
/*!
 * Determine number of channels in an SMChannelSet
 *
 * @param channelSet The channel set
 * @return The number of channels
 */
static inline int SMChannelSetGetNumberOfChannels(SMChannelSet set) {
    return set.lastChannel - set.firstChannel + 1;
}

#ifdef __cplusplus
}
#endif
