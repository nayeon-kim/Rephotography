//
//  ViewController.h
//  RephotoApp
//
//  Created by Nayeon Kim on 10/26/15.
//  Copyright (c) 2015 Nayeon Kim. All rights reserved.
//

//#ifdef __cplusplus
#import <opencv2/opencv.hpp>
//#endif

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#import <opencv2/highgui/cap_ios.h>
using namespace cv;

@interface ViewController : UIViewController
{
    IBOutlet UIImageView* imageView;
    IBOutlet UIButton* button;
    CvVideoCamera* videoCamera;
}
@property (nonatomic, retain) CvVideoCamera* videoCamera;

- (IBAction)actionStart:(id)sender;


@end

