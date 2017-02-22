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
        
        NSLog(@"Value had changed yet  1111 %@ %@",oldValue,newValue);
    }];
    
    [object LXD_addObserver: self forKey: @"observedNum" withBlock: ^(id observedObject, NSString *observedKey, id oldValue, id newValue) {
        
        NSLog(@"Value had changed yet  2222 %@ %@",oldValue,newValue);
    }];
    
    object.observedNum = @10;
    
    [object LXD_removeObserver:self forKey:@"observedNum"];
    
    object.observedNum = @11;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
