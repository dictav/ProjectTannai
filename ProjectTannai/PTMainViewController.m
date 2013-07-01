//
//  PTMainViewController.m
//  ProjectTannai
//
//  Created by Abe Shintaro on 2012/10/16.
//  Copyright (c) 2012年 Abe Shintaro. All rights reserved.
//

#import "PTMainViewController.h"
#import "Tesseract.h"
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UITextChecker.h>
#import "NSObject+switch.h"
@interface NSLocale (CustomLang)
+ (NSArray *)preferredLanguages;
@end

@implementation NSLocale (CustomLang)
+ (NSArray *)preferredLanguages {
    return [NSArray arrayWithObject:@"ja"];
}
@end
@interface PTMainViewController () <UIGestureRecognizerDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>
@property (assign) IBOutlet UIView *videoPreviewView;
@property (assign) AVCaptureVideoPreviewLayer *previewLayer;
@end

@implementation PTMainViewController
{
    AVCaptureSession *_captureSession;
    AVCaptureStillImageOutput *_stillImageOutput;
    AVCaptureVideoDataOutput *_videoOutput;
    Tesseract *tesseract;
    BOOL isRecognizing;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Init Tesseract
    isRecognizing = NO;
    tesseract = [[Tesseract alloc] initWithDataPath:@"tessdata" language:@"eng"];
    [tesseract setVariableValue:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ" forKey:@"tessedit_char_whitelist"];

//    [self recognizeSample];
//    return;
    // setup session
    _captureSession = [AVCaptureSession new];
    [_captureSession beginConfiguration];
    _captureSession.sessionPreset = AVCaptureSessionPresetHigh;


    // Init the device inputs
    AVCaptureDevice *camera = nil;
    for (AVCaptureDevice *device in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        if (device.position == AVCaptureDevicePositionBack) {
            camera = device;
        }
    }
    NSAssert(camera, @"couldn't get a camera");
    
    NSError *error = nil;
    AVCaptureDeviceInput *input = [[AVCaptureDeviceInput alloc] initWithDevice:camera error:&error];
    NSAssert(input && !error, @"couldn't ready a camera: %@", error);
    [_captureSession addInput:input];

    // Still image output
//    AVCaptureStillImageOutput *output = [AVCaptureStillImageOutput new];
//    NSAssert(input && !error, @"couldn't get a capture still image output: %@", error);
//    output.outputSettings = @{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)};
//    output.outputSettings = @{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)};
//    [_captureSession addOutput:output];
    
    // Video output
    AVCaptureVideoDataOutput *videoOutput = [AVCaptureVideoDataOutput new];
    videoOutput.videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)};
    dispatch_queue_t queue = dispatch_get_main_queue();//dispatch_queue_create("dictav.video.queue", NULL);

    [videoOutput setSampleBufferDelegate:self queue:queue];
    [_captureSession addOutput:videoOutput];
    
    // Create video preview layer and add it to the UI
    AVCaptureVideoPreviewLayer *newCaptureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    
    int width = self.videoPreviewView.bounds.size.width;
    int height = self.videoPreviewView.bounds.size.height;
    CGRect bounds = CGRectMake(-width/2, -height/2, width*2, height*2);
    [newCaptureVideoPreviewLayer setFrame:bounds];
    [newCaptureVideoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    CALayer *viewLayer = self.videoPreviewView.layer;
    [viewLayer setMasksToBounds:YES];
    [viewLayer insertSublayer:newCaptureVideoPreviewLayer below:[[viewLayer sublayers] objectAtIndex:0]];
    
    [_captureSession commitConfiguration];
    // Start the session. This is done asychronously since -startRunning doesn't return until the session is running.
    [[NSOperationQueue new] addOperationWithBlock:^{
        [_captureSession startRunning];
        AVCaptureConnection *conn = videoOutput.connections.lastObject;
        conn.videoOrientation = AVCaptureVideoOrientationPortrait;
        self.previewLayer = newCaptureVideoPreviewLayer;
    }];
    
    
    
}

