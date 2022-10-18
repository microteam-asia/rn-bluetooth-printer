//
//  RNBluethManager.m
//  RNBluetoothEscposPrinter
//

#import <Foundation/Foundation.h>
#import "RNBluetoothManager.h"
#import <CoreBluetooth/CoreBluetooth.h>
@implementation RNBluetoothManager

NSString *EVENT_DEVICE_ALREADY_PAIRED = @"EVENT_DEVICE_ALREADY_PAIRED";
NSString *EVENT_DEVICE_DISCOVER_DONE = @"EVENT_DEVICE_DISCOVER_DONE";
NSString *EVENT_DEVICE_FOUND = @"EVENT_DEVICE_FOUND";
NSString *EVENT_CONNECTION_LOST = @"EVENT_CONNECTION_LOST";
NSString *EVENT_UNABLE_CONNECT=@"EVENT_UNABLE_CONNECT";
NSString *EVENT_CONNECTED=@"EVENT_CONNECTED";
static NSArray<CBUUID *> *supportServices = nil;
static NSDictionary *writeableCharactiscs = nil;
bool isHasListeners;
static CBPeripheral *connected;
static RNBluetoothManager *instance;
static NSObject<WriteDataToBleDelegate> *writeDataDelegate;// delegate of write data resule;
static NSData *toWrite;
static NSTimer *timer;

+(Boolean)isConnected{
    return !(connected==nil);
}

+(void)writeValue:(NSData *) data withDelegate:(NSObject<WriteDataToBleDelegate> *) delegate
{
    @try{
        writeDataDelegate = delegate;
        toWrite = data;
        connected.delegate = instance;
        [connected discoverServices:supportServices];
    }
    @catch(NSException *e){
        NSLog(@"error in writing data to %@,issue:%@",connected,e);
        [writeDataDelegate didWriteDataToBle:false];
    }
}

// Will be called when this module's first listener is added.
-(void)startObserving {
    isHasListeners = YES;
    // Set up any upstream listeners or background tasks as necessary
}

// Will be called when this module's last listener is removed, or on dealloc.
-(void)stopObserving {
    isHasListeners = NO;
    // Remove upstream listeners, stop unnecessary background tasks
}

/**
 * Exports the constants to javascritp.
 **/
- (NSDictionary *)constantsToExport
{
    
    /*
     EVENT_DEVICE_ALREADY_PAIRED    Emits the devices array already paired
     EVENT_DEVICE_DISCOVER_DONE    Emits when the scan done
     EVENT_DEVICE_FOUND    Emits when device found during scan
     EVENT_CONNECTION_LOST    Emits when device connection lost
     EVENT_UNABLE_CONNECT    Emits when error occurs while trying to connect device
     EVENT_CONNECTED    Emits when device connected
     */

    return @{ EVENT_DEVICE_ALREADY_PAIRED: EVENT_DEVICE_ALREADY_PAIRED,
              EVENT_DEVICE_DISCOVER_DONE:EVENT_DEVICE_DISCOVER_DONE,
              EVENT_DEVICE_FOUND:EVENT_DEVICE_FOUND,
              EVENT_CONNECTION_LOST:EVENT_CONNECTION_LOST,
              EVENT_UNABLE_CONNECT:EVENT_UNABLE_CONNECT,
              EVENT_CONNECTED:EVENT_CONNECTED
              };
}
- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

+ (BOOL)requiresMainQueueSetup
{
    return YES;
}

/**
 * Defines the event would be emited.
 **/
- (NSArray<NSString *> *)supportedEvents
{
    return @[EVENT_DEVICE_DISCOVER_DONE,
             EVENT_DEVICE_FOUND,
             EVENT_UNABLE_CONNECT,
             EVENT_CONNECTION_LOST,
             EVENT_CONNECTED,
             EVENT_DEVICE_ALREADY_PAIRED];
}

RCT_EXPORT_MODULE(BluetoothManager);

//isBluetoothEnabled
RCT_EXPORT_METHOD(isBluetoothEnabled:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    CBManagerState state = [self.centralManager  state];
    resolve(state == CBManagerStatePoweredOn?@"true":@"false"); //canot pass boolean or int value to resolve directly.
}

