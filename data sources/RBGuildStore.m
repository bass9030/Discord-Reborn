//
//  RBServerStore.m
//  raspberry
//
//  Created by Trevir on 5/31/19.
//  Copyright (c) 2019 Trevir. All rights reserved.
//

#import "RBGuildStore.h"
#import "DCChannel.h"
#import "DCGuild.h"
#import "RBGatewayEvent.h"

@interface RBGuildStore()

@property NSMutableDictionary* guildDictionary;
@property NSMutableArray* guildKeys;
@property NSMutableDictionary* channelDictionary;

@end

@implementation RBGuildStore

-(void)handleReadyEvent:(RBGatewayEvent*)event {
	if(![event.t isEqualToString:@"READY"]){
		NSLog(@"event %i isn't a ready event!", event.s);
		return;
	}
	
	self.guildDictionary = [NSMutableDictionary new];
    self.channelDictionary = [NSMutableDictionary new];
    
    DCGuild* dmGuild = [[DCGuild alloc] initAsDMGuildFromJsonPrivateChannels:[event.d objectForKey:@"private_channels"]];
    [self.guildDictionary setObject:dmGuild forKey:dmGuild.snowflake];
    [self.channelDictionary addEntriesFromDictionary:dmGuild.channels];
    
	
	NSArray* jsonGuilds = [[NSArray alloc] initWithArray:[event.d objectForKey:@"guilds"]];
	
	for(NSDictionary* jsonGuild in jsonGuilds){
		DCGuild* guild = [[DCGuild alloc]initFromDictionary:jsonGuild];
		[self.guildDictionary setObject:guild forKey:guild.snowflake];
        
        if([guild.snowflake  isEqual: @"0"]) [self.channelDictionary addEntriesFromDictionary:guild.channels];
        else for(NSMutableArray* channels in [guild.channelsWithCategory allValues]) {
            for(DCChannel* channel in channels) {
                [self.channelDictionary setObject:channel forKey:channel.snowflake];
            }
        }
	}
    
#warning this can probably be simplified
    NSArray* readStates = [event.d objectForKey:@"read_state"];
    for(NSDictionary* readState in readStates){
        
        NSString* channelSnowflake = [readState objectForKey:@"id"];
        NSString* lastReadMessageSnowflake = [readState objectForKey:@"last_message_id"];
        
        DCChannel* channel = [self.channelDictionary objectForKey:channelSnowflake];
        
        if(channel.lastMessageReadOnLoginSnowflake)
            channel.isRead = [lastReadMessageSnowflake isEqual:channel.lastMessageReadOnLoginSnowflake];
        else
            channel.isRead = false;
    }
    
    self.guildKeys = [[NSMutableArray alloc] init];
    
    self.guildKeys[0] = dmGuild.snowflake;
    
    // TODO: support server folder
    NSArray* guildFolders = [[event.d objectForKey:@"user_settings" ] objectForKey:@"guild_folders"];
    NSMutableArray* guildKeys_converted = [self guildKeysFromGuildFolders:guildFolders];
    [self.guildKeys addObjectsFromArray:guildKeys_converted];
}

-(NSMutableArray*)guildKeysFromGuildFolders:(NSArray *)guildFolders{
    NSMutableArray* result = [[NSMutableArray alloc] init];
    for(NSDictionary* folder in guildFolders) {
        for(NSString* guildKey in [folder objectForKey:@"guild_ids"]) {
            [result addObject:guildKey];
        }
    }
    return result;
}

-(void)addGuild:(DCGuild *)guild{
    [self.guildDictionary setObject:guild forKey:guild.snowflake];
}



-(DCGuild*)guildAtIndex:(int)index{
    if(self.guildKeys.count - 1 < index) {
        return nil;
    }
    NSString* key = self.guildKeys[index];
	return [self.guildDictionary objectForKey:key];
}

-(DCGuild*)guildOfSnowflake:(NSString *)snowflake{
    return [self.guildDictionary objectForKey:snowflake];
}

-(DCChannel*)channelOfSnowflake:(NSString *)snowflake{
    return [self.channelDictionary objectForKey:snowflake];
}

-(int)count{
	return self.guildDictionary.count;
}

@end
