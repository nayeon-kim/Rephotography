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
    UIImagePickerController *pickerController = [[UIImagePickerController alloc] init];
    pickerController.delegate = self;
    [self presentModalViewController:pickerController animated:YES];
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
        self.initStable = true;
        //Should change contentMode here to allow warping?
//         videoCaptureView.contentMode = UIViewContentModeCenter;
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
//    UIImage *selectedImage = [self imageWithImage:selectedImg scaledToWidth:videoCaptureView.frame.size.width];
    UIImage *scaledSelectedImage = [self imageWithImage:selectedImg scaledToWidth:288];
    UIImage *selectedImage = [self imageWithInsets:scaledSelectedImage];
    
    cv::Mat cvRefImg;
    
    UIImageToMat(selectedImage, cvRefImg);
//    cv::Mat cvRefImg = [self UIImageToMat:selectedImage];
//    cv::resize(cvRefImg, cvRefImg, videoCaptureView.frame.size, 0, 0, INTER_LINEAR );
    
    // Canny Edge Detector with picked image
    Mat cvRefImg_gray;
    Mat cvRefImg_blurred;
    Mat cannyEdges;
    
    /// Create a matrix of the same type and size as src (for dst)
    
    /// Convert the image to grayscale
    cvtColor( cvRefImg, cvRefImg_gray, CV_BGR2GRAY );
    
    /// Reduce noise with a kernel 3x3
    int d = floor(videoCaptureView.frame.size.width/20);
//    std::cout << "what is d " << d << '\n';
    bilateralFilter ( cvRefImg_gray, cvRefImg_blurred, d, d*2, d/2 );
    
    /// Canny detector
    vector<vector<cv::Point> > contours;
    vector<Vec4i> hierarchy;
    int kernel_size = 3;
    Canny( cvRefImg_blurred, cannyEdges, 90, 120, kernel_size );
    findContours( cannyEdges, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE, cv::Point(0, 0) );
    
    /// Draw contours
    RNG rng(12345);
    Mat drawing = Mat::zeros( cannyEdges.size(), CV_8UC4 );
    for( int i = 0; i< contours.size(); i++ ){
//        std::cout << "what is arclength " << arcLength(contours[i], false) << '\n';
        // Discard short edges
        int shortEdgeThresh = 50;
        if (arcLength(contours[i], false) > shortEdgeThresh || arcLength(contours[i], true) > shortEdgeThresh) {
            Scalar color = Scalar(255,255,255);
            drawContours( drawing, contours, i, color, 1.6, 8, hierarchy, 0, cv::Point() );
        }
    }
    
    self.refImage = cvRefImg;
    self.refContours = drawing;
    videoCaptureView.image = MatToUIImage(self.refContours);
    
    // TEST1: SURF - DEBUG: not doing so good :(
//        SurfFeatureDetector detector( 10000, 10, 5 );
//        std::vector<KeyPoint> keypoints;
//        detector.detect( cvRefImg, keypoints );
//        Mat img_keypoints;
//        cvtColor( cvRefImg, cvRefImg, CV_BGRA2RGB);
//        drawKeypoints( cvRefImg, keypoints, img_keypoints, Scalar(255,0,0));
//    
//         videoCaptureView.image = MatToUIImage(img_keypoints);
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

-(UIImage*) imageWithInsets:(UIImage *)oldImage {
    // Setup a new context with the correct size
    CGFloat width = 288;
    CGFloat height = 352;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), YES, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIGraphicsPushContext(context);

    // Now we can draw anything we want into this new context.
    CGPoint origin = CGPointMake((width - oldImage.size.width) / 2.0f,
                                 (height - oldImage.size.height) / 2.0f);
    [oldImage drawAtPoint:origin];

    // Clean up and get the new image.
    UIGraphicsPopContext();
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
   
    cv::Mat refIm, refIm3, refIm_gray, currentFrame3;
    cv::Mat KLTIm, status, err;
    vector<cv::Point2f> featPts, nextPts;
    
    refIm = self.refImage;
    cvtColor(refIm, refIm3, CV_BGRA2BGR);

    // Params for ShiTomasi corner detection
    cvtColor( refIm, refIm_gray, CV_BGR2GRAY );
    //    goodFeaturesToTrack(refIm_gray, featPts, 5, 0.3, 7);
    
    
    if (!(self.stableFrame.empty())) {
        // If you have a stable frame do the stabilizing things
        
        // TEST: SURF
        SurfFeatureDetector detector( 10000, 10, 5 );
        std::vector<KeyPoint> keypoints_stable, keypoints_current;
        
        detector.detect( self.stableFrame, keypoints_stable );
        detector.detect( currentFrame, keypoints_current );
//        cvtColor( currentFrame, currentFrame, CV_BGRA2RGB);
//        drawKeypoints( currentFrame, keypoints_current, currentFrame, Scalar(255,0,0));
//        cvtColor( currentFrame, currentFrame, CV_BGR2RGBA);
        //    drawKeypoints( cvRefImg, keypoints, img_keypoints, Scalar(255,0,0));
        
        FlannBasedMatcher matcher;
        Mat descriptors_stable, descriptors_current;
        std::vector< DMatch > matches;
        
        SurfDescriptorExtractor extractor;
        extractor.compute( self.stableFrame, keypoints_stable, descriptors_stable );
        extractor.compute( currentFrame, keypoints_current, descriptors_current );
        
        if(descriptors_stable.type()!=CV_32F) {
            descriptors_stable.convertTo(descriptors_stable, CV_32F);
        }
        
        if(descriptors_current.type()!=CV_32F) {
            descriptors_current.convertTo(descriptors_current, CV_32F);
        }
        
        matcher.match( descriptors_stable, descriptors_current, matches );
        
        if (matches.size() > 4){
//            drawMatches(self.stableFrame, keypoints_stable, currentFrame, keypoints_current, matches, currentFrame);
            //if there are no matches, probably out of frame
            std::vector< DMatch > good_matches;
            double max_dist = 0; double min_dist = 200;
            int goodMatchCount = descriptors_stable.rows;
            for( int i = 0; i < goodMatchCount; i++ ){
                if( matches[i].distance < 3*min_dist && good_matches.size() < 4){
                    good_matches.push_back( matches[i]); }
            }
            std::vector<Point2f> refPts;
            std::vector<Point2f> currentPts;
            
            for( int i = 0; i < good_matches.size(); i++ )
            {
                //-- Get the keypoints from the good matches
                refPts.push_back( keypoints_stable[ good_matches[i].queryIdx ].pt );
                currentPts.push_back( keypoints_current[ good_matches[i].trainIdx ].pt );
            }
            
            // TODO: need to plot points to sanity check
                    cv::Mat HMatrix = findHomography(currentPts, refPts, CV_RANSAC);
            //        cv::Mat warpMatrix = getAffineTransform(refPts, currentPts);
//            cv::Mat warpMatrix = getPerspectiveTransform(currentPts, refPts);
            currentFrame += self.refContours;
            
            warpPerspective(currentFrame, currentFrame, HMatrix, currentFrame.size());
            //        warpAffine (currentFrame, currentFrame, warpMatrix, currentFrame.size());
            //        currentFrame += (self.stableFrame * 0.5);
        } else {
//            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Out of Frame Error" message:@"You're too far from the desired location!" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil ];
//            [alertView show];
            std::cout << "You're too far out of frame. " << '\n';
        }
    
    } else {
        // 4 channels
        currentFrame += self.refContours;
    }
}
#endif

@end
