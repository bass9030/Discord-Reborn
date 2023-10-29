//
//  RBImageViewController.m
//  raspberry
//
//  Created by bass9030 on 2023. 7. 27..
//  Copyright (c) 2023년 Trevir. All rights reserved.
//

#import "RBImageViewController.h"
#import "DCMessageAttachment.h"
#import <UIKit/UIKit.h>
#import <QuartzCore/CALayer.h>

@interface RBImageViewController ()
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIImageView *imgView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *downloadBtn;
@property UIActivityIndicatorView *activityIndicator;
@property UIView *hudView;
@property UILabel *captionLabel;
@property UIImage *image;
@end

@implementation RBImageViewController

-(void)setSelectedImg:(DCMessageAttachment*)attachment{
    self.view = self.view;
    self.image = attachment.image;
    self.imgView.image = self.image;
}

- (UIView*) viewForZoomingInScrollView:(UIScrollView*)scrollview {
    return self.imgView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.scrollView.maximumZoomScale = 3.0;
    self.scrollView.minimumZoomScale = 1.0;
    self.scrollView.bouncesZoom = true;
    self.scrollView.showsHorizontalScrollIndicator = false;
    self.scrollView.showsVerticalScrollIndicator = false;
    self.scrollView.backgroundColor = [UIColor blackColor];
    self.scrollView.delegate = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)OnDownloadButtonWasPressed:(UIBarButtonItem*)sender
{
    NSLog(@"Download btn click");

    _hudView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 150, 110)];
    _hudView.center = self.view.center;
    _hudView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.85];
    _hudView.clipsToBounds = YES;
    _hudView.layer.cornerRadius = 10.0;
    
    _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    _activityIndicator.frame = CGRectMake(75 - (_activityIndicator.bounds.size.width / 2), 20, _activityIndicator.bounds.size.width, _activityIndicator.bounds.size.height);
    [_hudView addSubview:_activityIndicator];
    [_activityIndicator startAnimating];
    
    _captionLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 70, 110, 22)];
//    _captionLabel.center = _hudView.center;
    _captionLabel.backgroundColor = [UIColor clearColor];
    _captionLabel.textColor = [UIColor whiteColor];
    _captionLabel.font = [UIFont boldSystemFontOfSize:16];
//    _captionLabel.adjustsFontSizeToFitWidth = YES;
    _captionLabel.textAlignment = NSTextAlignmentCenter;
    _captionLabel.text = @"Downloading";
    [_hudView addSubview:_captionLabel];
    
    [self.view addSubview:_hudView];
    UIImageWriteToSavedPhotosAlbum(self.image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo: (void *) contextInfo {
    [_hudView removeFromSuperview];

    if(error) {
        NSLog(@"error: %@", error.localizedDescription);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Download fail!" message:@"There was a problem saving the image." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alert show];
        
    }else{
        NSLog(@"saved");
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Download complete!" message:@"The image has been successfully saved to your camera roll." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alert show];
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
