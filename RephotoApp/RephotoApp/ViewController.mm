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
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UI Actions

- (IBAction)didStartCapture:(id)sender;
{
    // TODO: only start camera capture if self.cvImg exists. else show message, please load an image
    [self.videoCamera start];
    // TODO: linear blend of each frame in self.videoCamera and self.cvImg
    NSLog(@"video camera running: %d", [self.videoCamera running]);
    NSLog(@"capture session loaded: %d", [self.videoCamera captureSessionLoaded]);
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
    
    //TODO: save cvImg as a property?
    self.refImage = cvImg;
}

- (cv::Mat) UIImageToMat: (UIImage *)loadedImage;
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
//    UIImageToMat(loadedImage, cvImage);
    return cvMat;
}

#pragma mark - Protocol CvVideoCameraDelegate

#ifdef __cplusplus
- (void)processImage:(Mat&)image;
{
    double alpha = 0.8;
    double beta = 0.2;
    
    Mat refIm;
//    NSLog(@"processImage began running");
    // Do some OpenCV stuff with the image
    Mat image_copy;
    cvtColor(image, image_copy, CV_BGRA2BGR);
    
    //TODO: try debug with cvtColor
    
    // invert image
//    bitwise_not(image_copy, image_copy);
//    cvtColor(image_copy, image, CV_BGR2BGRA);
    
    //TODO: I guess this method runs when the video capture is turned on? (doub. check), so do linear blending with self.cvImg here.
    cv::resize(self.refImage, refIm, image_copy.size(), 0, 0, INTER_LINEAR );
    int dstSize[] = {refIm.rows, refIm.cols};
    Mat dst(2, dstSize, CV_BGRA2BGR);
//    cv::resize(self.refImage, refIm, image_copy.size(), 0, 0, INTER_LINEAR );
//    NSLog(@"imgCopy size: %f", image_copy.size);
//    NSLog(@"refImg size: %f", self.refImage.size());
//    NSLog(@"dst size: %f", dst.size());
    addWeighted( image_copy, alpha, refIm, beta, 0.0, dst);
}
#endif

@end
