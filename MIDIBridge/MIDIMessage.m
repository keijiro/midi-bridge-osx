#import "MIDIMessage.h"

@implementation MIDIMessage

#pragma mark Property accessors

- (Byte *)bytes
{
    return &_status;
}

- (NSUInteger)length
{
    return (_data2 & 0x80) ? 2 : 3;
}

#pragma mark Reader methods

- (NSUInteger)readBytes:(const Byte *)bytes length:(NSUInteger)length
{
    NSAssert(length >= 2, @"Invalid data length.");
    
    _status = bytes[0];
    _data1 = bytes[1];
    
    if (length == 2 || bytes[2] > 0x7f) {
        _data2 = 0x80;
        return 2;
    } else {
        _data2 = bytes[2];
        return 3;
    }
}

- (NSUInteger)readPacket:(const MIDIPacket *)packet offset:(NSUInteger)offset
{
    // Status byte.
    _status = packet->data[offset];
    
    if (++offset >= packet->length) {
        // This packet is actually corrupted.
        _data1 = 0;
        _data2 = 0x80;
        return offset;
    }
    
    // 1st data byte.
    Byte data = packet->data[offset];
    if (data & 0x80) return offset;
    _data1 = data;
    
    if (++offset >= packet->length) {
        _data2 = 0x80;
        return offset;
    }
    
    // 2nd data byte.
    data = packet->data[offset];
    if (data & 0x80) {
        _data2 = 0x80;
        return offset;
    }
    _data2 = data;
    
    // Simply dispose the reset of the data.
    while (++offset < packet->length && packet->data[offset] < 0x80){}
    
    return offset;
}

@end
