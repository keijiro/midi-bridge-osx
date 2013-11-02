#import "MIDIBridgeAppDelegate.h"
#import "MIDIMessage.h"
#import "MIDIClient.h"
#import "IPCRouter.h"

#pragma mark Private properties

@interface MIDIBridgeAppDelegate ()
@property (strong) MIDIClient *midiClient;
@property (strong) IPCRouter *ipcRouter;
@end

#pragma mark
#pragma mark Application delegate class implementation

@implementation MIDIBridgeAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.midiClient = [[MIDIClient alloc] initWithDelegate:self];
    self.ipcRouter = [[IPCRouter alloc] initWithDelegate:self];
    [self.deviceTable reloadData];
}

#pragma mark MIDIClient delegate methods

- (void)resetMIDIStatus
{
    [self.deviceTable reloadData];
}

- (void)processIncomingMIDIMessage:(MIDIMessage *)message
{
    [self.ipcRouter sendMessage:message];
    
    NSString *line = [NSString stringWithFormat:@"%0x %0x %0x %0x", message.sourceID, message.status, message.data1, message.data2];
    NSAttributedString *string = [[NSAttributedString alloc] initWithString:[line stringByAppendingString:@"\n"]];
    [self.textView.textStorage beginEditing];
    [self.textView.textStorage appendAttributedString:string];
    [self.textView.textStorage endEditing];
    [self.textView scrollRangeToVisible:NSMakeRange(self.textView.string.length, 0)];
}

#pragma mark IPCRouter delegate methods

- (void)processIncomingIPCMessage:(MIDIMessage *)message
{
    [self.midiClient sendMessage:message];
}

#pragma mark Table View Data Soruce methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.midiClient.sourceCount + self.midiClient.destinationCount;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (!self.midiClient) return nil;
    if (row < self.midiClient.sourceCount) {
        return [self.midiClient getSourceDisplayName:row];
    } else {
        return [self.midiClient getDestinationDisplayName:(row - self.midiClient.sourceCount)];
    }
}

@end
