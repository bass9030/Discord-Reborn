//
//  RBChatViewController.h
//  raspberry
//
//  Created by trevir on 10/18/19.
//  Copyright (c) 2019 Trevir. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DCChannel.h"
#import "UIBubbleTableView.h"
#import "UIBubbleTableViewDelegate.h"

@interface RBChatViewController : UIViewController <UIBubbleTableViewDataSource, UIImagePickerControllerDelegate, UIBubbleTableViewDelegate>

-(void)subscribeToChannelEvents:(DCChannel*)channel loadNumberOfMessages:(int)numMessages;

@end
