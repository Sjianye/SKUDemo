//
//  ViewController.m
//  SkuDemo
//
//  Created by HFL on 2017/1/17.
//  Copyright © 2017年 HFL. All rights reserved.
//

#import "ViewController.h"
#import "SpecWindowView.h"
#define SCREEN_HEIGHT   [UIScreen mainScreen].bounds.size.height //屏幕高度
#define SCREEN_WIDTH    [UIScreen mainScreen].bounds.size.width //屏幕宽度
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.view.backgroundColor  = [UIColor lightGrayColor];
    
    SpecWindowView * specView = [[NSBundle mainBundle]loadNibNamed:@"SpecWindowView" owner:nil options:nil].firstObject;
    specView.frame = CGRectMake(0, 200, SCREEN_WIDTH, SCREEN_HEIGHT-200);
    [self.view addSubview:specView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
