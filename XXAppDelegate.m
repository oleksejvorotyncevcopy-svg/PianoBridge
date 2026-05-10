#import "XXAppDelegate.h"
#import "XXRootViewController.h"
#import <ExternalAccessory/ExternalAccessory.h>
#import <CoreMIDI/CoreMIDI.h>

@interface XXAppDelegate () <NSStreamDelegate> {
    uint8_t _lastState[5];
}
@property (nonatomic, strong) EASession *pianoSession;
@property (nonatomic, assign) MIDIClientRef midiClient;
@property (nonatomic, assign) MIDIEndpointRef midiSource;
@end

@implementation XXAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [[XXRootViewController alloc] init];
    self.window.backgroundColor = [UIColor blueColor];
    [self.window makeKeyAndVisible];

    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];

    // Создаем MIDI клиент и виртуальный источник
    MIDIClientCreate(CFSTR("PianoClient"), NULL, NULL, &_midiClient);
    MIDISourceCreate(_midiClient, CFSTR("PocketLoops"), &_midiSource);
    memset(_lastState, 0, sizeof(_lastState));

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        EAAccessoryManager *manager = [EAAccessoryManager sharedAccessoryManager];
        for (EAAccessory *acc in [manager connectedAccessories]) {
            if ([acc.protocolStrings containsObject:@"com.gear4.keyboard"]) {
                self.pianoSession = [[EASession alloc] initWithAccessory:acc forProtocol:@"com.gear4.keyboard"];
                if (self.pianoSession) {
                    NSInputStream *is = [self.pianoSession inputStream];
                    [is setDelegate:self];
                    [is scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
                    [is open];
                    self.window.rootViewController.view.backgroundColor = [UIColor greenColor];
                }
            }
        }
    });
    return YES;
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    if (eventCode == NSStreamEventHasBytesAvailable) {
        [self readData:(NSInputStream *)aStream];
    }
}

- (void)readData:(NSInputStream *)stream {
    uint8_t buf[256];
    NSInteger len = [stream read:buf maxLength:256];
    if (len >= 7) {
        for (int i = 0; i <= len - 7; i++) {
            if (buf[i] == 0x55 && buf[i+1] == 0xAA) {
                uint8_t newState[5] = {buf[i+2], buf[i+3], buf[i+4], buf[i+5], buf[i+6]};
                for (int b = 0; b < 5; b++) {
                    uint8_t diff = newState[b] ^ _lastState[b];
                    if (diff != 0) {
                        for (int bit = 0; bit < 8; bit++) {
                            if (diff & (1 << bit)) {
                                uint8_t note = 48 + (b * 8) + bit;
                                BOOL down = (newState[b] & (1 << bit)) != 0;
                                [self sendNote:note velocity:down ? 100 : 0];
                                NSLog(@"[PIANO] Note: %d %@", note, down ? @"ON" : @"OFF");
                            }
                        }
                    }
                    _lastState[b] = newState[b];
                }
                i += 6;
            }
        }
    }
}

// ПРАВИЛЬНЫЙ МЕТОД ОТПРАВКИ MIDI
- (void)sendNote:(uint8_t)note velocity:(uint8_t)vel {
    Byte data[3];
    data[0] = (vel > 0) ? 0x90 : 0x80; // Note On (Ch 1) или Note Off (Ch 1)
    data[1] = note;
    data[2] = vel;

    // Используем буфер для пакета
    Byte packetBuffer[128];
    MIDIPacketList *packetList = (MIDIPacketList *)packetBuffer;
    MIDIPacket *packet = MIDIPacketListInit(packetList);
    
    // Добавляем MIDI данные в пакет
    packet = MIDIPacketListAdd(packetList, sizeof(packetBuffer), packet, 0, 3, data);

    if (packet) {
        MIDIReceived(self.midiSource, packetList);
    }
}

@end