//enableBluetooth
RCT_EXPORT_METHOD(enableBluetooth:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    resolve(nil);
}
//disableBluetooth
RCT_EXPORT_METHOD(disableBluetooth:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    resolve(nil);
}
//scanDevices
RCT_EXPORT_METHOD(scanDevices:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    @try{
        if(!self.centralManager || self.centralManager.state!=CBManagerStatePoweredOn){
            reject(@"BLUETOOTCH_INVALID_STATE",@"BLUETOOTCH_INVALID_STATE",nil);
            return;
        }
        if(self.centralManager.isScanning){
            [self.centralManager stopScan];
        }
        self.scanResolveBlock = resolve;
        self.scanRejectBlock = reject;
        if(connected && connected.identifier){
            NSDictionary *idAndName =@{@"address":connected.identifier.UUIDString,@"name":connected.name?connected.name:@""};
            NSDictionary *peripheralStored = @{connected.identifier.UUIDString:connected};
            if(!self.foundDevices){
                self.foundDevices = [[NSMutableDictionary alloc] init];
            }
            [self.foundDevices addEntriesFromDictionary:peripheralStored];
            if(isHasListeners){
                [self sendEventWithName:EVENT_DEVICE_FOUND body:@{@"device":idAndName}];
            }
        }
        [self.centralManager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@NO}];
        NSLog(@"Scanning started with services.");
        if(timer && timer.isValid){
            [timer invalidate];
            timer = nil;
        }
        timer = [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(callStop) userInfo:nil repeats:NO];
    
    }
    @catch(NSException *exception){
        NSLog(@"ERROR IN STARTING SCANE %@",exception);
        reject([exception name],[exception name],nil);
    }
}

RCT_EXPORT_METHOD(stopScan:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    [self callStop];
    resolve(nil);
}

RCT_EXPORT_METHOD(connect:(NSString *)address
                  findEventsWithResolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    NSLog(@"Trying to connect....%@",address);
    [self callStop];
    if(connected){
        NSString *connectedAddress =connected.identifier.UUIDString;
        if([address isEqualToString:connectedAddress]){
            resolve(nil);
            return;
        }else{
            [self.centralManager cancelPeripheralConnection:connected];
        }
    }
    CBPeripheral *peripheral = [self.foundDevices objectForKey:address];
    self.connectResolveBlock = resolve;
    self.connectRejectBlock = reject;
    if(peripheral){
          _waitingConnect = address;
          NSLog(@"Trying to connectPeripheral....%@",address);
        [self.centralManager connectPeripheral:peripheral options:nil];
    }else{
        _waitingConnect = address;
         NSLog(@"Scan to find ....%@",address);
        [self.centralManager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@NO}];
    }
}

-(void)callStop{
    if(self.centralManager.isScanning){
        [self.centralManager stopScan];
        NSMutableArray *devices = [[NSMutableArray alloc] init];
        for(NSString *key in self.foundDevices){
            NSLog(@"insert found devies:%@ =>%@",key,[self.foundDevices objectForKey:key]);
            NSString *name = [self.foundDevices objectForKey:key].name;
            if(!name){
                name = @"";
            }
            [devices addObject:@{@"address":key,@"name":name}];
        }
        NSError *error = nil;
        NSData* jsonData = [NSJSONSerialization dataWithJSONObject:devices options:NSJSONWritingPrettyPrinted error:&error];
        NSString * jsonStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        if(isHasListeners){
            [self sendEventWithName:EVENT_DEVICE_DISCOVER_DONE body:@{@"found":jsonStr,@"paired":@"[]"}];
        }
        if(self.scanResolveBlock){
            RCTPromiseResolveBlock rsBlock = self.scanResolveBlock;
            rsBlock(@{@"found":jsonStr,@"paired":@"[]"});
            self.scanResolveBlock = nil;
        }
    }
    if(timer && timer.isValid){
        [timer invalidate];
        timer = nil;
    }
    self.scanRejectBlock = nil;
    self.scanResolveBlock = nil;
}

- (void) initSupportServices
{
    if(!supportServices){
        CBUUID *issc = [CBUUID UUIDWithString: @"49535343-FE7D-4AE5-8FA9-9FAFD205E455"];
        supportServices = [NSArray arrayWithObject:issc];/*ISSC*/
        writeableCharactiscs = @{issc:@"49535343-8841-43F4-A8D4-ECBE34729BB3"};
    }
}

- (CBCentralManager *) centralManager
{
    @synchronized(_centralManager)
    {
        if (!_centralManager)
        {
            if (![CBCentralManager instancesRespondToSelector:@selector(initWithDelegate:queue:options:)])
            {
                //for ios version lowser than 7.0
                self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
            }else
            {
                self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options: nil];
            }
        }
        if(!instance){
            instance = self;
        }
    }
    [self initSupportServices];
    return _centralManager;
}

/**
 * CBCentralManagerDelegate
 **/
- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    NSLog(@"%ld",(long)central.state);
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI{
    NSLog(@"did discover peripheral: %@",peripheral);
    NSDictionary *idAndName =@{@"address":peripheral.identifier.UUIDString,@"name":peripheral.name?peripheral.name:@""};
    NSDictionary *peripheralStored = @{peripheral.identifier.UUIDString:peripheral};
    if(!self.foundDevices){
        self.foundDevices = [[NSMutableDictionary alloc] init];
    }
    [self.foundDevices addEntriesFromDictionary:peripheralStored];
    if(isHasListeners){
        [self sendEventWithName:EVENT_DEVICE_FOUND body:@{@"device":idAndName}];
    }
    if(_waitingConnect && [_waitingConnect isEqualToString: peripheral.identifier.UUIDString]){
        [self.centralManager connectPeripheral:peripheral options:nil];
        [self callStop];
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    NSLog(@"did connected: %@",peripheral);
    connected = peripheral;
    NSString *pId = peripheral.identifier.UUIDString;
    if(_waitingConnect && [_waitingConnect isEqualToString: pId] && self.connectResolveBlock){
        NSLog(@"Predefined the support services, stop to looking up services.");
        self.connectResolveBlock(nil);
        _waitingConnect = nil;
        self.connectRejectBlock = nil;
        self.connectResolveBlock = nil;
    }
       NSLog(@"going to emit EVENT_CONNECTED.");
    if(isHasListeners){
        [self sendEventWithName:EVENT_CONNECTED body:@{@"device":@{@"name":peripheral.name?peripheral.name:@"",@"address":peripheral.identifier.UUIDString}}];
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error{
    if(!connected && _waitingConnect && [_waitingConnect isEqualToString:peripheral.identifier.UUIDString]){
        if(self.connectRejectBlock){
            RCTPromiseRejectBlock rjBlock = self.connectRejectBlock;
            rjBlock(@"",@"",error);
            self.connectRejectBlock = nil;
            self.connectResolveBlock = nil;
            _waitingConnect=nil;
        }
        connected = nil;
        if(isHasListeners){
            [self sendEventWithName:EVENT_UNABLE_CONNECT body:@{@"name":peripheral.name?peripheral.name:@"",@"address":peripheral.identifier.UUIDString}];
        }
    }else{
        connected = nil;
        if(isHasListeners){
            [self sendEventWithName:EVENT_CONNECTION_LOST body:nil];
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error{
    if(self.connectRejectBlock){
        RCTPromiseRejectBlock rjBlock = self.connectRejectBlock;
        rjBlock(@"",@"",error);
        self.connectRejectBlock = nil;
        self.connectResolveBlock = nil;
        _waitingConnect = nil;
    }
    connected = nil;
    if(isHasListeners){
        [self sendEventWithName:EVENT_UNABLE_CONNECT body:@{@"name":peripheral.name?peripheral.name:@"",@"address":peripheral.identifier.UUIDString}];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error{
    if (error){
        NSLog(@"扫描外设服务出错：%@-> %@", peripheral.name, [error localizedDescription]);
        return;
    }
    NSLog(@"扫描到外设服务：%@ -> %@",peripheral.name,peripheral.services);
    for (CBService *service in peripheral.services) {
        [peripheral discoverCharacteristics:nil forService:service];
         NSLog(@"服务id：%@",service.UUID.UUIDString);
    }
    NSLog(@"开始扫描外设服务的特征 %@...",peripheral.name);
    
    if(error && self.connectRejectBlock){
        RCTPromiseRejectBlock rjBlock = self.connectRejectBlock;
         rjBlock(@"",@"",error);
        self.connectRejectBlock = nil;
        self.connectResolveBlock = nil;
        connected = nil;
    }else
    if(_waitingConnect && _waitingConnect == peripheral.identifier.UUIDString){
        RCTPromiseResolveBlock rsBlock = self.connectResolveBlock;
        rsBlock(peripheral.identifier.UUIDString);
        self.connectRejectBlock = nil;
        self.connectResolveBlock = nil;
        connected = peripheral;
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(nullable NSError *)error{
    if(toWrite && connected
       && [connected.identifier.UUIDString isEqualToString:peripheral.identifier.UUIDString]
       && [service.UUID.UUIDString isEqualToString:supportServices[0].UUIDString]){
        if(error){
            NSLog(@"Discrover charactoreristics error:%@",error);
           if(writeDataDelegate)
           {
               [writeDataDelegate didWriteDataToBle:false];
               return;
           }
        }
        for(CBCharacteristic *cc in service.characteristics){
            NSLog(@"Characterstic found: %@ in service: %@" ,cc,service.UUID.UUIDString);
            if([cc.UUID.UUIDString isEqualToString:[writeableCharactiscs objectForKey: supportServices[0]]]){
                @try{
                    [connected writeValue:toWrite forCharacteristic:cc type:CBCharacteristicWriteWithoutResponse];
                   if(writeDataDelegate) [writeDataDelegate didWriteDataToBle:true];
                    if(toWrite){
                        NSLog(@"Value wrote: %lu",[toWrite length]);
                    }
                }
                @catch(NSException *e){
                    NSLog(@"ERRO IN WRITE VALUE: %@",e);
                      [writeDataDelegate didWriteDataToBle:false];
                }
            }
        }
    }
    
    if(error){
        NSLog(@"Discrover charactoreristics error:%@",error);
        return;
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error{
    if(error){
        NSLog(@"Error in writing bluetooth: %@",error);
        if(writeDataDelegate){
            [writeDataDelegate didWriteDataToBle:false];
        }
    }
    
    NSLog(@"Write bluetooth success.");
    if(writeDataDelegate){
        [writeDataDelegate didWriteDataToBle:true];
    }
}
 
@end
