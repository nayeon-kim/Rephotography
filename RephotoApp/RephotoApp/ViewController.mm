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

- (IBAction)didTapLoadButton:(id)sender {
    UIImagePickerController *pickerController = [[UIImagePickerController alloc] init];
    pickerController.delegate = self;
    [self presentModalViewController:pickerController animated:YES];
}

- (IBAction)didStartCapture:(id)sender {
    if (self.imageLoaded) {
        
        // update dimensions of UIImageView videoCaptureView
        videoCaptureView.bounds = CGRectMake(videoCaptureView.bounds.origin.x, videoCaptureView.bounds.origin.y, videoCaptureView.frame.size.width, self.refImage.cols * (videoCaptureView.frame.size.width/self.refImage.rows));
        //        videoCaptureView.bounds = CGRectMake(videoCaptureView.bounds.origin.x, videoCaptureView.bounds.origin.y, self.refImage.rows/10, self.refImage.cols/10);
        
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
//    self->loadedImageView.image = image;
    
    
    videoCaptureView.image = image;
    
    [self dismissModalViewControllerAnimated:YES];
    
    cv::Mat cvImg = [self UIImageToMat:image];
    //    cv::Mat cvImg;
    //    UIImageToMat(image, cvImg);
    
    // Canny Edge Detector with picked image
    Mat cvImg_gray;
    Mat cvImg_blurred;
    Mat cvMatrix, edges;
    
    //    int ratio = 3;
    //    int kernel_size = 3;
    
    /// Create a matrix of the same type and size as src (for dst)
    cvMatrix.create( cvImg.size(), cvImg.type() );
    
    /// Convert the image to grayscale
    cvtColor( cvImg, cvImg_gray, CV_BGR2GRAY );
    
    //    int CannyThreshold = 0.0;
    
    /// Show the image
    
    /// Reduce noise with a kernel 3x3
    //    blur( cvImg_gray, cvImg_blurred, cv::Size(23,23));
    //    GaussianBlur(cvImg_gray, cvImg_blurred, cv::Size(23,23), 1, 1);
    bilateralFilter ( cvImg_gray, cvImg_blurred, 23, 23*2, 23/2 );
    //    self->loadedImageView.image = MatToUIImage(cvImg_blurred);
    
    /// Canny detector
    //    Canny( detected_edges, detected_edges, lowThreshold, lowThreshold*ratio, kernel_size );
    
    //    Canny( cvImg_gray, edges, 100.0, 300.0, 3 );
    vector<vector<cv::Point> > contours;
    vector<Vec4i> hierarchy;
    Canny( cvImg_blurred, edges, 10, 40, 3 );
    findContours( edges, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE, cv::Point(0, 0) );
    
    /// Draw contours
    RNG rng(12345);
    Mat drawing = Mat::zeros( edges.size(), CV_8UC3 );
    for( int i = 0; i< contours.size(); i++ )
    {
        Scalar color = Scalar(255,255,255);
        drawContours( drawing, contours, i, color, 2, 8, hierarchy, 0, cv::Point() );
    }
    
    /// Using Canny's output as a mask, we display our result
    cvMatrix = Scalar::all(0.0);
    //    cvImg_gray.copyTo( cvMatrix, edges );
    //    cvImg.copyTo( cvMatrix, drawing );
    
    //    self->loadedImageView.image = MatToUIImage(cvMatrix);
    
    
//    TESTING no loadedImageView.image
//    self->loadedImageView.image = MatToUIImage(drawing);
    videoCaptureView.image = MatToUIImage(drawing);
    
    //    self.refImage = cvMatrix;
    self.refImage = drawing;
    //    self.refImage = cvImg;
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
    cols = loadedImage.size.height;
    rows = loadedImage.size.width;
    NSLog(@"cols: %f", cols);
    NSLog(@"rows: %f", rows);
    //TODO: shouldn't the width be cols
    
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
    
    Mat refIm, image_copy;
    //    NSLog(@"processImage began running");
    //    Mat image_copy;
    cvtColor(image, image_copy, CV_BGRA2BGR);
    
    // invert image
    //    bitwise_not(image_copy, image_copy);
    //    cvtColor(image_copy, image, CV_BGR2BGRA);
    
    cv::resize(self.refImage, refIm, image_copy.size(), 0, 0, INTER_LINEAR );
    cvtColor(refIm, refIm, CV_BGRA2BGR);
    //    image_copy += refIm;
    addWeighted( image_copy, alpha, refIm, beta, 0.0, image);
    
    NSLog(@"img size: %f", image.size);
    NSLog(@"refImg size: %f", self.refImage.size);
    //    NSLog(@"dst size: %f", dst.size());
    
}
#endif

@end
