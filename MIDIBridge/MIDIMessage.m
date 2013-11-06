#import "MIDIMessage.h"

@implementation MIDIMessage

#pragma mark Property accessors

- (Byte *)bytes
{
    return &_status;
}

- (NSUInteger)length
{
    return (_data1 & 0x80) ? 1 : ((_data2 & 0x80) ? 2 : 3);
}

#pragma mark Reader methods

- (NSUInteger)readBytes:(const Byte *)bytes offset:(NSUInteger)offset length:(NSUInteger)length
{
    NSAssert(offset < length, @"Invalid argument.");
    
    _data1 = 0x80;
    _data2 = 0x80;

    // Status byte.
    Byte temp = bytes[offset++];
    if (temp < 0x80) {
        // It seems to be corrupted. Replace with an Active Sense event.
        _status = 0xfe;
        return offset;
    }
    _status = temp;
    
    if (offset >= length) {
        return offset;
    }
    
    // 1st data byte.
    temp = bytes[offset];
    if (temp & 0x80) {
        return offset;
    }
    _data1 = temp;
    
    if (++offset >= length) {
        return offset;
    }
    
    // 2nd data byte.
    temp = bytes[offset];
    if (temp & 0x80) {
        return offset;
    }
    _data2 = temp;
    
    // Simply dispose the reset of the data.
    while (++offset < length && bytes[offset] < 0x80) {}
    
    return offset;
}

- (NSUInteger)readPacket:(const MIDIPacket *)packet offset:(NSUInteger)offset
{
    return [self readBytes:packet->data offset:offset length:packet->length];
}

@end
