#import <Foundation/Foundation.h>
#import <CoreMIDI/CoreMIDI.h>

@interface MIDIMessage : NSObject
{
    Byte _status;
    Byte _data1;
    Byte _data2;
}

- (void)readBytes:(const Byte *)bytes length:(NSUInteger)length;
- (NSUInteger)readPacket:(const struct MIDIPacket *)packet offset:(NSUInteger)offset;

@property (readonly) Byte *bytes;
@property (readonly) NSUInteger length;

@property (readonly) Byte status;
@property (readonly) Byte data1;
@property (readonly) Byte data2;

@end
