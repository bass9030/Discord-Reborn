//
//  DCGuild.m
//  Disco
//
//  Created by Trevir on 3/1/19.
//  Copyright (c) 2019 Trevir. All rights reserved.
//

#import "DCDiscordObject.h"
#import "DCGuildMember.h"
#import "DCGuild.h"
#import "DCChannel.h"
#import "DCMessage.h"
#import "DCRole.h"
#import "DCUser.h"
#import "RBNotificationEvent.h"
#import "UIKit/UIKit.h"

static NSOperationQueue* loadIconOperationQueue;

@implementation DCGuild
@synthesize snowflake = _snowflake;

-(DCGuild*)initFromDictionary:(NSDictionary *)dict{
	self = [super init];
    
    if(![dict objectForKey:@"region"]){
		[NSException exceptionWithName:@"invalid dictionary"
                                reason:@"tried to initialize guild from invalid dictionary!"
                              userInfo:dict];
	}
	
	self.snowflake = [dict objectForKey:@"id"];
	self.name = [dict objectForKey:@"name"];
    self.ownedByUser = [[dict objectForKey:@"owner"] boolValue];
    self.iconHash = [dict objectForKey:@"icon"];
    
    // Order in which objects must be initialized:
    // Roles, Guild members, and channels
	
    //Roles
    NSArray *jsonRoles = ((NSArray*)[dict objectForKey:@"roles"]);
    self.roles = [[NSMutableDictionary alloc]init];

    for(NSDictionary* jsonRole in jsonRoles){
        DCRole* role = [[DCRole alloc] initFromDictionary:jsonRole];
        [self.roles setObject:role forKey:role.snowflake];
    }
    
    self.everyoneRole = [self.roles objectForKey:self.snowflake];
    
    //Guild members
    NSArray *jsonMembers = ((NSArray*)[dict objectForKey:@"members"]);
//    if([self.snowflake isEqualToString:@"738201950218354708"]) {
//        NSLog(@"breakPoint!");
//    }
    self.members = [[NSMutableDictionary alloc] initWithCapacity:jsonMembers.count];
    for(NSDictionary *jsonMember in jsonMembers){
        DCGuildMember* member = [[DCGuildMember alloc]initFromDictionary:jsonMember inGuild:self];
        [self.members setObject:member forKey:member.user.snowflake];
    }
    
    [self.userGuildMember.roles setObject:self.everyoneRole forKey:self.everyoneRole.snowflake];
    
	//Channels
	NSArray *jsonChannels = ((NSArray*)[dict objectForKey:@"channels"]);

//	self.channels = [NSMutableDictionary new];
    self.categorys = [NSMutableDictionary new];
    self.channelsWithCategory = [NSMutableDictionary new];
    
    
    // handle channels without category
    DCChannel* noCategory = [DCChannel new];
    noCategory.sortingPosition = -999;
    noCategory.name = @"";
    noCategory.channelType = DCChannelTypeGuildCatagory;
    noCategory.snowflake = @"no cat";
    
	self.channels = [[NSMutableDictionary alloc] initWithCapacity:jsonChannels.count];
    [self.categorys setObject:noCategory forKey:noCategory.snowflake];
    [self.channelsWithCategory setObject:[NSMutableArray new] forKey:noCategory.snowflake];
	
    
    // add categorys
    for(NSDictionary *jsonChannel in jsonChannels){
		DCChannel *channel = [[DCChannel alloc] initFromDictionary:jsonChannel andGuild:self];
        if(channel.channelType == DCChannelTypeGuildCatagory) {
            [self.categorys setObject:channel forKey:channel.snowflake];
            [self.channelsWithCategory setObject:[NSMutableArray new] forKey:channel.snowflake];
        }else continue;
	}
    
    
    // add channels
    for(NSDictionary* jsonChannel in jsonChannels) {
        DCChannel *channel = [[DCChannel alloc] initFromDictionary:jsonChannel andGuild:self];
        if(channel.channelType != DCChannelTypeGuildCatagory) {
            [self.channels setObject:channel forKey:channel.snowflake];
            [(NSMutableArray*)[self.channelsWithCategory objectForKey:channel.parentCatagorySnowflake] addObject:channel];
        }else continue;
    }
    
    // category sorting
    self.sortedCategorys = [[self.channelsWithCategory allKeys] sortedArrayUsingComparator:^(NSString* s1, NSString* s2) {
        DCChannel* c1 = [self.categorys objectForKey:s1];
        DCChannel* c2 = [self.categorys objectForKey:s2];
        
        if (c1.sortingPosition > c2.sortingPosition) {
            return (NSComparisonResult)NSOrderedDescending;
        }
        
        if (c1.sortingPosition < c2.sortingPosition) {
            return (NSComparisonResult)NSOrderedAscending;
        }
        return (NSComparisonResult)NSOrderedSame;
    }];
    
    // channel sorting
    for(NSString* key in self.sortedCategorys) {
        NSArray* channels = [NSArray arrayWithArray:[self.channelsWithCategory objectForKey:key]];
        NSArray* sortedChannels = [channels sortedArrayUsingComparator:^(DCChannel* c1, DCChannel* c2) {
            if (c1.sortingPosition > c2.sortingPosition) {
                return (NSComparisonResult)NSOrderedDescending;
            }
            
            if (c1.sortingPosition < c2.sortingPosition) {
                return (NSComparisonResult)NSOrderedAscending;
            }
            return (NSComparisonResult)NSOrderedSame;
        }];
        [self.channelsWithCategory removeObjectForKey:key];
        [self.channelsWithCategory setObject:sortedChannels forKey:key];
    }
	
	return self;
}

