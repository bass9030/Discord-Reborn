//
//  NSBubbleData.m
//
//  Created by Alex Barinov
//  Project home page: http://alexbarinov.github.com/UIBubbleTableView/
//
//  This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License.
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/
//

#import "NSBubbleData.h"
#import "TTTAttributedLabel.h"
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@implementation NSBubbleData

#pragma mark - Properties

@synthesize date = _date;
@synthesize type = _type;
@synthesize view = _view;
@synthesize insets = _insets;
@synthesize avatar = _avatar;
@synthesize buttonSelector = _buttonSelector;

#pragma mark - Lifecycle

#if !__has_feature(objc_arc)
- (void)dealloc
{
    [_date release];
	_date = nil;
    [_view release];
    _view = nil;
    
    self.avatar = nil;

    [super dealloc];
}
#endif

#pragma mark - Text bubble

const UIEdgeInsets textInsetsMine = {5, 10, 11, 17};
const UIEdgeInsets textInsetsSomeone = {5, 15, 11, 10};

+ (id) dataWithText:(NSString *)text date:(NSDate *)date type:(NSBubbleType)type selector:(NSString *)selector
{
#if !__has_feature(objc_arc)
    return [[[NSBubbleData alloc] initWithText:text date:date type:type selector:selector] autorelease];
#else
    return [[NSBubbleData alloc] initWithText:text date:date type:type selector:selector];
#endif 
}

- (id)initWithText:(NSString *)text date:(NSDate *)date type:(NSBubbleType)type selector:(NSString *)selector
{
    UIFont *font = [UIFont systemFontOfSize:[UIFont systemFontSize]];

    // TTTAttributedLabel
    TTTAttributedLabel *label = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
    label.numberOfLines = 0;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    [label setFont:font];

    label.backgroundColor = [UIColor clearColor];
    
    NSDictionary *linkAttr = @{ NSForegroundColorAttributeName: [UIColor blueColor],
                                NSUnderlineStyleAttributeName: [NSNumber numberWithInt:1] };
    label.linkAttributes = linkAttr;
    label.activeLinkAttributes = linkAttr;
    label.inactiveLinkAttributes = linkAttr;
    
    label.userInteractionEnabled = YES;
    
    label.delegate = self;
    
    [label setText:text ? text : @""];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = nil;
        NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:&error];
        if (error == nil) {
            NSArray *matches = [detector matchesInString:label.text
                                                 options:0
                                                   range:NSMakeRange(0, [label.text length])];
            for (NSTextCheckingResult *match in matches) {
                NSRange matchRange = [match range];
                if ([match resultType] == NSTextCheckingTypeLink) {
                    NSURL *url = [match URL];
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        [label addLinkToURL:url withRange:matchRange];
                    });
                }
            }
        }
    });
    
    CGSize size = [TTTAttributedLabel sizeThatFitsAttributedString:[label attributedText] withConstraints:CGSizeMake(220, 9999) limitedToNumberOfLines:0];
    label.frame = CGRectMake(0, 0, size.width, size.height);
    
    
    // ==== UILabel ====
//    CGSize size = [(text ? text : @"") sizeWithFont:font constrainedToSize:CGSizeMake(220, 9999) lineBreakMode:NSLineBreakByCharWrapping];
//    
//    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
//    label.numberOfLines = 0;
//    label.lineBreakMode = NSLineBreakByWordWrapping;
//    [label setText:text ? text : @""];
//    [label setFont:font];
//    label.backgroundColor = [UIColor clearColor];
    
// ==== UITextView ====
//    CGSize fontSize = [(text ? text : @"") sizeWithFont:font constrainedToSize:CGSizeMake(220, 9999) lineBreakMode:NSLineBreakByWordWrapping];
//    
//    UITextView *label = [[UITextView alloc] init];
//    [label setText: (text ? text : @"")];
//
//    label.contentInset = UIEdgeInsetsMake(-8,-8,-8,-8);
//    label.scrollEnabled = NO;
//    label.dataDetectorTypes = UIDataDetectorTypeAll;
//    label.font = font;
//    label.editable = NO;
//    label.backgroundColor = [UIColor clearColor];
//    label.translatesAutoresizingMaskIntoConstraints = NO;
//    CGSize contentSize = [label sizeThatFits:CGSizeMake(fontSize.width + 16, CGFLOAT_MAX)];
//    label.frame = CGRectMake(0, 0, contentSize.width, contentSize.height - 16);
    
#if !__has_feature(objc_arc)
    [label autorelease];
#endif
    
    UIEdgeInsets insets = (type == BubbleTypeMine ? textInsetsMine : textInsetsSomeone);
    return [self initWithView:label date:date type:type insets:insets selector:selector];
}

- (void)attributedLabel:(TTTAttributedLabel*)label didSelectLinkWithURL:(NSURL *)url {
    NSLog(@"Touched %@", [url absoluteString]);
    [[UIApplication sharedApplication] openURL:url];
}

#pragma mark - Image bubble

const UIEdgeInsets imageInsetsMine = {11, 13, 16, 22};
const UIEdgeInsets imageInsetsSomeone = {11, 18, 16, 14};

+ (id)dataWithImage:(UIImage *)image date:(NSDate *)date type:(NSBubbleType)type
{
#if !__has_feature(objc_arc)
    return [[[NSBubbleData alloc] initWithImage:image date:date type:type] autorelease];
#else
    return [[NSBubbleData alloc] initWithImage:image date:date type:type];
#endif    
}

- (id)initWithImage:(UIImage *)image date:(NSDate *)date type:(NSBubbleType)type
{
    CGSize size = image.size;
    if (size.width > 220)
    {
        size.height /= (size.width / 220);
        size.width = 220;
    }
    
    UIButton * button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0, 0, size.width, size.height);
    button.tag = 1;
    [button setBackgroundImage:image forState:UIControlStateNormal];

    
#if !__has_feature(objc_arc)
    [button autorelease];
#endif
    
    UIEdgeInsets insets = (type == BubbleTypeMine ? imageInsetsMine : imageInsetsSomeone);
    return [self initWithView:button date:date type:type insets:insets selector:nil];
}

#pragma mark - Custom view bubble

+ (id)dataWithView:(UIView *)view date:(NSDate *)date type:(NSBubbleType)type insets:(UIEdgeInsets)insets selector:(NSString *)selector
{
#if !__has_feature(objc_arc)
    return [[[NSBubbleData alloc] initWithView:view date:date type:type insets:insets selector:selector] autorelease];
#else
    return [[NSBubbleData alloc] initWithView:view date:date type:type insets:insets selector:selector];
#endif    
}

- (id)initWithView:(UIView *)view date:(NSDate *)date type:(NSBubbleType)type insets:(UIEdgeInsets)insets selector:(NSString *)selector
{
    self = [super init];
    if (self)
    {
#if !__has_feature(objc_arc)
        _view = [view retain];
        _date = [date retain];
        if (selector) {
            _buttonSelector = [buttonSelector retain];
        }
#else
        _view = view;
        _date = date;
        if (selector) {
            _buttonSelector = selector;
        }
#endif
        _type = type;
        _insets = insets;
    }
    return self;
}

@end
