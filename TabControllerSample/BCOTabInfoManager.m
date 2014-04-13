//
//  BCOTabInfoManager.m
//  TabControllerSample
//
//  Created by 阿部耕平 on 2014/04/13.
//  Copyright (c) 2014年 Kohei Abe. All rights reserved.
//

#import "BCOTabInfoManager.h"

@interface BCOTabInfo : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, strong) UIColor *backgroundColor;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong) UIColor *highlightedBackgroundColor;
@property (nonatomic, strong) UIColor *highlightedTextColor;
@end

@implementation BCOTabInfo

+ (BCOTabInfo *)tabInfoWithDictionary:(NSDictionary *)dictionary
{
    // TODO: 型チェックもしたほうがよいかも
    
    BCOTabInfo *tabInfo = [[BCOTabInfo alloc] init];
    
    if ([[dictionary allKeys] containsObject:@"title"]) {
        tabInfo.title = dictionary[@"title"];
    }
    
    if ([[dictionary allKeys] containsObject:@"identifier"]) {
        tabInfo.identifier = dictionary[@"identifier"];
    }
    
    if ([[dictionary allKeys] containsObject:@"backgroundColor"]) {
        NSArray *backgroundColorArray = dictionary[@"backgroundColor"];
        tabInfo.backgroundColor = [UIColor colorWithRed:[backgroundColorArray[0] floatValue]
                                                  green:[backgroundColorArray[1] floatValue]
                                                   blue:[backgroundColorArray[2] floatValue]
                                                  alpha:1.0];
    }
    
    if ([[dictionary allKeys] containsObject:@"textColor"]) {
        NSArray *textColorArray = dictionary[@"textColor"];
        tabInfo.textColor = [UIColor colorWithRed:[textColorArray[0] floatValue]
                                            green:[textColorArray[1] floatValue]
                                             blue:[textColorArray[2] floatValue]
                                            alpha:1.0];
    }
    
    if ([[dictionary allKeys] containsObject:@"highlightedBackgroundColor"]) {
        NSArray *hBackgroundColorArray = dictionary[@"highlightedBackgroundColor"];
        tabInfo.highlightedBackgroundColor = [UIColor colorWithRed:[hBackgroundColorArray[0] floatValue]
                                                             green:[hBackgroundColorArray[1] floatValue]
                                                              blue:[hBackgroundColorArray[2] floatValue]
                                                             alpha:1.0];
    }
    
    if ([[dictionary allKeys] containsObject:@"highlightedTextColor"]) {
        NSArray *hTextColorArray = dictionary[@"highlightedTextColor"];
        tabInfo.highlightedTextColor = [UIColor colorWithRed:[hTextColorArray[0] floatValue]
                                                       green:[hTextColorArray[1] floatValue]
                                                        blue:[hTextColorArray[2] floatValue]
                                                       alpha:1.0];
    }
    
    return tabInfo;
}

@end

//=====================================

NSString * const kBCOTabInfoManagerAllTabInfoFileName      = @"allTabInfo.plist";

@interface BCOTabInfoManager ()

@property (nonatomic, strong) NSArray *allTabInfo;

@end

@implementation BCOTabInfoManager

+ (BCOTabInfoManager *)sharedManager
{
    static BCOTabInfoManager *tabInfoManager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        tabInfoManager = [[BCOTabInfoManager alloc] init];
        [tabInfoManager p_readExternalData];
    });
    
    return tabInfoManager;
}

- (NSArray *)allTitles
{
    NSMutableArray *titlesBuf = @[].mutableCopy;
    for (int i = 0; i < [_allTabInfo count]; i++) {
        NSString *title = [self titleAtIndex:i];
        [titlesBuf addObject:title];
    }
    return [titlesBuf copy];
}

- (NSString *)titleAtIndex:(NSUInteger)index
{
    if (!_allTabInfo) {
        return nil;
    }
    
    BCOTabInfo *tabInfo = nil;
    if ([_allTabInfo count] > index) {
        tabInfo = _allTabInfo[index];
    }
    
    return tabInfo.title;
}

- (NSArray *)allColors
{
    NSMutableArray *colorsBuf = @[].mutableCopy;
    for (int i = 0; i < [_allTabInfo count]; i++) {
        BCOTabColor *color = [self colorAtIndex:i];
        [colorsBuf addObject:color];
    }
    return [colorsBuf copy];
}

- (BCOTabColor *)colorAtIndex:(NSUInteger)index
{
    if (!_allTabInfo) {
        return nil;
    }
    
    BCOTabInfo *tabInfo = nil;
    if ([_allTabInfo count] > index) {
        tabInfo = _allTabInfo[index];
    }
    
    return [BCOTabColor tabColorWithBackgroundColor:tabInfo.backgroundColor
                                          textColor:tabInfo.textColor
                         highlightedBackgroundColor:tabInfo.highlightedBackgroundColor
                               highlightedTextColor:tabInfo.highlightedTextColor];
    
}

#pragma mark - private

- (void)p_readExternalData
{
    NSString *allInfoPath = [[NSBundle mainBundle] pathForResource:kBCOTabInfoManagerAllTabInfoFileName
                                                            ofType:nil];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:allInfoPath]) {
        NSArray *allInfo = [NSArray arrayWithContentsOfFile:allInfoPath];
        
        NSMutableArray *allTabInfoBuf = @[].mutableCopy;
        for (NSDictionary *info in allInfo) {
            BCOTabInfo *tabInfo = [BCOTabInfo tabInfoWithDictionary:info];
            [allTabInfoBuf addObject:tabInfo];
        }
        self.allTabInfo = [allTabInfoBuf copy];
    }
}

@end
