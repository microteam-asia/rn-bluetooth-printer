//
//  PrintImageBleWriteDelegate.m
//  RNBluetoothEscposPrinter
//

#import <Foundation/Foundation.h>
#import "PrintImageBleWriteDelegate.h"
@implementation PrintImageBleWriteDelegate


- (void) didWriteDataToBle: (BOOL)success
{NSLog(@"PrintImageBleWriteDelete diWriteDataToBle: %d",success?1:0);
    if(success){
        if(_now == -1){
             if(_pendingResolve) {_pendingResolve(nil); _pendingResolve=nil;}
        }else if(_now>=[_toPrint length]){
            unsigned char * initPrinter = malloc(5);
            initPrinter[0]=27;
            initPrinter[1]=77;
            initPrinter[2]=0;
            initPrinter[3]=13;
            initPrinter[4]=10;
            [RNBluetoothManager writeValue:[NSData dataWithBytes:initPrinter length:5] withDelegate:self];
            _now = -1;
            [NSThread sleepForTimeInterval:0.01f];
        }else {
            [self print];
        }
    }else if(_pendingReject){
        _pendingReject(@"PRINT_IMAGE_FAILED",@"PRINT_IMAGE_FAILED",nil);
        _pendingReject = nil;
    }
    
}

-(void) print
{
    @synchronized (self) {
    NSInteger sizePerLine = (int)(_width/8);

    NSData *subData = [_toPrint subdataWithRange:NSMakeRange(_now, sizePerLine)];
    NSLog(@"Write data:%@",subData);
    [RNBluetoothManager writeValue:subData withDelegate:self];
        _now = _now+sizePerLine;
        [NSThread sleepForTimeInterval:0.01f];
        
    }
}
@end
