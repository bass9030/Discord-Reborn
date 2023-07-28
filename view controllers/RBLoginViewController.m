//
//  RBLoginViewController.m
//  raspberry
//
//  Created by Trevir on 8/6/19.
//  Copyright (c) 2019 Trevir. All rights reserved.
//

#import "RBLoginViewController.h"
#import "RBGuildStore.h"
#import "RBClient.h"
#import "RBWebSocket.h"
#import "RBWebSocketDelegate.h"
#import "RBNotificationEvent.h"

@interface RBLoginViewController ()

@property RBGuildStore* guildStore;
@property (weak, nonatomic) IBOutlet UITextField *tokenTextField;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loginIndicator;

@property bool authenticated;
@property bool autoAuthenticated;

@end

@implementation RBLoginViewController

- (void)viewDidLoad{
	[super viewDidLoad];
    
	self.navigationItem.hidesBackButton = YES;
    self.autoAuthenticated = NO;
    
    NSString *lastUsableToken = [NSUserDefaults.standardUserDefaults objectForKey:@"last usable token"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didLogin)
                                                 name:RBNotificationEventDidLogin
                                               object:nil];
    
    if(lastUsableToken){
        self.tokenTextField.text = lastUsableToken;
        self.autoAuthenticated = YES;
    }else{
        self.tokenTextField.text = UIPasteboard.generalPasteboard.string;
    }
}

-(void)viewDidAppear:(BOOL)animated{
    self.authenticated = false;
    if(self.autoAuthenticated) {
        [self loginButtonWasClicked];
    }
}

- (void)didReceiveMemoryWarning{
	[super didReceiveMemoryWarning];
}

- (IBAction)loginButtonWasClicked {
	[RBClient.sharedInstance newSessionWithTokenString:self.tokenTextField.text shouldResume:false];
	[self.loginIndicator startAnimating];
	[self.loginIndicator setHidden:false];
    [self.loginButton setHidden:true];
    
    [self performSelector:@selector(checkAuth) withObject:nil afterDelay:10];
}

#pragma mark RBLoginDelegate

// called by RBWebSocketDelegate on successful auth
-(void)didLogin {
	[self performSegueWithIdentifier:@"login to guilds" sender:self];
    self.authenticated = true;
    
    // user shouldn't be able to go back to this screen once logged in
    NSMutableArray *navigationArray = [[NSMutableArray alloc] initWithArray: self.navigationController.viewControllers];
    [navigationArray removeObjectAtIndex:0];
    self.navigationController.viewControllers = navigationArray;
}

-(void)checkAuth {
    if(!self.authenticated){
        [self.loginIndicator stopAnimating];
        [self.loginIndicator setHidden:true];
        [self.loginButton setHidden:false];
        
        [RBClient.sharedInstance endSession];
    
        [[[UIAlertView alloc]initWithTitle:@"Not connecting!" message:@"Check that you have the correct token and a decent internet connection" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
}

@end
