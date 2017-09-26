//
//  ProductCountCell.h
//  ToChangeTheCar
//
//  Created by 改车吧 on 2017/7/21.
//  Copyright © 2017年 gaicheba. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProductCountCell : UICollectionViewCell

@property (nonatomic,assign) NSInteger count;

@property (copy,nonatomic) void(^jyProductCountCallBack)(NSInteger count);

@end
