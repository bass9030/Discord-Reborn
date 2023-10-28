//
//  RBImageViewController.m
//  raspberry
//
//  Created by bass9030 on 2023. 7. 27..
//  Copyright (c) 2023년 Trevir. All rights reserved.
//

#import "RBImageViewController.h"

@interface RBImageViewController ()
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIImageView *imgView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *downloadBtn;

@end

@implementation RBImageViewController

-(void)setSelectedImg:(UIImage*)img{
    self.view = self.view;
    self.imgView.image = img;
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
    // TODO: add Image Save
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Image.png"];
//    
//    // Save image.
//    [UIImagePNGRepresentation(image) writeToFile:filePath atomically:YES];
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
