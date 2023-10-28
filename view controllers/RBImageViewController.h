//
//  RBImageViewController.h
//  raspberry
//
//  Created by bass9030 on 2023. 7. 27..
//  Copyright (c) 2023년 Trevir. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RBImageViewController : UIViewController
-(void)setSelectedImg:(UIImage*)img;
- (UIView*) viewForZoomingInScrollView:(UIScrollView*)scrollview;
- (IBAction) OnDownloadButtonWasPressed : (UIButton*) sender;
@end