- (void)recognizeSample
{
    UIImage *image = [UIImage imageNamed:@"text_sample3 small.jpeg"];
    _hogeView.image = image;
    [tesseract setImage:image];

    NSDate *date = [NSDate new];

    if ([tesseract recognize]) {
        NSLog(@"%lf", [date timeIntervalSinceNow]);
        NSLog(@"recognized text: %@", tesseract.recognizedText);
        NSCharacterSet *cSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        NSArray *words = [tesseract.recognizedText componentsSeparatedByCharactersInSet:cSet];
        static UITextChecker *checker = nil;
        if (!checker) {
            checker = [UITextChecker new];
        }
        for (NSString *word in words) {
            if ([word isEqualToString:@""]) {
                continue;
            }
            NSLog(@"word: %@", word);
            // 入力した文字列を使って候補を取得
            NSArray *suggestions = [checker guessesForWordRange:NSMakeRange(0, [word length])
                                                       inString:word
                                                       language:@"en_US"];
            if (suggestions.count) {
                NSLog(@"suggestions: %@", suggestions);
            }
            // 一致した単語があるかどうかを判定
            BOOL isMatched = [UIReferenceLibraryViewController dictionaryHasDefinitionForTerm:word];
            if (isMatched) {
                NSLog(@"matched: %@", word);
            } else {
                NSLog(@"not matched");
            }
        }

    } else {
        NSLog(@"couldn't recognize");
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Flipside View

- (void)flipsideViewControllerDidFinish:(PTFlipsideViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showAlternate"]) {
        [[segue destinationViewController] setDelegate:self];
    }
}

#pragma mark -
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (!isRecognizing) {
        return;
    }
    isRecognizing = NO;
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // Lock the base address of the pixel buffer.
    CVPixelBufferLockBaseAddress(imageBuffer,0);
    
    // Get the number of bytes per row for the pixel buffer.
//    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // Get the pixel buffer width and height.
    int width = CVPixelBufferGetWidth(imageBuffer);
    int w = width/4;
    int xOffset = (width - w)/2;
    int height = CVPixelBufferGetHeight(imageBuffer);
    int h = height/4;
    int yOffset = (height - h)/2;
    int wh = w*h;
    
    
    // Get Y offset
    CVPlanarPixelBufferInfo_YCbCrBiPlanar *planar = CVPixelBufferGetBaseAddress(imageBuffer);
    size_t offset = NSSwapBigLongToHost(planar->componentInfoY.offset);
    size_t bytesPerRow = NSSwapBigLongToHost(planar->componentInfoY.rowBytes);
    // Get the base address of the pixel buffer.
//    unsigned char* baseAddress = (unsigned char *)CVPixelBufferGetBaseAddress(imageBuffer);
//    unsigned char* baseAddress = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
    unsigned char* pixel = (unsigned char*)planar + offset;// + width * yOffset;
    // Get the data size for contiguous planes of the pixel buffer.
//    size_t bufferSize = CVPixelBufferGetDataSize(imageBuffer);
    
    /*
    int threshold = 0;
    for (int y=yOffset; y<h + yOffset; y++) {
        for (int x=xOffset; x < w + xOffset; x++) {
            threshold += pixel[x + width*y ];
        }
    }
    threshold /= wh;
    
    // Create Look Up Table
    unsigned char LUT[256] = {0};
    for (int i = threshold; i < 256; i++) {
        LUT[i] = 255;
    }
    */
    
    // Create buffer
    unsigned char* buffer = NULL;
    if (buffer == NULL) {
        buffer = (unsigned char *)malloc(sizeof(unsigned char) * wh);
    }
    
    
    int i=0;
    for (int y=yOffset; y<h + yOffset; y++) {
        for (int x=xOffset; x < w + xOffset; x++) {
            buffer[i] = pixel[x + width*y];
            i++;
        }
    }
    
    // Create UIImage
#ifdef DEBUG
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    size_t bitsPerPixel = bytesPerRow/width*8;
    CGContextRef context = CGBitmapContextCreate(buffer, w, h, 8, w, colorSpace, kCGImageAlphaNone);
    //    CGContextRef context = CGBitmapContextCreate(pixel, width, height, bitsPerPixel, bytesPerRow, colorSpace, kCGImageAlphaNone);
    CGImageRef newImage = CGBitmapContextCreateImage(context);
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
//    CGDataProviderRef  dataProvider = CGDataProviderCreateWithData(NULL, baseAddress,
//                                                                   height * bytesPerRow, NULL);
//    CGImageRef newImage = CGImageCreate(width, height, 8, 8, bytesPerRow,
//                                        colorSpace, kCGImageAlphaNone, dataProvider, NULL, NO, kCGRenderingIntentDefault);
//    CGDataProviderRelease(dataProvider);
    
    UIImage *image = [UIImage imageWithCGImage:newImage];
    self.hogeView.image = image;
#endif
//    return;
//    NSDate *date = [NSDate new];
//    NSLog(@"recognizing");
//    CGSize size = CGSizeMake(width, height);
//    [tesseract setImageWithPixels:buffer withSize:size bytesPerPixel:1];
//    if ([tesseract recognize]) {
//        NSLog(@"recognized : %lf\n%@", [date timeIntervalSinceNow], tesseract.recognizedText);
//    } else {
//        NSLog(@"couldn't recognize");
//    }

    NSDate *date = [NSDate new];
    NSLog(@"recognizing");
    [tesseract setImage:image];
    if ([tesseract recognize]) {
        NSLog(@"recognized : %lf\n%@", [date timeIntervalSinceNow], tesseract.recognizedText);
        NSCharacterSet *cSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        for (NSString *word in [tesseract.recognizedText componentsSeparatedByCharactersInSet:cSet]) {
            BOOL isMatched = [UIReferenceLibraryViewController dictionaryHasDefinitionForTerm:word];
            if (isMatched) {
                UIReferenceLibraryViewController *vc = [[UIReferenceLibraryViewController alloc] initWithTerm:word];
                [self presentModalViewController:vc animated:YES];
                break;
            }
        }
        
    } else {
        NSLog(@"couldn't recognize");
    }
    
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    isRecognizing = NO;
}

