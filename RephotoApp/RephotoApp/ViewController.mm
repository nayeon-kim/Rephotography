//
//  ViewController.mm
//  RephotoApp
//
//  Created by Nayeon Kim on 10/26/15.
//  Copyright (c) 2015 Nayeon Kim. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController
@synthesize videoCamera;

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
//    TODO: if videoCapture on, then turn off first
    UIImagePickerController *pickerController = [[UIImagePickerController alloc] init];
    pickerController.delegate = self;
    [self presentModalViewController:pickerController animated:YES];
}

- (IBAction)didStartCapture:(id)sender {
    if (self.imageLoaded) {
        
// TODO: update dimensions of UIImageView videoCaptureView
//       videoCaptureView.contentMode = UIViewContentModeScaleToFill;
//       videoCaptureView.contentMode =  UIViewContentModeCenter;
//        videoCaptureView.frame = CGRectMake(videoCaptureView.bounds.origin.x, videoCaptureView.bounds.origin.y, videoCaptureView.frame.size.width, self.refImage.cols * (videoCaptureView.frame.size.width/self.refImage.rows));
        
//        videoCaptureView.bounds = CGRectMake(videoCaptureView.bounds.origin.x, videoCaptureView.bounds.origin.y, videoCaptureView.frame.size.width, self.refImage.cols * (videoCaptureView.frame.size.width/self.refImage.rows));
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
//    videoCaptureView.image = image;
    
    [self dismissModalViewControllerAnimated:YES];
    
    cv::Mat cvRefImg = [self UIImageToMat:image];
//        UIImageToMat(image, cvRefImg);
    
    // Canny Edge Detector with picked image
    Mat cvImg_gray;
    Mat cvImg_blurred;
    Mat cvMatrix, edges;
    
    //    int ratio = 3;
    //    int kernel_size = 3;
    
    /// Create a matrix of the same type and size as src (for dst)
    cvMatrix.create( cvRefImg.size(), cvRefImg.type() );
    
    /// Convert the image to grayscale
    cvtColor( cvRefImg, cvImg_gray, CV_BGR2GRAY );
    
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
    
    //    self.refImage = cvMatrix;
    self.refImage = cvRefImg;
    self.refContours = drawing;
    
    // TESTING: goodFeaturesToTrack vs. SIFT vs. SURF
    // TEST1: gFTT
//    vector<cv::Point2f> featPts;
//    cv::Mat featPtMat, testContours;
//    cv::Point p(0.0, 0.0);
//    cvtColor( self.refImage, testContours, CV_BGRA2GRAY );
//    goodFeaturesToTrack(testContours, featPts, 10, 0.3, 7);
//    
//    for ( int i=0; i < featPts.size(); i++ ) {
//        Point2f pt = featPts[i];
//        circle(cvRefImg, pt, 20, Scalar(255,0,0), 10);
//    }
    
    // TEST1: SURF
    SurfFeatureDetector detector( 5000 );
    std::vector<KeyPoint> keypoints;
    detector.detect( cvRefImg, keypoints );
    Mat img_keypoints;
    cvtColor( cvRefImg, cvRefImg, CV_BGRA2RGB);
    drawKeypoints( cvRefImg, keypoints, img_keypoints, Scalar(255,0,0));
    
     videoCaptureView.image = MatToUIImage(img_keypoints);
    
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

// Convert from UIImage to CV Mat : commenting out for now to use standard func
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
    
    cv::Mat cvMat(rows, cols, CV_8UC4);
//    cv::Mat cvMat(rows, cols, CV_8UC3);       // 8 bits per component, 4 channels
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
- (void)processImage:(Mat&)currentFrame;
{
    cv::Mat refIm, refIm_gray, image_copy;
    cv::Mat KLTIm, status, err;
    vector<cv::Point2f> featPts, nextPts;
    UIImage *testIm;
    
    // 3 channel image frame
    //    cvtColor(currentFrame, image_copy, CV_BGRA2BGR);
    cvtColor(currentFrame, currentFrame, CV_BGRA2BGR);
    
    // invert image
    //    bitwise_not(image_copy, image_copy);
    //    cvtColor(image_copy, image, CV_BGR2BGRA);
    
    cv::resize(self.refImage, refIm, currentFrame.size(), 0, 0, INTER_LINEAR );
    std::cout << "currentFrame size: " << currentFrame.size() << '\n';
    std::cout << "refIm size: " << self.refImage.size() << '\n';
    cvtColor(refIm, refIm, CV_BGRA2BGR);
    //    image_copy += refIm;
    
    // TODO: eventually find overlay or += rather than blend.
    double alpha = 0.8;
    double beta = 0.2;
//    addWeighted( currentFrame, alpha, refIm, beta, 0.0, currentFrame );
    
    // Params for ShiTomasi corner detection
    // Get refPts from refIm (must grayscale first)
    cvtColor( refIm, refIm_gray, CV_BGR2GRAY );
//    goodFeaturesToTrack(refIm_gray, featPts, 5, 0.3, 7);
    // TEST: SURF
    SurfFeatureDetector detector( 5000 );
    std::vector<KeyPoint> keypoints;
    detector.detect( refIm, keypoints );
    Mat img_keypoints;
    cvtColor( refIm, refIm, CV_BGRA2RGB);
//    drawKeypoints( cvRefImg, keypoints, img_keypoints, Scalar(255,0,0));
    
    std::cout << "featPts size: " << featPts.size() << '\n';
//    calcOpticalFlowPyrLK(refIm, currentFrame, keypoints, nextPts, status, err);
    // TODO: need to plot points to sanity check
    cv::Mat HMatrix = findHomography(featPts, keypoints);
//    cv::Mat HMatrix = findHomography(nextPts, featPts);
    //    calcOpticalFlowPyrLK(8-bit inputRefImage, sameSizeSameType 8-bit currentFrameImage, vec<2D float single-precision points> featPts, vec<2D points> nextPts, OutputArray status, OutputArray err);
    warpPerspective(currentFrame, currentFrame, HMatrix, currentFrame.size());
    
    currentFrame += refIm;
    
    // TODO: Need to save alpha info before
//    cvtColor(currentFrame, currentFrame, CV_BGR2BGRA);
    
    
    NSLog(@"img size: %f", currentFrame.size);
    NSLog(@"refImg size: %f", self.refImage.size);
}
#endif

@end
