//
//  ViewController.mm
//  RephotoApp
//
//  Created by Nayeon Kim on 10/26/15.
//  Copyright (c) 2015 Nayeon Kim. All rights reserved.
//

#import "ViewController.h"
//#import <opencv2/highgui/cap_ios.h>
//using namespace cv;

//@interface ViewController
//@interface ViewController : UIViewController<CvVideoCameraDelegate>

//@end

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
    [self.videoCamera start];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UI Actions

//- (IBAction)captureStart:(id)sender;
//{
//    printf("here!");
//    [self.videoCamera start];
//    NSLog(@"video camera running: %d", [self.videoCamera running]);
//    NSLog(@"capture session loaded: %d", [self.videoCamera captureSessionLoaded]);
//}

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
    
    [self overlayLoadedImage:image];
}

- (void) overlayLoadedImage: (UIImage *)loadedImage;
{
    // Convert from UIImage to CV Mat
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

}

#pragma mark - Protocol CvVideoCameraDelegate

#ifdef __cplusplus
- (void)processImage:(Mat&)image;
{
    // Do some OpenCV stuff with the image
    Mat image_copy;
    cvtColor(image, image_copy, CV_BGRA2BGR);
    
    // invert image
//    bitwise_not(image_copy, image_copy);
//    cvtColor(image_copy, image, CV_BGR2BGRA);
}
#endif

@end