- (void) captureStillImage
{
    isRecognizing = YES;
    return;
    AVCaptureStillImageOutput *output = _captureSession.outputs.lastObject;
    AVCaptureConnection *connection = nil;
    for (AVCaptureConnection *conn in output.connections) {
        for (AVCaptureInputPort *port in conn.inputPorts) {
            if ([port.mediaType isEqual:AVMediaTypeVideo]) {
                connection = conn;
                break;
            }
        }
        if (connection) break;
    }
    
    void (^completionHandler)(CMSampleBufferRef,NSError*);
    completionHandler = ^(CMSampleBufferRef sampleBuffer, NSError *error){
        if (error) {
            NSLog(@"error: %@",error);
            return ;
        }
        NSLog(@"recognizing");
        
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        // Lock the base address of the pixel buffer.
        CVPixelBufferLockBaseAddress(imageBuffer,0);
        
        // Get the number of bytes per row for the pixel buffer.
        size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
        NSLog(@"bytesPerRow: %d", bytesPerRow);
        // Get the pixel buffer width and height.
        size_t width = CVPixelBufferGetWidth(imageBuffer);
        size_t height = CVPixelBufferGetHeight(imageBuffer);
        NSLog(@"width,height: %d, %d", width, height);
        
        // Get the base address of the pixel buffer.
//        void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
        uint32_t *pixels = CVPixelBufferGetBaseAddress(imageBuffer);
        // Get the data size for contiguous planes of the pixel buffer.
        size_t bufferSize = CVPixelBufferGetDataSize(imageBuffer);
        NSLog(@"size: %d", bufferSize);
        
        // convert to white and black
//        for (int i = 0; i < width * height;i++) {
//            unsigned int r = pixels[i] >> 24;
//            unsigned int g = pixels[i] & 0x00FF0000 >> 16;
//            unsigned int b = pixels[i] & 0x0000FF00 >> 8;
//            int a = pixels[i] & 0x000000FF;
//            int y = r*0.3 + g*0.59 + b*0.11;
//            if (y > 90) {
//                pixels[i] = 0xFFFFFFFF;
//            } else {
//                pixels[i] = 0x00000000;
//            }
// 
//        }

        // Create a device-dependent RGB color space.
        static CGColorSpaceRef colorSpace = NULL;
        if (colorSpace == NULL) {
            colorSpace = CGColorSpaceCreateDeviceRGB();
        }
        
        
        // Create a Quartz direct-access data provider that uses data we supply.
        CGDataProviderRef dataProvider =
        CGDataProviderCreateWithData(NULL, pixels, bufferSize, NULL);
        // Create a bitmap image from data supplied by the data provider.
        CGImageRef cgImage =
        CGImageCreate(width, height, 8, 32, bytesPerRow,
                      colorSpace, kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Little,
                      dataProvider, NULL, true, kCGRenderingIntentDefault);
        CGDataProviderRelease(dataProvider);
        
        // Create and return an image object to represent the Quartz image.
        UIImage *image = [UIImage imageWithCGImage:cgImage];
        CGImageRelease(cgImage);
        NSLog(@"image:%@", image);
        NSData *data = UIImagePNGRepresentation(image);

        NSURL *url = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
        url = [url URLByAppendingPathComponent:@"hoge.png"];

        [data writeToURL:url atomically:YES];
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            self.hogeView.image = image;
        }];
        
        // Recognize
        CGSize size = CGSizeMake(width, height);
        [tesseract setImageWithPixels:pixels withSize:size bytesPerPixel:sizeof(uint32_t)];
        if ([tesseract recognize]) {
            NSLog(@"recognized : %@", tesseract.recognizedText);
        } else {
            NSLog(@"couldn't recognize");
        }
        CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
        
    };
    

    [output captureStillImageAsynchronouslyFromConnection:connection
                                        completionHandler:completionHandler];

}

- (void)viewDidUnload {
    [self setHogeView:nil];
    [super viewDidUnload];
}

@end

