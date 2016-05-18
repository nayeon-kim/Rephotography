//
//  ViewController.h
//  RephotoApp
//
//  Created by Nayeon Kim on 10/26/15.
//  Copyright (c) 2015 Nayeon Kim. All rights reserved.
//

#ifdef __cplusplus
#import <opencv2/opencv.hpp>
#endif

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <opencv2/features2d/features2d.hpp>
#import <opencv2/nonfree/features2d.hpp>
#import <opencv2/highgui/cap_ios.h>
#import <opencv2/highgui/ios.h>
using namespace cv;

@interface ViewController : UIViewController <CvVideoCameraDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>
{
    IBOutlet UIImageView* videoCaptureView;
    IBOutlet UIButton* loadButton;
    CvVideoCamera* videoCamera;
}

- (IBAction)didStartCapture:(id)sender;
- (IBAction)didTapLoadButton:(id)sender;
- (IBAction)didTapStabilize:(id)stableButton;

@property (nonatomic, strong) CvVideoCamera* videoCamera;
@property (nonatomic) cv::Mat refImage;
@property (nonatomic) cv::Mat refContours;
@property (nonatomic) cv::Mat stableFrame;
@property (nonatomic) bool imageLoaded;
@property (nonatomic) bool captureInSession;
@property (nonatomic) bool initStable;

@end


