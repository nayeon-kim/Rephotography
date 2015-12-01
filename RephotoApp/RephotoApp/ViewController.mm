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
    
    // Canny Edge Detector with picked image
    
    Mat cvImg_gray;
    Mat cvMatrix, detected_edges;
    
//    int edgeThresh = 1;
//    int lowThreshold;
//    int const max_lowThreshold = 100;
    int ratio = 3;
    int kernel_size = 3;
    
    /// Create a matrix of the same type and size as src (for dst)
    cvMatrix.create( cvImg.size(), cvImg.type() );
    
    /// Convert the image to grayscale
    cvtColor( cvImg, cvImg_gray, CV_BGR2GRAY );
    
    int CannyThreshold = 20.0;
    
    /// Show the image
//    CannyThreshold(0, 0);
    
    /// Reduce noise with a kernel 3x3
//    blur( cvImg_gray, cvImg_gray, cv::Size(3,3) );
        GaussianBlur(cvImg_gray, cvImg_gray, cvSize(5, 5),1.2,1.2);//remove small details
    /// Canny detector
    Canny( cvImg_gray, detected_edges, CannyThreshold, CannyThreshold*ratio, kernel_size );
    
    /// Using Canny's output as a mask, we display our result
    cvMatrix = Scalar::all(0.0);

    cvImg.copyTo( cvMatrix, detected_edges);
    
    self.refImage = cvMatrix;
    self.imageLoaded = true;
}

// Convert from UIImage to CV Mat
- (cv::Mat) UIImageToMat: (UIImage *)loadedImage;
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(loadedImage.CGImage);
    
    UIImageOrientation orientation = loadedImage.imageOrientation;
    CGFloat cols, rows;
    if  (orientation == UIImageOrientationLeft
         || orientation == UIImageOrientationRight) {
        cols = loadedImage.size.height;
        rows = loadedImage.size.width;
    } else {
        cols = loadedImage.size.width;
        rows = loadedImage.size.height;
    }
    
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
    double alpha = 0.3;
    double beta = 0.7;
    
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
