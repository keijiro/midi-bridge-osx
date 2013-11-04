#import <Foundation/Foundation.h>

struct MIDIPacket; // Forward declaration.

@interface MIDIMessage : NSObject

- (id)initWithBytes:(const Byte *)bytes;
- (int)readPacket:(const struct MIDIPacket *)packet dataOffset:(int)offset;

@property (readonly) UInt32 packedData;
@property (assign) Byte status;
@property (assign) Byte data1;
@property (assign) Byte data2;

@end
