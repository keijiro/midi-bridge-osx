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

- (NSUInteger)readBytes:(const Byte *)bytes offset:(NSUInteger)offset length:(NSUInteger)length
{
    if (length < offset + 2) {
        // No data, do nothing.
        return offset;
    }
    
    _status = bytes[offset++];
    
    // 1st data byte.
    Byte data = bytes[offset];
    if (data & 0x80) {
        // It seems to be corrupted. Replace with an Active Sense event.
        _status = 0xff;
        _data1 = 0xfe;
        _data2 = 0x80;
        return offset;
    }
    _data1 = data;
    
    if (++offset >= length) {
        _data2 = 0x80;
        return offset;
    }
    
    // 2nd data byte.
    data = bytes[offset];
    if (data & 0x80) {
        _data2 = 0x80;
        return offset;
    }
    _data2 = data;
    
    // Simply dispose the reset of the data.
    while (++offset < length && bytes[offset] < 0x80) {}
    
    return offset;
}

- (NSUInteger)readPacket:(const MIDIPacket *)packet offset:(NSUInteger)offset
{
    return [self readBytes:packet->data offset:offset length:packet->length];
}

@end
