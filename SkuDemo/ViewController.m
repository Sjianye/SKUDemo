//
//  ViewController.m
//  SKUDemo
//
//  Created by 改车吧 on 2017/9/26.
//  Copyright © 2017年 SJianye. All rights reserved.
//

#import "ViewController.h"
#import "BottomPopViewSKU.h"
#define kScreenWidth ([UIScreen mainScreen].bounds.size.width)
#define kScreenHeight ([UIScreen mainScreen].bounds.size.height)

@interface ViewController ()

@property (nonatomic, strong)        BottomPopViewSKU       *popView;

@property (nonatomic, strong)        UIView             *maskView;        // 蒙版视图


@end

@implementation ViewController
#pragma mark - 底部弹出视图懒加载
- (UIView *)popView {
    if (!_popView) {
        CGFloat    popViewHeight = 420.f;
        
        _popView = [[[NSBundle mainBundle] loadNibNamed:@"BottomPopViewSKU" owner:self options:nil] lastObject];
        
        _popView.frame = CGRectMake(0, kScreenHeight+60, kScreenWidth, popViewHeight);
        _popView.backgroundColor = [UIColor whiteColor];
        //阴影
        _popView.layer.shadowColor = [UIColor blackColor].CGColor;
        _popView.layer.shadowOffset = CGSizeMake(0.5, 0.5);
        _popView.layer.shadowOpacity = 0.8;
        _popView.layer.shadowRadius = 5;
        __weak typeof(self) weakSelf = self;
        _popView.jyPopViewCloseClick = ^{
            [weakSelf closePop];
        };
        _popView.jyPopViewSureClick = ^(ProductModel *model){
            NSLog(@"确定按钮点击");
        };
    }
    return _popView;
}
#pragma mark -蒙版视图懒加载
- (UIView *)maskView {
    if (!_maskView) {
        _maskView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _maskView.backgroundColor = [UIColor colorWithWhite:0.000 alpha:0.400];
        _maskView.alpha = 0.0f;
        // 添加点击背景按钮
        UIButton *btn = [[UIButton alloc] initWithFrame:[UIScreen mainScreen].bounds];
        [btn addTarget:self action:@selector(closePop) forControlEvents:UIControlEventTouchUpInside];
        [_maskView addSubview:btn];
    }
    return _maskView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = [UIColor cyanColor];
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(100, 200, 100, 100)];
    [button setBackgroundColor:[UIColor lightGrayColor]];
    [button setTitle:@"show" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(buttonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}
//按钮点击事件
- (void)buttonClick{

    CGFloat popViewHeight = 480.f;
    
    [[[UIApplication sharedApplication].windows lastObject] addSubview:self.maskView];
    [[[UIApplication sharedApplication].windows lastObject] addSubview:self.popView];
        
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"111" ofType:@".txt"];
    NSString* content = [NSString stringWithContentsOfFile:path
                                                  encoding:NSUTF8StringEncoding
                                                     error:NULL];
    NSDictionary *dicFromJSON =
    [NSJSONSerialization JSONObjectWithData: [content dataUsingEncoding:NSUTF8StringEncoding]
                                    options: NSJSONReadingMutableContainers
                                      error: nil];
    
    
    //给popView赋模型
    [self.popView setResponseDic:dicFromJSON];

    //防止多次弹出
    if (self.maskView.alpha != 0) {
        return;
    }
    self.popView.userInteractionEnabled = NO;
    self.maskView.userInteractionEnabled = NO;
    
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.3 animations:^{
        weakSelf.view.layer.transform = [weakSelf firstStepTransform];
        weakSelf.maskView.alpha = 1.0;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3 animations:^{
            weakSelf.view.layer.transform = [weakSelf secondStepTransform];
            weakSelf.popView.transform = CGAffineTransformTranslate(weakSelf.popView.transform, 0, -popViewHeight);
        }];
        weakSelf.popView.userInteractionEnabled = YES;
        weakSelf.maskView.userInteractionEnabled = YES;
    }];
    
}
//关闭弹出视图
- (void)closePop {
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.3 animations:^{
        weakSelf.view.layer.transform = [weakSelf firstStepTransform];
        weakSelf.popView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3 animations:^{
            weakSelf.view.layer.transform = CATransform3DIdentity;
            weakSelf.maskView.alpha = 0.0;
        } completion:^(BOOL finished) {
            [weakSelf.maskView removeFromSuperview];
            [weakSelf.popView removeFromSuperview];
        }];
    }];
    
}

// 动画1
- (CATransform3D)firstStepTransform {
    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = 1.0 / -900.0;
    transform = CATransform3DScale(transform, 0.95, 0.95, 1.0);
    transform = CATransform3DRotate(transform, 15.0 * M_PI / 180.0, 1, 0, 0);
    transform = CATransform3DTranslate(transform, 0, 0, -30.0);
    return transform;
}

// 动画2
- (CATransform3D)secondStepTransform {
    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = [self firstStepTransform].m34;
    transform = CATransform3DTranslate(transform, 0, [UIScreen mainScreen].bounds.size.height * -0.08, 0);
    transform = CATransform3DScale(transform, 0.8, 0.8, 1.0);
    return transform;
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
