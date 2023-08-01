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
    
//    NSLog(@"Received message from: %@", [dict objectForKey:@"guild_id"]);
    self.parentGuild = [RBClient.sharedInstance.guildStore guildOfSnowflake:[dict objectForKey:@"guild_id"]];
    self.parentChannel = [RBClient.sharedInstance.guildStore channelOfSnowflake:[dict objectForKey:@"channel_id"]];
//    NSLog([NSString stringWithFormat:@"guild_ID: %@", [dict objectForKey:@"guild_id"]]);
    if(self.parentGuild == nil) {
        self.parentGuild = self.parentChannel.parentGuild;
    }
    
    NSString* tmpContent = [NSString stringWithString:self.content];
    NSArray* mentions = [dict objectForKey:@"mentions"];
    NSRegularExpression* mentionRegex = [NSRegularExpression regularExpressionWithPattern:@"<@(!){0,1}[0-9]{17,20}>" options:NSRegularExpressionCaseInsensitive error:NULL];
    NSArray* mentionsMatches = [mentionRegex matchesInString:tmpContent options:0 range:NSMakeRange(0, [tmpContent length])];
    
    
    // user mentions
    for ( NSTextCheckingResult* match in mentionsMatches )
    {
        NSCharacterSet *charactersToRemove = [NSCharacterSet.alphanumericCharacterSet invertedSet];
        NSString *snowflake = [[[tmpContent substringWithRange:match.range] componentsSeparatedByCharactersInSet:charactersToRemove] componentsJoinedByString:@""];
        for(NSDictionary* mention in mentions) {
            if([[mention objectForKey:@"id"] isEqualToString:snowflake]) {
                NSString* username;
                if([mention objectForKey:@"member"]) {
                    username = [[mention objectForKey:@"member"] objectForKey:@"nick"];
                }else{
                    if([mention objectForKey:@"global_name"] != [NSNull null]) {
                        username = [mention objectForKey:@"global_name"];
                    }else{
                        username = [mention objectForKey:@"username"];
                    }
                }
                if(!username) {
                    username = @"UNKNOWN_USER";
                }
                
                NSString* matchText = [tmpContent substringWithRange:match.range];
                self.content = [self.content stringByReplacingOccurrencesOfString:matchText withString:[NSString stringWithFormat:@"@%@", username]];
                NSLog(@"user mention found: %@ | name: %@", snowflake, username);
                break;
            }
        }
    }
    
    // role mentions
    NSRegularExpression* roleRegex = [NSRegularExpression regularExpressionWithPattern:@"<@&[0-9]{17,20}>" options:NSRegularExpressionCaseInsensitive error:NULL];
    NSArray* roleMatches = [roleRegex matchesInString:self.content options:0 range:NSMakeRange(0, [self.content length])];
    tmpContent = self.content;
    for ( NSTextCheckingResult* match in roleMatches )
    {
        NSCharacterSet *charactersToRemove = [NSCharacterSet.alphanumericCharacterSet invertedSet];
        NSString *snowflake = [[[tmpContent substringWithRange:match.range] componentsSeparatedByCharactersInSet:charactersToRemove] componentsJoinedByString:@""];
        NSString* rolename = [[[self.parentGuild roles] objectForKey:snowflake] name];
        if(!rolename) {
            rolename = @"UNKNOWN_ROLE";
        }
        
        NSString* matchText = [tmpContent substringWithRange:match.range];
        self.content = [self.content stringByReplacingOccurrencesOfString:matchText withString:[NSString stringWithFormat:@"@%@", rolename]];
        NSLog(@"role mention found: %@ | name: %@", snowflake, rolename);
    }

    // channel mentions
    NSRegularExpression* channelRegex = [NSRegularExpression regularExpressionWithPattern:@"<#[0-9]{17,20}>" options:NSRegularExpressionCaseInsensitive error:NULL];
    NSArray* channelMatches = [channelRegex matchesInString:self.content options:0 range:NSMakeRange(0, [self.content length])];
    tmpContent = self.content;
    for ( NSTextCheckingResult* match in channelMatches )
    {
        NSCharacterSet *charactersToRemove = [NSCharacterSet.alphanumericCharacterSet invertedSet];
        NSString *snowflake = [[[tmpContent substringWithRange:match.range] componentsSeparatedByCharactersInSet:charactersToRemove] componentsJoinedByString:@""];
        NSString* channelname = [[[self.parentGuild channels] objectForKey:snowflake] name];
        if(!channelname) {
            channelname = @"UNKNOWN_CHANNEL";
        }
        
        NSString* matchText = [tmpContent substringWithRange:match.range];
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
