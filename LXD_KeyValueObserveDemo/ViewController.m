//
//  ViewController.m
//  LXD_KeyValueObserveDemo
//
//  Created by linxinda on 15/3/15.
//  Copyright (c) 2015年 Personal. All rights reserved.
//

#import "ViewController.h"
#import "NSObject+LXD_KVO.h"
#import "LXD_ObservedObject.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    LXD_ObservedObject * object = [LXD_ObservedObject new];
    [object LXD_addObserver: self forKey: @"observedNum" withBlock: ^(id observedObject, NSString *observedKey, id oldValue, id newValue) {
        
        NSLog(@"object:%@ observedKey:%@ Value had changed 1111 yet %@ > %@",observedObject,observedKey,oldValue,newValue);
    }];
    
//    [object LXD_addObserver: self forKey: @"observedNum" withBlock: ^(id observedObject, NSString *observedKey, id oldValue, id newValue) {
//        
//        NSLog(@"object:%@ observedKey:%@ Value had changed 2222 yet %@ > %@",observedObject,observedKey,oldValue,newValue);
//    }];
    
    object.observedNum = @10;
    object.observedNum = @11;
    
//    [object LXD_removeObserver:self forKey:@"observedNum"];
    
    object.observedNum = @12;
    
    [object LXD_addObserver: self forKey: @"bInt" withBlock: ^(id observedObject, NSString *observedKey, id oldValue, id newValue) {
        
        NSLog(@"object:%@ observedKey:%@ Value had changed yet %@ > %@",observedObject,observedKey,oldValue,newValue);
    }];
    object.bInt = 13;
    object.bInt = 14;
    
    [object LXD_addObserver: self forKey: @"cCGPoint" withBlock: ^(id observedObject, NSString *observedKey, id oldValue, id newValue) {
        
        NSLog(@"object:%@ observedKey:%@ Value had changed yet %@ > %@",observedObject,observedKey,oldValue,newValue);
    }];
    object.cCGPoint = CGPointMake(2, 2);
    object.cCGPoint = CGPointMake(3, 4);
    
//    [object observeKeyPath:@"observedInt" withBlock:^(id  _Nullable __weak self, id  _Nullable old, id  _Nullable newVal) {
//        NSLog(@"Value had changed yet  2222 %@ %@",old,newVal);
//    }];
//    
//    [object observeKeyPath:@"observedInt" withBlock:^(id  _Nullable __weak self, id  _Nullable old, id  _Nullable newVal) {
//        NSLog(@"Value had changed yet  1111 %@ %@",old,newVal);
//    }];
//    
//    object.observedInt = 33;
//
//    [object removeObserverFor:@"observedInt"];
//
//    object.observedInt = 44;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
