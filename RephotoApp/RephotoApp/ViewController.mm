//
//  ViewController.mm
//  RephotoApp
//
//  Created by Nayeon Kim on 10/26/15.
//  Copyright (c) 2015 Nayeon Kim. All rights reserved.
//

#import "ViewController.h"
//#import <opencv2/highgui/cap_ios.h>

@implementation ViewController
//@synthesize imageView;
@synthesize videoCamera;
//@synthesize loadedImageView;

- (void)viewDidLoad {
    [super viewDidLoad];
//    Initialize Video
    self.videoCamera = [[CvVideoCamera alloc] initWithParentView:videoCaptureView];
    self.videoCamera.delegate = self;
    self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset352x288;
    self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    self.videoCamera.defaultFPS = 30;
//    self.videoCamera.grayscale = NO;
    
    self.imageLoaded = false;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UI Actions

- (IBAction)didStartCapture:(id)sender;
{
    if (self.imageLoaded) {
        [self.videoCamera start];
        NSLog(@"video camera running: %d", [self.videoCamera running]);
        NSLog(@"capture session loaded: %d", [self.videoCamera captureSessionLoaded]);
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"No Reference Image" message:@"Please load a photo before starting!" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil ];
        
        [alertView show];
    }
}

- (IBAction)didTapLoadButton:(id)sender;
{
    UIImagePickerController *pickerController = [[UIImagePickerController alloc] init];
    pickerController.delegate = self;
    [self presentModalViewController:pickerController animated:YES];

}
#pragma mark -
#pragma mark UIImagePickerControllerDelegate

- (void) imagePickerController:(UIImagePickerController *)picker
         didFinishPickingImage:(UIImage *)image
                   editingInfo:(NSDictionary *)editingInfo
{
    self->loadedImageView.image = image;
    [self dismissModalViewControllerAnimated:YES];
    
    cv::Mat cvImg = [self UIImageToMat:image];
    self.refImage = cvImg;
    self.imageLoaded = true;
}

// Convert from UIImage to CV Mat
- (cv::Mat) UIImageToMat: (UIImage *)loadedImage;
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(loadedImage.CGImage);
    CGFloat cols = loadedImage.size.width;
    CGFloat rows = loadedImage.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4);                                 // 8 bits per component, 4 channels
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to backing data
                                                    cols,                      // Width of bitmap
                                                    rows,                     // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), loadedImage.CGImage);
    CGContextRelease(contextRef);
    return cvMat;
}

#pragma mark - Protocol CvVideoCameraDelegate

#ifdef __cplusplus
- (void)processImage:(Mat&)image;
{
    double alpha = 0.7;
    double beta = 0.3;
    
    Mat refIm;
    NSLog(@"processImage began running");
    //    Mat image_copy;
    //    cvtColor(image, image_copy, CV_BGRA2BGR);
    
    // invert image
    //    bitwise_not(image_copy, image_copy);
    //    cvtColor(image_copy, image, CV_BGR2BGRA);

    cv::resize(self.refImage, refIm, image.size(), 0, 0, INTER_LINEAR );
    addWeighted( image, alpha, refIm, beta, 0.0, image);

//    NSLog(@"imgCopy size: %f", image_copy.size);
//    NSLog(@"refImg size: %f", self.refImage.size());
//    NSLog(@"dst size: %f", dst.size());
    
}
#endif

@end
