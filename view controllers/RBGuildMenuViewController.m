//
//  RBGuildMenuViewController.m
//  raspberry
//
//  Created by trev on 8/13/19.
//  Copyright (c) 2019 Trevir. All rights reserved.
//

#import "RBGuildMenuViewController.h"
#import "RBClient.h"
#import "DCChannel.h"
#import "RBChatViewController.h"
#import "RBGuildStore.h"
#import "DCGuild.h"
#import "RBNotificationEvent.h"

@interface RBGuildMenuViewController ()

@property (weak, nonatomic) IBOutlet UITableView *guildTableView;
@property (weak, nonatomic) IBOutlet UITableView *channelTableView;
@property DCGuild *selectedGuild;
@property DCChannel *selectedChannel;

@property NSOperationQueue* serverIconImageQueue;

@end

@implementation RBGuildMenuViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	
    self.serverIconImageQueue = [NSOperationQueue new];
    self.serverIconImageQueue.maxConcurrentOperationCount = 1;
    
	self.navigationItem.hidesBackButton = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self.guildTableView
                                             selector:@selector(reloadData)
                                                 name:RBNotificationEventLoadedGuildIcon
                                               object:nil];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	if(tableView == self.guildTableView){
        NSLog([NSString stringWithFormat:@"guildChange: %d", indexPath.row]);
		self.selectedGuild = [RBClient.sharedInstance.guildStore guildAtIndex:(int)indexPath.row];
        self.navigationItem.title = self.selectedGuild.name;
		[self.channelTableView reloadData];
	}
    
    if(tableView == self.channelTableView){
        NSLog([NSString stringWithFormat:@"channelChange: %d", indexPath.row]);

        self.selectedChannel = (DCChannel*)[self.selectedGuild.sortedChannels objectAtIndex:indexPath.row];
        
        [self performSegueWithIdentifier:@"guilds to chat" sender:self];
        
        [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
}



#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
	if(tableView == self.guildTableView)
		return [RBClient.sharedInstance.guildStore count];
	
    if(tableView == self.channelTableView)
        return self.selectedGuild.channels.count;
    
    return 0;
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if([segue.destinationViewController class] == [RBChatViewController class]){
        [((RBChatViewController*)segue.destinationViewController) subscribeToChannelEvents:self.selectedChannel loadNumberOfMessages:50];
        ((RBChatViewController*)segue.destinationViewController).title = self.selectedChannel.name;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	UITableViewCell *cell;
    
//    NSLog([NSString stringWithFormat:@"index: %d", indexPath.row]);
	
	if(tableView == self.guildTableView){
        DCGuild* guild = [RBClient.sharedInstance.guildStore guildAtIndex:(int)indexPath.row];
        NSLog([NSString stringWithFormat:@"server id: %@", guild.snowflake]);
        NSLog([NSString stringWithFormat:@"server name: %@", guild.name]);
		cell = [tableView dequeueReusableCellWithIdentifier:@"guild" forIndexPath:indexPath];
		cell.textLabel.text = @"";
        
        if(!guild.iconImage){
            NSLog([NSString stringWithFormat:@"Cached image not found: %d", indexPath.row]);
            [guild queueLoadIconImage];
        }
        
        cell.imageView.image = guild.iconImage;
	}
	
	if(tableView == self.channelTableView){
        DCChannel* channel = (DCChannel*)[self.selectedGuild.sortedChannels objectAtIndex:indexPath.row];
        
		cell = [tableView dequeueReusableCellWithIdentifier:@"channel" forIndexPath:indexPath];
		cell.textLabel.text = channel.name;
        
        UITableViewCellAccessoryType unreadIndicatorType;
        
        if(channel.isRead){
            unreadIndicatorType = UITableViewCellAccessoryDisclosureIndicator;
        }else{
            unreadIndicatorType = UITableViewCellAccessoryDetailDisclosureButton;
        }
        
        cell.accessoryType = unreadIndicatorType;
	}
    
	return cell;
}

@end
