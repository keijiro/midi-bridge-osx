#import "MIDIMessage.h"
#import <CoreFoundation/CoreFoundation.h>
#import <CoreMIDI/CoreMIDI.h>

@implementation MIDIMessage

- (id)initWithBytes:(const Byte *)bytes
{
    self = [super init];
    if (self) {
        self.status = bytes[0];
        self.data1 = bytes[1];
        self.data2 = bytes[2];
    }
    return self;
}

- (int)readPacket:(const MIDIPacket *)packet dataOffset:(int)offset
{
    // Status byte.
    self.status = packet->data[offset];
    
    if (++offset >= packet->length) return offset;
    
    // 1st data byte.
    Byte data = packet->data[offset];
    if (data & 0x80) return offset;
    self.data1 = data;
    
    if (++offset >= packet->length) return offset;
    
    // 2nd data byte.
    data = packet->data[offset];
    if (data & 0x80) return offset;
    self.data2 = data;
    
    // Simply dispose the reset of the data.
    while (++offset < packet->length && packet->data[offset] < 0x80){}
    
    return offset;
}

- (UInt32)packedData
{
    return
        (UInt32)self->_status |
        ((UInt32)self->_data1 << 8) |
        ((UInt32)self->_data2 << 16);
}

@end