-(DCGuild*)initAsDMGuildFromJsonPrivateChannels:(NSDictionary *)jsonPrivateChannels{
	self = [super init];
    
	self.name = @"DM Channel";
    self.snowflake = @"0";
    self.iconImage = [UIImage imageNamed:@"DMs"];
    
    // Order in which objects must be initialized:
    // Roles, Guild members, and channels
    
	//Channels
	self.channels = [[NSMutableDictionary alloc] initWithCapacity:jsonPrivateChannels.count];
	for(NSDictionary *jsonChannel in jsonPrivateChannels){
		DCChannel *channel = [[DCChannel alloc] initFromDictionary:jsonChannel andGuild:self];
        if(channel.channelType == DCChannelTypeDirectMessage || channel.channelType == DCChannelTypeGroupMessage)
            [self.channels setObject:channel forKey:channel.snowflake];
	}
    
    self.sortedChannels = [[self.channels allValues] sortedArrayUsingComparator:^(DCChannel* c1, DCChannel* c2) {
        if([c1.lastMessageReadOnLoginSnowflake isEqual:[NSNull null]] || [c2.lastMessageReadOnLoginSnowflake isEqual:[NSNull null]]) {
            if([c1.lastMessageReadOnLoginSnowflake isEqual:[NSNull null]] && ![c2.lastMessageReadOnLoginSnowflake isEqual:[NSNull null]]) {
                return (NSComparisonResult)NSOrderedDescending;
            }else if(![c1.lastMessageReadOnLoginSnowflake isEqual:[NSNull null]] && [c2.lastMessageReadOnLoginSnowflake isEqual:[NSNull null]]) {
                return (NSComparisonResult)NSOrderedAscending;
            }else{
                return (NSComparisonResult)NSOrderedSame;
            }
        }
        uint64_t c1LastMessage = [self snowflakeToDate:c1.lastMessageReadOnLoginSnowflake];
        uint64_t c2LastMessage = [self snowflakeToDate:c2.lastMessageReadOnLoginSnowflake];
        if (c2LastMessage > c1LastMessage) {
            return (NSComparisonResult)NSOrderedDescending;
        }
        
        if (c2LastMessage < c1LastMessage) {
            return (NSComparisonResult)NSOrderedAscending;
        }
        return (NSComparisonResult)NSOrderedSame;
    }];
	
	return self;
}

- (uint64_t)snowflakeToDate:(NSString *)snowflake {
    // Convert snowflake string to unsigned 64-bit integer
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    NSNumber *snowflakeNumber = [numberFormatter numberFromString:snowflake];
    uint64_t snowflakeValue = [snowflakeNumber unsignedLongLongValue];
    
    // Extract date bits from the snowflake
    uint64_t dateBits = snowflakeValue >> 22;
    
    // Calculate the timestamp (milliseconds since the Discord epoch)
    uint64_t timestamp = dateBits + 1420070400000;
    
    return timestamp;
}

- (void)queueLoadIconImage {
    
    if(self.iconImage) return;
    
    self.iconImage = [UIImage new];
    
    if(!self.iconHash || [self.iconHash isEqual:[NSNull null]]){
        self.iconImage = [UIImage imageNamed:@"no icon"];
        return;
    }
    
    if(!loadIconOperationQueue){
        loadIconOperationQueue = [[NSOperationQueue alloc] init];
        loadIconOperationQueue.maxConcurrentOperationCount = 1;
    }
    
    
    NSBlockOperation *loadIconOperation = [NSBlockOperation new];
    
    __weak __typeof__(NSBlockOperation) *weakOp = loadIconOperation;
    
    [loadIconOperation addExecutionBlock:^{
        
        if(weakOp.isCancelled) return;
        
        NSString *imgURLstr = [NSString stringWithFormat:@"https://cdn.discordapp.com/icons/%@/%@.png", self.snowflake, self.iconHash];
        NSURL* imgURL = [NSURL URLWithString:imgURLstr];
        
        NSData *data = [NSData dataWithContentsOfURL:imgURL];
        
        NSLog(@"loaded guild icon for %@", self.name);
        
        self.iconImage = [UIImage imageWithData:data];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:RBNotificationEventLoadedGuildIcon object:nil];
        });
    }];
    
    [loadIconOperationQueue addOperation:loadIconOperation];
}

@end
