//
//  ViewController.mm
//  RephotoApp
//
//  Created by Nayeon Kim on 10/26/15.
//  Copyright (c) 2015 Nayeon Kim. All rights reserved.
//

#import "ViewController.h"

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
    
    self.imageLoaded = false;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UI Actions

- (IBAction)didTapLoadButton:(id)sender;
{
    UIImagePickerController *pickerController = [[UIImagePickerController alloc] init];
    pickerController.delegate = self;
    [self presentModalViewController:pickerController animated:YES];
    
}

- (IBAction)didStartCapture:(id)sender;
{
    if (self.imageLoaded) {
        
        // update dimensions of UIImageView videoCaptureView
        videoCaptureView.bounds = CGRectMake(videoCaptureView.bounds.origin.x, videoCaptureView.bounds.origin.y, videoCaptureView.frame.size.width, self.refImage.cols * (videoCaptureView.frame.size.width/self.refImage.rows));
        
        [self.videoCamera start];
        NSLog(@"video camera running: %d", [self.videoCamera running]);
        NSLog(@"capture session loaded: %d", [self.videoCamera captureSessionLoaded]);
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"No Reference Image" message:@"Please load a photo before starting!" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil ];
        
        [alertView show];
    }
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
//    cv::Mat cvImg;
//    UIImageToMat(image, cvImg);

    
    // Canny Edge Detector with picked image
    
    Mat cvImg_gray;
    Mat cvMatrix, edges;
    
    int ratio = 3;
    int kernel_size = 3;
    
    /// Create a matrix of the same type and size as src (for dst)
    cvMatrix.create( cvImg.size(), cvImg.type() );
    
    /// Convert the image to grayscale
    cvtColor( cvImg, cvImg_gray, CV_BGR2GRAY );
    
//    int CannyThreshold = 0.0;
    
    /// Show the image
//    CannyThreshold(0, 0);
    
    /// Reduce noise with a kernel 3x3
//    blur( cvImg_gray, cvImg_gray, cv::Size(3,3));
//    cv::GaussianBlur(cvImg_gray, cvImg_gray, cv::Size(5, 5));
    
    
    /// Canny detector
    Canny( cvImg_gray, edges, 100.0, 300.0, 3 );
//    Canny( cvImg_gray, detected_edges, CannyThreshold, CannyThreshold*ratio, kernel_size );

    /// Using Canny's output as a mask, we display our result
    cvMatrix = Scalar::all(0.0);
    cvImg.copyTo( cvMatrix, edges );
//    cvImg += detected_edges;
    
    self->loadedImageView.image = MatToUIImage(cvMatrix);

    self.refImage = cvImg;
    self.imageLoaded = true;
}
/**
 * Rotate an image
 */
void rotate(cv::Mat& src, double angle, cv::Mat& dst)
{
    int len = std::max(src.cols, src.rows);
    cv::Point2f pt(len/2., len/2.);
    cv::Mat r = cv::getRotationMatrix2D(pt, angle, 1.0);
    
    cv::warpAffine(src, dst, r, cv::Size(len, len));
}

// Convert from UIImage to CV Mat
- (cv::Mat) UIImageToMat: (UIImage *)loadedImage;
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(loadedImage.CGImage);
    
    UIImageOrientation orientation = loadedImage.imageOrientation;
    CGFloat cols, rows;
    rows = loadedImage.size.height;
    cols = loadedImage.size.width;
    
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
    
    if  (orientation != UIImageOrientationUp) {
        rotate(cvMat, -90, cvMat);
    }

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
