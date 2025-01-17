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
#import "UIKit/UIKit.h"

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
		self.selectedGuild = [RBClient.sharedInstance.guildStore guildAtIndex:(int)indexPath.row];
        self.navigationItem.title = self.selectedGuild.name;
		[_channelTableView reloadData];
	}
    
    if(tableView == self.channelTableView){
        if([self.selectedGuild.snowflake isEqual:@"0"]) {
            self.selectedChannel = (DCChannel*)[self.selectedGuild.sortedChannels objectAtIndex:indexPath.row];
        }else{
            NSString* categorySnowflake = [self.selectedGuild.sortedCategorys objectAtIndex:indexPath.section];
            self.selectedChannel = (DCChannel*)[(NSMutableArray*)[self.selectedGuild.channelsWithCategory objectForKey:categorySnowflake] objectAtIndex:indexPath.row];
        }
        
        [self performSegueWithIdentifier:@"guilds to chat" sender:self];
        
        [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
}


// category count
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if(tableView == self.guildTableView || [self.selectedGuild.snowflake isEqual:@"0"]) return 1;
    return self.selectedGuild.channelsWithCategory.allKeys.count;
}


// category title
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(tableView == self.guildTableView || [self.selectedGuild.snowflake isEqual:@"0"]) return @"";
    NSString* categorySnowflake = [self.selectedGuild.sortedCategorys objectAtIndex:section];
    NSString* categoryName = [[self.selectedGuild.categorys objectForKey:categorySnowflake] name];
    return categoryName;
}


#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if(tableView == self.guildTableView)
		return [RBClient.sharedInstance.guildStore count];
	
    if(tableView == self.channelTableView){
        if([self.selectedGuild.snowflake isEqual:@"0"])
            return self.selectedGuild.sortedChannels.count;
        NSString *key = [self.selectedGuild.sortedCategorys objectAtIndex: section];
        return [(NSMutableArray*) [self.selectedGuild.channelsWithCategory objectForKey: key] count];
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	UITableViewCell *cell;
    
	if(tableView == self.guildTableView){
        DCGuild* guild = [RBClient.sharedInstance.guildStore guildAtIndex:(int)indexPath.row];
		cell = [tableView dequeueReusableCellWithIdentifier:@"guild" forIndexPath:indexPath];
		cell.textLabel.text = @"";
        
        if(!guild.iconImage){
            if(!guild.iconHash || [guild.iconHash isEqual:[NSNull null]]) {
                cell.textLabel.text = guild.name;
            }else{
                [guild queueLoadIconImage];
            }
        }
        
        cell.imageView.image = guild.iconImage;
    }
	
	if(tableView == self.channelTableView){
        DCChannel* channel;
        if([self.selectedGuild.snowflake isEqual:@"0"]) {
            // private channel
            channel = [self.selectedGuild.sortedChannels objectAtIndex:indexPath.row];
        }else{
            NSString *key = self.selectedGuild.sortedCategorys[indexPath.section];
            NSArray *content = self.selectedGuild.channelsWithCategory[key];
            channel = (DCChannel*)[content objectAtIndex:indexPath.row];
        }

		cell = [tableView dequeueReusableCellWithIdentifier:@"channel"];
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"channel"];
        }
		cell.textLabel.text = channel.name;
        
        UITableViewCellAccessoryType unreadIndicatorType;
        
        
        
        if(channel.isRead){
            unreadIndicatorType = UITableViewCellAccessoryDisclosureIndicator;
        }else{
            unreadIndicatorType = UITableViewCellAccessoryDetailDisclosureButton;
        }
        
        if(channel.channelType == DCChannelTypeGuildText ||
           channel.channelType == DCChannelTypeDirectMessage ||
           channel.channelType == DCChannelTypeGroupMessage ||
           channel.channelType == DCChannelTypeGuildNews) {
            cell.userInteractionEnabled = true;
            cell.textLabel.textColor = [UIColor blackColor];
        }else {
            cell.userInteractionEnabled = false;
            cell.textLabel.textColor = [UIColor grayColor];
            unreadIndicatorType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
        cell.accessoryType = unreadIndicatorType;
	}
    
	return cell;
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if([segue.destinationViewController class] == [RBChatViewController class]){
        [((RBChatViewController*)segue.destinationViewController) subscribeToChannelEvents:self.selectedChannel loadNumberOfMessages:20];
        ((RBChatViewController*)segue.destinationViewController).title = self.selectedChannel.name;
    }
}

@end
