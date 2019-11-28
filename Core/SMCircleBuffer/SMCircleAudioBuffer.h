
#ifdef __cplusplus
extern "C" {
#endif

#import "TPCircularBuffer.h"
#import <AudioToolbox/AudioToolbox.h>

#define SMCircleAudioBufferCopyAll UINT32_MAX

/*!
 * Circular buffer
 */
typedef struct {
    TPCircularBuffer buffer;
    AudioStreamBasicDescription audioDescription;
} SMCircleAudioBuffer;

/*!
 * Initialize buffer
 */
BOOL SMCircleAudioBufferInit(SMCircleAudioBuffer * buffer, UInt32 capacityInFrames, AudioStreamBasicDescription audioDescription);

/*!
 * Cleanup buffer
 *
 *  Releases buffer resources.
 */
void SMCircleAudioBufferCleanup(SMCircleAudioBuffer *buffer);

/*!
 * Clear buffer
 *
 *  Resets buffer to original, empty state.
 *
 *  This is safe for use by consumer while producer is accessing the buffer.
 */
void SMCircleAudioBufferClear(SMCircleAudioBuffer *buffer);

/*!
 * Set the atomicity
 *
 *  If you set the atomiticy to false using this method, the buffer will
 *  not use atomic operations. This can be used to give the compiler a little
 *  more optimisation opportunities when the buffer is only used on one thread.
 *
 *  Important note: Only set this to false if you know what you're doing!
 *
 *  The default value is true (the buffer will use atomic operations)
 *
 * @param buffer Circular buffer
 * @param atomic Whether the buffer is atomic (default true)
 */
void SMCircleAudioBufferSetAtomic(SMCircleAudioBuffer *buffer, BOOL atomic);

/*!
 * Change channel count and/or sample rate
 *
 *  This will cause the buffer to clear any existing audio, and reconfigure to use the new
 *  channel count and sample rate. Note that it will not alter the buffer's capacity; if you
 *  need to increase capacity to cater to a larger number of channels/frames, then you'll
 *  need to cleanup and re-initialize the buffer.
 *
 *  You should only use this on the consumer thread.
 *
 * @param buffer Circular buffer
 * @param channelCount Number of channels of audio you'll be working with
 * @param sampleRate Sample rate of audio, used to work with AudioTimeStamps
 */
void SMCircleAudioBufferSetChannelCountAndSampleRate(SMCircleAudioBuffer * buffer,
                                                  int channelCount,
                                                  double sampleRate);

#pragma mark - Producing

/*!
 * Determine how many much space there is in the buffer
 *
 *  Determines the number of frames of audio that can be buffered.
 *
 *  Note: This function should only be used on the producer thread, not the consumer thread.
 *
 * @param buffer Circular buffer
 * @return The number of frames that can be stored in the buffer
 */
UInt32 SMCircleAudioBufferGetAvailableSpace(SMCircleAudioBuffer *buffer);

/*!
 * Copy the audio buffer list onto the buffer
 *
 * @param buffer Circular buffer
 * @param bufferList Buffer list containing audio to copy to buffer
 * @param timestamp The timestamp associated with the buffer, or NULL
 * @param frames Length of audio in frames, or SMCircleAudioBufferCopyAll to copy the whole buffer
 * @return YES if buffer list was successfully copied; NO if there was insufficient space
 */
BOOL SMCircleAudioBufferEnqueue(SMCircleAudioBuffer *buffer,
                             const AudioBufferList *bufferList,
                             const AudioTimeStamp *timestamp,
                             UInt32 frames);

/*!
 * Prepare an empty buffer list, stored on the circular buffer
 *
 * @param buffer Circular buffer
 * @param frameCount The number of frames that will be stored
 * @param timestamp The timestamp associated with the buffer, or NULL.
 * @return The empty buffer list, or NULL if circular buffer has insufficient space
 */
AudioBufferList * SMCircleAudioBufferPrepareEmptyAudioBufferList(SMCircleAudioBuffer *buffer,
                                                              UInt32 frameCount,
                                                              const AudioTimeStamp *timestamp);

/*!
 * Mark next audio buffer list as ready for reading
 *
 *  This marks the audio buffer list prepared using SMCircleAudioBufferPrepareEmptyAudioBufferList
 *  as ready for reading. You must not call this function without first calling
 *  SMCircleAudioBufferPrepareEmptyAudioBufferList.
 *
 * @param buffer Circular buffer
 */
void SMCircleAudioBufferProduceAudioBufferList(SMCircleAudioBuffer *buffer);

#pragma mark - Consuming
    
/*!
 * Determine how many frames of audio are buffered
 *
 *  Note: This function should only be used on the consumer thread, not the producer thread.
 *
 * @param buffer Circular buffer
 * @param outTimestamp On output, if not NULL, the timestamp corresponding to the first audio frame
 * @return The number of frames queued in the buffer
 */
UInt32 SMCircleAudioBufferPeek(SMCircleAudioBuffer *buffer, AudioTimeStamp *outTimestamp);

/*!
 * Copy a certain number of frames from the buffer and dequeue
 *
 * @param buffer Circular buffer
 * @param ioLengthInFrames On input, the number of frames to consume; on output, the number of frames provided
 * @param outputBufferList The buffer list to copy audio to, or NULL to discard audio.
 * @param outTimestamp On output, if not NULL, the timestamp corresponding to the first audio frame returned
 */
void SMCircleAudioBufferDequeue(SMCircleAudioBuffer *buffer,
                             UInt32 *ioLengthInFrames,
                             const AudioBufferList *outputBufferList,
                             AudioTimeStamp *outTimestamp);

/*!
 * Access the next stored buffer list
 *
 * @param buffer Circular buffer
 * @param outTimestamp On output, if not NULL, the timestamp corresponding to the buffer
 * @param lastBufferList If not NULL, the preceding buffer list on the buffer. The next buffer list after this will be returned; use this to iterate through all queued buffers. If NULL, this function will return the first queued buffer.
 * @return Pointer to the next queued buffer list
 */
AudioBufferList * SMCircleAudioBufferNextBufferList(SMCircleAudioBuffer *buffer,
                                                 AudioTimeStamp *outTimestamp,
                                                 const AudioBufferList * lastBufferList);

/*!
 * Consume the next buffer list available for reading
 *
 * @param buffer Circular buffer
 */
void SMCircleAudioBufferConsumeNextBufferList(SMCircleAudioBuffer *buffer);

/*!
 * Consume a portion of the next buffer list
 *
 *  This will also increment the sample time and host time portions of the timestamp of
 *  the buffer list, if present.
 *
 * @param buffer Circular buffer
 * @param frames The number of frames to consume from the buffer list
 */
void SMCircleAudioBufferConsumeNextBufferListPartial(SMCircleAudioBuffer *buffer, UInt32 frames);

#ifdef __cplusplus
}
#endif
