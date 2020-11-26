//
//  ImageUtils.m
//  RNBluetoothEscposPrinter
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ImageUtils.h"
@implementation ImageUtils : NSObject
int p0[] = { 0, 0x80 };
int p1[] = { 0, 0x40 };
int p2[] = { 0, 0x20 };
int p3[] = { 0, 0x10 };
int p4[] = { 0, 0x08 };
int p5[] = { 0, 0x04 };
int p6[] = { 0, 0x02 };

+ (UIImage*)imagePadLeft:(NSInteger) left withSource: (UIImage*)source
{
    CGSize orgSize = [source size];
    CGSize size = CGSizeMake(orgSize.width + [[NSNumber numberWithInteger: left] floatValue], orgSize.height);
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context,
                                   [[UIColor whiteColor] CGColor]);
    CGContextFillRect(context, CGRectMake(0, 0, size.width, size.height));
    [source drawInRect:CGRectMake(left, 0, orgSize.width, orgSize.height)
             blendMode:kCGBlendModeNormal alpha:1.0];
    UIImage *paddedImage =  UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return paddedImage;
}

+(uint8_t *)imageToGreyImage:(UIImage *)image {
    // Create image rectangle with current image width/height
    int kRed = 1;
    int kGreen = 2;
    int kBlue = 4;

    int colors = kGreen | kBlue | kRed;

    CGFloat actualWidth = image.size.width;
    CGFloat actualHeight = image.size.height;
    NSLog(@"actual size: %f,%f",actualWidth,actualHeight);
    uint32_t *rgbImage = (uint32_t *) malloc(actualWidth * actualHeight * sizeof(uint32_t));
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(rgbImage, actualWidth, actualHeight, 8, actualWidth*4, colorSpace,
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipLast);
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGContextSetShouldAntialias(context, NO);
    CGContextDrawImage(context, CGRectMake(0, 0, actualWidth, actualHeight), [image CGImage]);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // now convert to grayscale
    uint8_t *m_imageData = (uint8_t *) malloc(actualWidth * actualHeight);
    // NSMutableString *toLog = [[NSMutableString alloc] init];
    for(int y = 0; y < actualHeight; y++) {
        for(int x = 0; x < actualWidth; x++) {
            uint32_t rgbPixel=rgbImage[(int)(y*actualWidth+x)];
            uint32_t sum=0,count=0;
            if (colors & kRed) {sum += (rgbPixel>>24)&255; count++;}
            if (colors & kGreen) {sum += (rgbPixel>>16)&255; count++;}
            if (colors & kBlue) {sum += (rgbPixel>>8)&255; count++;}
            // [toLog appendFormat:@"pixel:%d,sum:%d,count:%d,val:%d;",rgbPixel,sum,count,(int)(sum/count)];
            m_imageData[(int)(y*actualWidth+x)]=sum/count;
           
        }
    }
    return m_imageData;
}

+ (UIImage *)imageWithImage:(UIImage *)image scaledToFillSize:(CGSize)size
{
    CGFloat scale = MAX(size.width/image.size.width, size.height/image.size.height);
    CGFloat width = image.size.width * scale;
    CGFloat height = image.size.height * scale;
    CGRect imageRect = CGRectMake((size.width - width)/2.0f,
                                  (size.height - height)/2.0f,
                                  width,
                                  height);
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    [image drawInRect:imageRect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

+ (NSData*)bitmapToArray:(UIImage*) bmp
{
    CGDataProviderRef provider = CGImageGetDataProvider(bmp.CGImage);
    NSData* data = (id)CFBridgingRelease(CGDataProviderCopyData(provider));
    return data;
}

+ (NSData *)eachLinePixToCmd:(unsigned char *)src nWidth:(NSInteger) nWidth nHeight:(NSInteger) nHeight nMode:(NSInteger) nMode
{
    NSLog(@"SIZE OF SRC: %lu",sizeof(&src));
    NSInteger nBytesPerLine = (int)nWidth/8;
    unsigned char * data = malloc(nHeight*(8+nBytesPerLine));
    // const char* srcData = (const char*)[src bytes];
    NSInteger k = 0;
    // NSMutableString *toLog = [[NSMutableString alloc] init];
    for(int i=0;i<nHeight;i++){
        NSInteger var10 = i*(8+nBytesPerLine);
         //GS v 0 m xL xH yL yH d1....dk
                data[var10 + 0] = 29;//GS
                data[var10 + 1] = 118;//v
                data[var10 + 2] = 48;//0
                data[var10 + 3] =  (unsigned char)(nMode & 1);
                data[var10 + 4] =  (unsigned char)(nBytesPerLine % 256);//xL
                data[var10 + 5] =  (unsigned char)(nBytesPerLine / 256);//xH
                data[var10 + 6] = 1;//yL
                data[var10 + 7] = 0;//yH
        
        for (int j = 0; j < nBytesPerLine; ++j) {
            data[var10 + 8 + j] = (int) (p0[src[k]] + p1[src[k + 1]] + p2[src[k + 2]] + p3[src[k + 3]] + p4[src[k + 4]] + p5[src[k + 5]] + p6[src[k + 6]] + src[k + 7]);
            k =k+8;
        }
    }
    return [NSData dataWithBytes:data length:nHeight*(8+nBytesPerLine)];
}

+(unsigned char *)format_K_threshold:(unsigned char *) orgpixels
                        width:(NSInteger) xsize height:(NSInteger) ysize
{
    unsigned char * despixels = malloc(xsize*ysize);
    int graytotal = 0;
    int k = 0;
    
    int i;
    int j;
    int gray;
    for(i = 0; i < ysize; ++i) {
        for(j = 0; j < xsize; ++j) {
            gray = orgpixels[k] & 255;
            graytotal += gray;
            ++k;
        }
    }
    
    int grayave = graytotal / ysize / xsize;
    k = 0;
    // NSMutableString *logStr = [[NSMutableString alloc]init];
    // int oneCount = 0;
    for(i = 0; i < ysize; ++i) {
        for(j = 0; j < xsize; ++j) {
            gray = orgpixels[k] & 255;
            if(gray > grayave) {
                despixels[k] = 0;
            } else {
                despixels[k] = 1;
            }
            
            ++k;
        }
    }
    return despixels;
}

+(NSData *)pixToTscCmd:(uint8_t *)src width:(NSInteger) width
{
    int length = (int)width/8;
    uint8_t * data = malloc(length);
    int k = 0;
    for(int j = 0;k<length;++k){
        data[k] =(uint8_t)(p0[src[j]] + p1[src[j + 1]] + p2[src[j + 2]] + p3[src[j + 3]] + p4[src[j + 4]] + p5[src[j + 5]] + p6[src[j + 6]] + src[j + 7]);
        j+=8;
    }
    return [[NSData alloc] initWithBytes:data length:length];
}

@end
