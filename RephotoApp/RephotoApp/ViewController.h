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

@property (nonatomic, strong) CvVideoCamera* videoCamera;
@property (nonatomic) cv::Mat refImage;
@property (nonatomic) bool imageLoaded;

@end

