//
//  LXD_ObservedObject.h
//  LXD_KeyValueObserveDemo
//
//  Created by linxinda on 15/3/16.
//  Copyright (c) 2015年 Personal. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LXD_ObservedObject : NSObject

@property (strong, nonatomic) NSNumber *observedNum;
@property (weak) NSNumber *observedNumWeak;
@property (copy, nonatomic) NSDictionary *observedDic;
@property (copy, nonatomic) NSArray *observedArray;

@property (assign, nonatomic) char bChar;
@property (assign, nonatomic) unsigned char bUChar;
@property (assign, nonatomic) short bShort;
@property (assign, nonatomic) unsigned short bUShort;
@property (assign, nonatomic) int bInt;
@property (assign, nonatomic) unsigned int bUInt;
@property (assign, nonatomic) long bLong;
@property (assign, nonatomic) unsigned long bULong;
@property (assign, nonatomic) long long bLongLong;
@property (assign, nonatomic) unsigned long long bULongLong;
@property (assign, nonatomic) NSInteger bInteger;
@property (assign, nonatomic) NSUInteger bUInteger;
@property (assign, nonatomic) CGFloat bCGFloat;
@property (assign, nonatomic) float bFloat;
@property (assign, nonatomic) double bDouble;
@property (assign, nonatomic) BOOL bBOOL;

@property (assign, nonatomic) NSTextAlignment textAlignment;

@property (assign, nonatomic) CGPoint cCGPoint;
@property (assign, nonatomic) CGRect cCGRect;

@property (assign, nonatomic) CGVector cCGVector;
@property (assign, nonatomic) CGSize cCGSize;
@property (assign, nonatomic) CGAffineTransform cCGAffineTransform;
@property (assign, nonatomic) UIEdgeInsets cUIEdgeInsets;
@property (assign, nonatomic) UIOffset cUIOffset;
@property (assign, nonatomic) NSRange cNSRange;
@property (assign, nonatomic) CATransform3D cCATransform3D;

@end
