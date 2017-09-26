//
//  BottomPopView.h
//  ToChangeTheCar
//
//  Created by 改车吧 on 16/11/4.
//  Copyright © 2016年 gaicheba. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ProductModel;
@interface BottomPopViewSKU : UIView


/*
 * 商品详情页修改商品数量
 */
@property (strong,nonatomic)ProductModel *productModel;




/*
 * 关闭按钮回调
 */
@property (copy,nonatomic) void(^jyPopViewCloseClick)();
/*
 * 确定按钮回调
 */
@property (copy,nonatomic) void(^jyPopViewSureClick)(ProductModel *mdoel);


- (void)setResponseDic:(NSDictionary *)dic;

@end
