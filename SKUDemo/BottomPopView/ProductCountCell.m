//
//  ProductCountCell.m
//  ToChangeTheCar
//
//  Created by 改车吧 on 2017/7/21.
//  Copyright © 2017年 gaicheba. All rights reserved.
//

#import "ProductCountCell.h"
@interface ProductCountCell ()
@property (weak, nonatomic) IBOutlet UILabel *countLabel;
@end
@implementation ProductCountCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    _count = 1;
}

- (void)setCount:(NSInteger)count{
    _count = count;
    _countLabel.text = [NSString stringWithFormat:@"%ld",count];
}

- (IBAction)addBtnClick:(UIButton *)sender {
    _count ++;
    _countLabel.text = [NSString stringWithFormat:@"%ld",_count];
    if (_jyProductCountCallBack) {
        _jyProductCountCallBack(_count);
    }
}
- (IBAction)subBtnClick:(UIButton *)sender {
    if (_count == 1) {
        return;
    }
    _count --;
    _countLabel.text = [NSString stringWithFormat:@"%ld",_count];
    if (_jyProductCountCallBack) {
        _jyProductCountCallBack(_count);
    }
}

@end
