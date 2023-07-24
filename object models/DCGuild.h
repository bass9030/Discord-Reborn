//
//  DCGuild.h
//  Disco
//
//  Created by Trevir on 3/1/19.
//  Copyright (c) 2019 Trevir. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "DCDiscordObject.h"
@class RBMessageItem;
@class DCGuildMember;
@class DCRole;

@interface DCGuild : NSObject <DCDiscordObject>

@property NSArray *permissions;
@property bool ownedByUser;

@property NSString *name;
@property NSString *iconHash;

@property DCRole* everyoneRole;
@property NSMutableDictionary *roles;
@property NSMutableDictionary *emoji;
@property NSMutableDictionary *members;
@property NSMutableDictionary *channels;
@property NSMutableDictionary *channelsWithCategory;
@property NSMutableDictionary *categorys;
@property NSArray *sortedChannels;

@property UIImage *iconImage;

@property DCGuildMember *userGuildMember;

@property bool isLarge;
@property bool isAvailable;
@property bool sendNotificationForEveryMessage;

-(DCGuild*)initFromDictionary:(NSDictionary*)dict;
-(DCGuild*)initAsDMGuildFromJsonPrivateChannels:(NSDictionary*)jsonPrivateChannels;

- (void)queueLoadIconImage;

@end
