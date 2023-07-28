//
//  DCMessage.m
//  Disco
//
//  Created by Trevir on 3/1/19.
//  Copyright (c) 2019 Trevir. All rights reserved.
//

#import "DCMessage.h"
#import "RBClient.h"
#import "DCMessageAttachment.h"
#import "RBUserStore.h"
#import "RBGuildStore.h"
#import "DCUser.h"
#import "DCGuild.h"
#import "DCRole.h"
#import "DCChannel.h"

@implementation DCMessage
@synthesize snowflake = _snowflake;
@synthesize author = _author;
@synthesize member = _member;
@synthesize timestamp = _timestamp;
@synthesize writtenByUser = _writtenByUser;

- (DCMessage *)initFromDictionary:(NSDictionary *)dict {
	self = [super init];
    if(![dict objectForKey:@"channel_id"]){
		[NSException exceptionWithName:@"invalid dictionary"
                                reason:@"tried to initialize message from invalid dictionary!"
                              userInfo:dict];
	}
    
	self.snowflake = [dict objectForKey:@"id"];
    
    self.type = (NSInteger)[dict objectForKey:@"type"];
	
	self.author = [RBClient.sharedInstance.userStore getUserBySnowflake:[[dict objectForKey:@"author"] objectForKey:@"id"]];
    if(self.author == RBClient.sharedInstance.user){
        self.writtenByUser = true;
    }else if(!self.author) {
        self.author = [[DCUser alloc] initFromDictionary:[dict objectForKey:@"author"]];
        [RBClient.sharedInstance.userStore addUser:self.author];
    }
    self.content = [dict objectForKey:@"content"];
    
    self.parentGuild = [RBClient.sharedInstance.guildStore guildOfSnowflake:[dict objectForKey:@"guild_id"]];
    self.parentChannel = [RBClient.sharedInstance.guildStore channelOfSnowflake:[dict objectForKey:@"channel_id"]];
    
    NSError* error = nil;
    NSRegularExpression* userMention = [NSRegularExpression regularExpressionWithPattern:@"<@(!){0,1}[0-9]{17,20}>" options:0 error:&error];
    NSRegularExpression* roleMention = [NSRegularExpression regularExpressionWithPattern:@"<@&[0-9]{17,20}>" options:0 error:&error];
    NSRegularExpression* channelMention = [NSRegularExpression regularExpressionWithPattern:@"<#[0-9]{17,20}>" options:0 error:&error];
    NSRegularExpression* numberRegex= [NSRegularExpression regularExpressionWithPattern:@"[0-9]{17,20}" options:0 error:&error];
    NSArray* userMentionMatches = [userMention matchesInString:self.content options:0 range:NSMakeRange(0, [self.content length])];
    NSArray* roleMentionMatches = [roleMention matchesInString:self.content options:0 range:NSMakeRange(0, [self.content length])];
    NSArray* channelMentionMatches = [channelMention matchesInString:self.content options:0 range:NSMakeRange(0, [self.content length])];
    
    NSString* tmpContent = [NSString stringWithString:self.content];
    for ( NSTextCheckingResult* match in userMentionMatches )
    {
        NSString* matchText = [tmpContent substringWithRange:[match range]];
        NSTextCheckingResult* numberMatch = [[numberRegex matchesInString:matchText options:0 range:NSMakeRange(0, matchText.length)] objectAtIndex:0];
        NSString* snowflake = [matchText substringWithRange:[numberMatch range]];
        NSString* username = [[RBClient.sharedInstance.userStore getUserBySnowflake:snowflake] username];
        self.content = [self.content stringByReplacingOccurrencesOfString:matchText withString:[NSString stringWithFormat:@"@%@", username]];
        NSLog(@"user mention found: %@ | name: %@", snowflake, username);
    }
    
    for ( NSTextCheckingResult* match in roleMentionMatches )
    {
        NSString* matchText = [tmpContent substringWithRange:[match range]];
        NSTextCheckingResult* numberMatch = [[numberRegex matchesInString:matchText options:0 range:NSMakeRange(0, matchText.length)] objectAtIndex:0];
        NSString* snowflake = [matchText substringWithRange:[numberMatch range]];
        NSString* rolename = [[[self.parentGuild roles] objectForKey:snowflake] name];
        self.content = [self.content stringByReplacingOccurrencesOfString:matchText withString:[NSString stringWithFormat:@"@%@", rolename]];
        NSLog(@"role mention found: %@ | name: %@", snowflake, rolename);
    }
    
    for ( NSTextCheckingResult* match in channelMentionMatches )
    {
        NSString* matchText = [tmpContent substringWithRange:[match range]];
        NSTextCheckingResult* numberMatch = [[numberRegex matchesInString:matchText options:0 range:NSMakeRange(0, matchText.length)] objectAtIndex:0];
        NSString* snowflake = [matchText substringWithRange:[numberMatch range]];
        NSString* channelname = [[[self.parentGuild channels] objectForKey:snowflake] name];
        self.content = [self.content stringByReplacingOccurrencesOfString:matchText withString:[NSString stringWithFormat:@"#%@", channelname]];
        NSLog(@"channel mention found: %@ | name: %@", snowflake, channelname);
    }
    
    //FORMAT: 2020-01-03T15:46:52.158000+00:00
    
    NSDateFormatter *dateFormat = [NSDateFormatter new];
    dateFormat.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ";
    // Always use this locale when parsing fixed format date strings
    dateFormat.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    
    NSString *dateString = [dict objectForKey:@"timestamp"];
    self.timestamp = [dateFormat dateFromString:dateString];
    
    
    NSArray *jsonAttachments = (NSArray*)([dict objectForKey:@"attachments"]);
    self.attachments = [[NSMutableDictionary alloc] initWithCapacity:jsonAttachments.count];
    
    for(NSDictionary *jsonAttachment in jsonAttachments){
        DCMessageAttachment *messageAttachment = [[DCMessageAttachment alloc] initFromDictionary:jsonAttachment withParentMessage:self];
        [self.attachments setObject:messageAttachment forKey:messageAttachment.snowflake];
    }
	
	return self;
}

-(void)queueLoadAttachments{
    for(DCMessageAttachment *messageAttachment in [self.attachments allValues]){
        [messageAttachment queueLoadContent];
    }
}

@end
