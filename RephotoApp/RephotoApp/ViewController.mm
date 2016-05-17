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
    //TODO: try higher resolution video in the future.
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset352x288;
    self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    //TODO: higher or lower frames per second?!?!
    self.videoCamera.defaultFPS = 30;
    
    self.imageLoaded = false;
    self.captureInSession = false;
    self.initStable = false;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UI Actions

- (IBAction)didTapLoadButton:(id)sender {
    if (self.captureInSession) {
        // If capture in session, stop first.
        [self.videoCamera stop];
        self.captureInSession = false;
    }
    std::cout << "didTapLoadButton" << '\n';
    UIImagePickerController *pickerController = [[UIImagePickerController alloc] init];
    pickerController.delegate = self;
    [self presentModalViewController:pickerController animated:YES];
    //TODO: Resize on load before processing
}

- (IBAction)didStartCapture:(id)sender {
    if (self.imageLoaded) {
        [self.videoCamera start];
        self.captureInSession = true;
        NSLog(@"video camera running: %d", [self.videoCamera running]);
        NSLog(@"capture session loaded: %d", [self.videoCamera captureSessionLoaded]);
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"No Reference Image" message:@"Please load a photo before starting!" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil ];
        [alertView show];
    }
}

- (IBAction)didTapStabilize:(id)sender {
    if (self.captureInSession) {
        // TODO: store a frame as self.stableFrame.
        self.initStable = true;
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"No Camera Running" message:@"There is no camera to stabilize!" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil ];
        [alertView show];
    }
}

#pragma mark -
#pragma mark UIImagePickerControllerDelegate

