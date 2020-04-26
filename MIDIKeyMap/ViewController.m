//
//  ViewController.m
//  MIDIKeyMap
//
//  Created by Maxwell on 26/04/20.
//  Copyright © 2020 Maxwell Swadling. All rights reserved.
//

#import "ViewController.h"

#import <CoreMIDI/CoreMIDI.h>

MIDIPortRef     gOutPort = NULL;
MIDIEndpointRef gDest = NULL;
int             gChannel = 0;

static void MyReadProc(const MIDIPacketList *pktlist, void *refCon, void *connRefCon)
{
    MIDIPacket *packet = (MIDIPacket *)pktlist->packet; // remove const (!)
    for (unsigned int j = 0; j < pktlist->numPackets; ++j) {
        if (packet->length == 3) {
            Byte CC1 = packet->data[0];
            Byte CC2 = packet->data[1];
            Byte value = packet->data[2];
            printf("Control: %02X %02X = %02X\n", CC1, CC2, value);
            
            if (CC1 == 0xB0 && CC2 == 0x3A && value > 0x00) {
                // left key
                dispatch_async(dispatch_get_main_queue(), ^{
                    CGEventRef keyOn, keyOff;
                    keyOn = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)0x7B, true);
                    keyOff = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)0x7B, false);
                    CGEventPost(kCGHIDEventTap, keyOn);
                    CGEventPost(kCGHIDEventTap, keyOff);
                });
                
            } else if (CC1 == 0xB0 && CC2 == 0x3B && value > 0x00) {
                // right key
                dispatch_async(dispatch_get_main_queue(), ^{
                    CGEventRef keyOn, keyOff;
                    keyOn = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)0x7C, true);
                    keyOff = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)0x7C, false);
                    CGEventPost(kCGHIDEventTap, keyOn);
                    CGEventPost(kCGHIDEventTap, keyOff);
                });
            }
        }
        packet = MIDIPacketNext(packet);
    }

}

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    MIDIClientRef client = NULL;
    MIDIClientCreate(CFSTR("MIDI Echo"), NULL, NULL, &client);

    MIDIPortRef inPort = NULL;
    MIDIInputPortCreate(client, CFSTR("Input port"), MyReadProc, NULL, &inPort);
    MIDIOutputPortCreate(client, CFSTR("Output port"), &gOutPort);
    // enumerate devices (not really related to purpose of the echo program
    // but shows how to get information about devices)
    int i, n;
    CFStringRef pname, pmanuf, pmodel;
    char name[64], manuf[64], model[64];

    n = MIDIGetNumberOfDevices();
    for (i = 0; i < n; ++i) {
       MIDIDeviceRef dev = MIDIGetDevice(i);

       MIDIObjectGetStringProperty(dev, kMIDIPropertyName, &pname);
       MIDIObjectGetStringProperty(dev, kMIDIPropertyManufacturer, &pmanuf);
       MIDIObjectGetStringProperty(dev, kMIDIPropertyModel, &pmodel);

       CFStringGetCString(pname, name, sizeof(name), 0);
       CFStringGetCString(pmanuf, manuf, sizeof(manuf), 0);
       CFStringGetCString(pmodel, model, sizeof(model), 0);
       CFRelease(pname);
       CFRelease(pmanuf);
       CFRelease(pmodel);

       printf("name=%s, manuf=%s, model=%s\n", name, manuf, model);
    }
    
    // open connections from all sources
    n = MIDIGetNumberOfSources();
    printf("%d sources\n", n);
    for (i = 0; i < n; ++i) {
        MIDIEndpointRef src = MIDIGetSource(i);
        MIDIObjectGetStringProperty(src, kMIDIPropertyModel, &pname);
        if ([((__bridge NSString *)pname) isEqualToString:@"nanoKONTROL Studio"]) {

            MIDIPortConnectSource(inPort, src, NULL);
        }

        CFRelease(pname);
        
    }

}

@end
