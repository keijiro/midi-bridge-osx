#import "LogWindowController.h"
#import "MIDIMessage.h"
#import "MIDIEndpoint.h"

#pragma mark Local functions

static const char *statusByteToCString(Byte b)
{
    static const char *texts[] = {
        "Note Off",         // 0x8*
        "Note On",          // 0x9*
        "Aftertouch",       // 0xa*
        "Control Change",   // 0xb*
        "Program Change",   // 0xc*
        "Pressure",         // 0xd*
        "Pitch Wheel",      // 0xe*
        "System"            // 0xf*
    };
    return texts[(b >> 4) & 7];
}

#pragma mark
#pragma mark Private properties

@interface LogWindowController ()
{
    NSUInteger _inLogCount;
    NSUInteger _outLogCount;
}

@property (assign) IBOutlet NSTableView *inLogTable;
@property (assign) IBOutlet NSTableView *outLogTable;

@property (assign) NSUInteger maxLogCount;
@property (strong) NSMutableArray *inSourceLog;
@property (strong) NSMutableArray *inMessageLog;
@property (strong) NSMutableArray *outMessageLog;

@end

#pragma mark
#pragma mark Log window controller class implementation

@implementation LogWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        _maxLogCount = 64;
        self.inSourceLog = [[NSMutableArray alloc] initWithCapacity:_maxLogCount];
        self.inMessageLog = [[NSMutableArray alloc] initWithCapacity:_maxLogCount];
        self.outMessageLog = [[NSMutableArray alloc] initWithCapacity:_maxLogCount];
    }
    return self;
}

- (IBAction)showWindow:(id)sender
{
    // Reload the data before popping up.
    [self.inLogTable reloadData];
    [self.outLogTable reloadData];
    [super showWindow:sender];
}

#pragma mark Logging functions

- (void)logIncomingMessage:(MIDIMessage *)message from:(MIDIEndpoint *)source
{
    if (_inLogCount < _maxLogCount) {
        [self.inSourceLog addObject:source];
        [self.inMessageLog addObject:message];
    } else {
        NSUInteger index = _inLogCount % _maxLogCount;
        [self.inSourceLog replaceObjectAtIndex:index withObject:source];
        [self.inMessageLog replaceObjectAtIndex:index withObject:message];
    }
    _inLogCount++;
    
    // Reload the data only if the window is visible.
    if (self.window.isVisible) [self.inLogTable reloadData];
}

- (void)logOutgoingMessage:(MIDIMessage *)message
{
    if (_outLogCount < _maxLogCount) {
        [self.outMessageLog addObject:message];
    } else {
        NSUInteger index = _inLogCount % _maxLogCount;
        [self.outMessageLog replaceObjectAtIndex:index withObject:message];
    }
    _outLogCount++;
    
    // Reload the data only if the window is visible.
    if (self.window.isVisible) [self.outLogTable reloadData];
}

#pragma mark Data source interface for NSTableView

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return (tableView.tag == 0) ? self.inMessageLog.count : self.outMessageLog.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{
    // Source column.
    if ([tableColumn.identifier isEqualToString:@"source"]) {
        NSUInteger index = (_inLogCount - rowIndex - 1) % _maxLogCount;
        MIDIEndpoint *source = [self.inSourceLog objectAtIndex:index];
        return [NSString stringWithFormat:@"%@", source.displayName];
    }
    
    // Incomming or outgoing?
    MIDIMessage *message;
    if (tableView.tag == 0) {
        NSUInteger index = (_inLogCount - rowIndex - 1) % _maxLogCount;
        message = [self.inMessageLog objectAtIndex:index];
    } else {
        NSUInteger index = (_outLogCount - rowIndex - 1) % _maxLogCount;
        message = [self.outMessageLog objectAtIndex:index];
    }
    
    // Channel column.
    if ([tableColumn.identifier isEqualToString:@"channel"]) {
        return [NSString stringWithFormat:@"%d", (message.status & 0xf)];
    }
    
    // Event column.
    if ([tableColumn.identifier isEqualToString:@"event"]) {
        return [NSString stringWithUTF8String:statusByteToCString(message.status)];
    }
    
    // Data column
    if (message.length > 2) {
        return [NSString stringWithFormat:@"%d, %d", message.data1, message.data2];
    } else {
        return [NSString stringWithFormat:@"%d", message.data1];
    }
}

@end