- (void) imagePickerController:(UIImagePickerController *)picker
         didFinishPickingImage:(UIImage *)selectedImg
                   editingInfo:(NSDictionary *)editingInfo
{
    [self dismissModalViewControllerAnimated:YES];
    
    // Scale and Resize Ref Photo to Fit videoCaptureView
//    videoCaptureView.contentMode = UIViewContentModeScaleAspectFill;
    UIImage *selectedImage = [self imageWithImage:selectedImg scaledToWidth:videoCaptureView.frame.size.width];
    
    cv::Mat cvRefImg;
    UIImageToMat(selectedImage, cvRefImg);
//    cv::Mat cvRefImg = [self UIImageToMat:selectedImage];
    std::cout << "selectedImage size: " << selectedImage.size.width << '\n';
    std::cout << "selectedImage size: " << selectedImage.size.height << '\n';
    //        UIImageToMat(image, cvRefImg);
//    cv::resize(cvRefImg, cvRefImg, videoCaptureView.frame.size, 0, 0, INTER_LINEAR );
//    std::cout << "currentFrame size: " << currentFrame.size() << '\n';
    std::cout << "cvrefIm size: " << cvRefImg.size() << '\n';

    
    // Canny Edge Detector with picked image
    Mat cvRefImg_gray;
    Mat cvRefImg_blurred;
    Mat cvMatrix, cannyEdges;
    
    /// Create a matrix of the same type and size as src (for dst)
//    cvMatrix.create( cvRefImg.size(), cvRefImg.type() );
    
    /// Convert the image to grayscale
//    cvtColor( cvRefImg, cvRefImg_gray, CV_BGR2GRAY );
    
    /// Reduce noise with a kernel 3x3
//    bilateralFilter ( cvRefImg_gray, cvRefImg_blurred, 23, 23*2, 23/2 );
    
    /// Canny detector
//    vector<vector<cv::Point> > contours;
//    vector<Vec4i> hierarchy;
//    int kernel_size = 3;
//    Canny( cvRefImg_blurred, cannyEdges, 10, 40, kernel_size );
//    findContours( cannyEdges, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE, cv::Point(0, 0) );
    
    /// Draw contours
//    RNG rng(12345);
//    Mat drawing = Mat::zeros( cannyEdges.size(), CV_8UC3 );
//    for( int i = 0; i< contours.size(); i++ ){
//        Scalar color = Scalar(255,255,255);
//        drawContours( drawing, contours, i, color, 2, 8, hierarchy, 0, cv::Point() );
//    }
    
    //    self.refImage = cvMatrix;
    self.refImage = cvRefImg;
//    self.refContours = drawing;
//    videoCaptureView.image = MatToUIImage(self.refContours);
    videoCaptureView.image = MatToUIImage(self.refImage);
    // TEST1: SURF
    //    SurfFeatureDetector detector( 5000 );
    //    std::vector<KeyPoint> keypoints;
    //    detector.detect( cvRefImg, keypoints );
    //    Mat img_keypoints;
    //    cvtColor( cvRefImg, cvRefImg, CV_BGRA2RGB);
    //    drawKeypoints( cvRefImg, keypoints, img_keypoints, Scalar(255,0,0));
    
    //     videoCaptureView.image = MatToUIImage(img_keypoints);
    //    videoCaptureView.image = MatToUIImage(cvRefImg);
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

-(UIImage*)imageWithImage: (UIImage*) sourceImage scaledToWidth: (float) i_width
{
    float oldWidth = sourceImage.size.width;
    float scaleFactor = i_width / oldWidth;
    
    float newHeight = sourceImage.size.height * scaleFactor;
    float newWidth = oldWidth * scaleFactor;
    
    UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight));
    [sourceImage drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
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
    if (self.captureInSession && self.initStable && self.stableFrame.empty()) {
        std::cout << "can capture stable frame her" << '\n';
        self.stableFrame = currentFrame;
        self.initStable = false;
    }
   
    
    cv::Mat refIm, refIm_gray, image_copy;
    cv::Mat KLTIm, status, err;
    vector<cv::Point2f> featPts, nextPts;
    
    // 3 channel image frame
    //    cvtColor(currentFrame, image_copy, CV_BGRA2BGR);
    cvtColor(currentFrame, currentFrame, CV_BGRA2BGR);
    
    // invert image
    //    bitwise_not(image_copy, image_copy);
    //    cvtColor(image_copy, image, CV_BGR2BGRA);
    
//    cv::resize(self.refImage, refIm, currentFrame.size(), 0, 0, INTER_LINEAR );
//    std::cout << "currentFrame size: " << currentFrame.size() << '\n';
//    std::cout << "refIm size: " << self.refImage.size() << '\n';
    cvtColor(refIm, refIm, CV_BGRA2BGR);
    //    image_copy += refIm;
    
    // Params for ShiTomasi corner detection
    // Get refPts from refIm (must grayscale first)
    cvtColor( refIm, refIm_gray, CV_BGR2GRAY );
    //    goodFeaturesToTrack(refIm_gray, featPts, 5, 0.3, 7);
    // TEST: SURF
    
    //    SurfFeatureDetector detector( 5000 );
    ////    std::vector<KeyPoint> keypoints;
    //    std::vector<KeyPoint> keypoints_ref, keypoints_current;
    //
    //    detector.detect( refIm, keypoints_ref );
    //    //DEBUG:  keypoints_current size is 0
    //    detector.detect( currentFrame, keypoints_current );
    //    drawKeypoints( currentFrame, keypoints_current, currentFrame, Scalar(255,0,0));
    //
    ////    Mat img_keypoints;
    ////    cvtColor( refIm, refIm, CV_BGRA2RGB);
    ////    drawKeypoints( cvRefImg, keypoints, img_keypoints, Scalar(255,0,0));
    //
    //    FlannBasedMatcher matcher;
    //    Mat descriptors_ref, descriptors_current;
    //    std::vector< DMatch > matches;
    //
    //    SurfDescriptorExtractor extractor;
    //
    //    //DEBUG:descriptors_current is zero and keypoints_current is also size=0
    //    extractor.compute( refIm, keypoints_ref, descriptors_ref );
    //    extractor.compute( currentFrame, keypoints_current, descriptors_current );
    //
    //
    //    if(descriptors_ref.type()!=CV_32F) {
    //        descriptors_ref.convertTo(descriptors_ref, CV_32F);
    //    }
    //
    //    if(descriptors_current.type()!=CV_32F) {
    //        descriptors_current.convertTo(descriptors_current, CV_32F);
    //    }
    //
    //    //print # descriptor - descriptors_current does not contain any descriptors
    //    matcher.match( descriptors_ref, descriptors_current, matches );
    //
    //    std::vector< DMatch > good_matches;
    //    double max_dist = 0; double min_dist = 100;
    //    for( int i = 0; i < descriptors_ref.rows; i++ ){
    //        if( matches[i].distance < 3*min_dist ){
    //            good_matches.push_back( matches[i]); }
    //    }
    //    std::vector<Point2f> refPts;
    //    std::vector<Point2f> currentPts;
    //
    //    for( int i = 0; i < good_matches.size(); i++ )
    //    {
    //        //-- Get the keypoints from the good matches
    //        refPts.push_back( keypoints_ref[ good_matches[i].queryIdx ].pt );
    //        currentPts.push_back( keypoints_current[ good_matches[i].trainIdx ].pt );
    //    }
    //
    //    std::cout << "featPts size: " << featPts.size() << '\n';
    ////    calcOpticalFlowPyrLK(refIm, currentFrame, keypoints, nextPts, status, err);
    //
    //    // TODO: need to plot points to sanity check
    //    cv::Mat HMatrix = findHomography(refPts, currentPts, CV_RANSAC);
    //    cv::Mat HMatrix = findHomography(nextPts, featPts);
    //    calcOpticalFlowPyrLK(8-bit inputRefImage, sameSizeSameType 8-bit currentFrameImage, vec<2D float single-precision points> featPts, vec<2D points> nextPts, OutputArray status, OutputArray err);
    //    warpPerspective(currentFrame, currentFrame, HMatrix, currentFrame.size());
    
    
    if (!(self.stableFrame.empty())) {
        // if you have a stable frame do the stabilizing things
    } else {
        currentFrame += refIm;
    }
    
    
    // TODO: Need to save alpha info before
    //    cvtColor(currentFrame, currentFrame, CV_BGR2BGRA);
    
    
    NSLog(@"img size: %f", currentFrame.size);
    NSLog(@"refImg size: %f", self.refImage.size);
}
#endif

@end
