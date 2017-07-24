//
//  SpecWindowView.m
//  HuanHuan
//
//  Created by HFL on 2016/12/7.
//  Copyright © 2016年 HFL. All rights reserved.
//
#import "SpecWindowView.h"
#import "UICollectionViewLeftAlignedLayout.h"

#import "SpecHeadView.h"
#import "SpecLabelCell.h"

#define kSpecHeadView   @"SpecHeadView"
#define kSpecLabelCell  @"SpecLabelCell"

#define NSString(type,obj)   [NSString stringWithFormat:(type),(obj)]//强转字符串
#define SCREEN_HEIGHT   [UIScreen mainScreen].bounds.size.height //屏幕高度
#define SCREEN_WIDTH    [UIScreen mainScreen].bounds.size.width //屏幕宽度

@implementation SpecWindowView

- (void)awakeFromNib
{
    NSString * path = [[NSBundle mainBundle]pathForResource:@"testJson" ofType:@"txt"];
    NSString * string = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    NSData * data = [string dataUsingEncoding:NSUTF8StringEncoding];
    id obj = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    NSDictionary * SkuDate = obj[@"Result"][@"SkuDate"];
    NSMutableArray * array = [[NSMutableArray alloc]init];
    NSArray * allKeys = [SkuDate allKeys];
    for (int i = 0;i < allKeys.count;i++) {
        NSString * key = allKeys[i];
        NSDictionary * dic = [SkuDate objectForKey:key];
        NSDictionary * skuDic = @{key:dic};
        [array addObject:skuDic];
    }
    
    [self createDataSource:array];
    [self reloadWindow:obj];
    [self.collectionView registerNib:[UINib nibWithNibName:kSpecLabelCell bundle:nil] forCellWithReuseIdentifier:kSpecLabelCell];
    [self.collectionView registerNib:[UINib nibWithNibName:kSpecHeadView bundle:nil] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:kSpecHeadView];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    UICollectionViewLeftAlignedLayout * flowLayout = [[UICollectionViewLeftAlignedLayout alloc]init];
    flowLayout.minimumInteritemSpacing = 15;
    flowLayout.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10);
    [self.collectionView setCollectionViewLayout:flowLayout];
    self.goodsPrice.adjustsFontSizeToFitWidth = YES;
    self.currentTitle = @"(null)";
    
}


///接收通知处理数据
- (void)reloadWindow:(NSDictionary *)object
{
    NSDictionary * result = object;
    NSArray * skuResult = self.SKUResult;
    [self.skuResult removeAllObjects];
    [self.seletedEnable removeAllObjects];
    [self.noSelectedHead removeAllObjects];
    [self.seletedIdArray removeAllObjects];
    [self.seletedIndexPaths removeAllObjects];
    [self.skuResult addObjectsFromArray:skuResult];
    
    ///取出SKUResult中所有可能的排列组合方式(keysArray)
    NSMutableArray * keysArray = [[NSMutableArray alloc]init];
    for (NSDictionary * dict in self.skuResult) {
        NSString * key = [[dict allKeys] firstObject];
        [keysArray addObject:key];
    }
    
    NSDictionary * dic = result[@"Result"];
    self.goodsName.text = NSString(@"%@", dic[@"name"]);
    self.goodsId = NSString(@"%@", dic[@"MinId"]);
    [self.dataSource removeAllObjects];
    NSArray * array = dic[@"SiftKey"];
    
    if ([array isKindOfClass:[NSNull class]]) {
        return;
    }
    
    
    NSString * price;
    NSMutableArray * allPrice = [[NSMutableArray alloc]init];
    for (NSDictionary * dic in self.skuResult) {
        NSString * skey = [[dic allKeys] firstObject];
        NSDictionary * dict = dic[skey];
        NSArray * prices = dict[@"prices"];
        [allPrice addObjectsFromArray:prices];
    }
    NSArray * rePrices = [self change:allPrice];
    NSString * minPrice = [rePrices firstObject];
    NSString * maxPrice = [rePrices lastObject];
    if ([maxPrice isEqualToString:minPrice]) {
        price = [NSString stringWithFormat:@"￥%@",minPrice];
    }
    else
    {
        price = [NSString stringWithFormat:@"￥%@~￥%@",minPrice,maxPrice];
    }

    self.goodsPrice.text = price;
    self.goodsprice = price;

    
    int i = 0;
    for (NSDictionary * dic in array) {
        NSArray *  StandardInfoList = dic[@"StandardInfoList"];
        NSString * StandardListName = NSString(@"%@", dic[@"StandardListName"]);
        int x = -1;
        NSString * attrValueId = @"";
        for (int j = 0; j < StandardInfoList.count; j++) {
            NSDictionary * dict = StandardInfoList[j];
            NSString * isSelected = NSString(@"%@", dict[@"IsSelect"]);
            NSString * AttrValueId = NSString(@"%@", dict[@"AttrValueId"]);
            if ([StandardListName isEqualToString:@"成色"]) {
                NSString * AttrvalueTitle = NSString(@"%@", dict[@"AttrvalueTitle"]);
                [self.alertInfo addObject:AttrvalueTitle];
            }
            
            //不可选
//            if (![keysArray containsObject:AttrValueId]) {
//                NSIndexPath * indexpath = [NSIndexPath indexPathForItem:j inSection:i];
//                [self.seletedEnable addObject:indexpath];
//            }
           
            
            if ([isSelected isEqualToString:@"1"]) {
                x = j;
                attrValueId = AttrValueId;
                break;
            }
        }
        //如果没有选中的
        if (x == -1) {
            [self.seletedIndexPaths addObject:@"0"];
            [self.seletedIdArray addObject:@""];
        }
        else
        {
            NSIndexPath * indexPath = [NSIndexPath indexPathForItem:x inSection:i];
            [self.seletedIndexPaths addObject:indexPath];
            [self.seletedIdArray addObject:attrValueId];
        }
        
        [self.dataSource addObject:dic];
        i++;
    }
    
    [self.seletedEnable removeAllObjects];
    
    for (int i = 0; i < self.dataSource.count; i++) {
        NSDictionary * subDic = self.dataSource[i];
        NSArray *subArray = subDic[@"StandardInfoList"];
        for (int j = 0; j < subArray.count; j++) {
            NSDictionary * reSubDic = subArray[j];
            NSIndexPath * currentIndexPath = [NSIndexPath indexPathForItem:j inSection:i];
            NSString * currentId = NSString(@"%@", reSubDic[@"AttrValueId"]);
            NSMutableArray * tempArray = [[NSMutableArray alloc]initWithArray:self.seletedIdArray];
            
            [tempArray removeObjectAtIndex:i];
            [tempArray insertObject:currentId atIndex:i];
            NSMutableArray * resultArray = [[NSMutableArray alloc]init];
            for (NSString * str in tempArray) {
                if (![str isEqualToString:@""]) {
                    [resultArray addObject:str];
                }
            }
            NSArray * changeArray = [self change:resultArray];
            NSString * resultKey = [changeArray componentsJoinedByString:@";"];
            if (![keysArray containsObject:resultKey]) {
                [self.seletedEnable addObject:currentIndexPath];
            }
            
            
        }
        
    }

    
    [self.collectionView reloadData];
}


///取出对应商品id
- (NSArray *)getGoodsId
{
    NSMutableArray * resultArray = [[NSMutableArray alloc]init];
    for (NSString * str in self.seletedIdArray) {
        if (![str isEqualToString:@""]) {
            [resultArray addObject:str];
        }
    }
    NSArray * skeyArray =  [self change:resultArray];
    
    NSString * key = [skeyArray componentsJoinedByString:@";"];
    
    
    //#移动4G 国行 iphone 6sp 金色  128G 未激活  2676
    NSArray * goodsIds;
    for (NSDictionary * dic in self.skuResult) {
        NSString * skey = [[dic allKeys] firstObject];
        if ([key isEqualToString:skey]) {
            NSDictionary * dict = dic[key];
            NSArray * productIds = dict[@"productIds"];
            goodsIds = productIds;
        }
    }
    return goodsIds;
    
}

#pragma mark - Button点击事件
- (IBAction)cancelSlectedAction:(id)sender {
    
    if (self.CallBackWithCloseWindow) {
        self.CallBackWithCloseWindow(@"0",self.goodsId);
    }
    
}
- (IBAction)submitAction:(id)sender {
    int i = 0;
    [self.noSelectedHead removeAllObjects];
    for (id obj in self.seletedIndexPaths) {
        if ([obj isKindOfClass:[NSString class]]) {
            NSIndexPath * indexPath = [NSIndexPath indexPathForItem:0 inSection:i];
            [self.noSelectedHead addObject:indexPath];
        }
        i++;
    }
    
    
    BOOL isAllSelected = self.noSelectedHead.count == 0 ? YES : NO;
    
    //如果还有未选的
    if (!isAllSelected) {
        [self.collectionView reloadData];
        return;
    }
    NSArray * goodsIds = [self getGoodsId];
    NSString * goodsId = [goodsIds firstObject];
    if (self.CallBackWithCloseWindow) {
        self.CallBackWithCloseWindow(@"1",goodsId);
    }
}
- (IBAction)buyAction:(id)sender {
    int i = 0;
    [self.noSelectedHead removeAllObjects];
    for (id obj in self.seletedIndexPaths) {
        if ([obj isKindOfClass:[NSString class]]) {
            NSIndexPath * indexPath = [NSIndexPath indexPathForItem:0 inSection:i];
            [self.noSelectedHead addObject:indexPath];
        }
        i++;
    }
    
    
    BOOL isAllSelected = self.noSelectedHead.count == 0 ? YES : NO;
    
    //如果还有未选的
    if (!isAllSelected) {
        [self.collectionView reloadData];
        return;
    }
    NSArray * goodsIds = [self getGoodsId];
    NSString * goodsId = [goodsIds firstObject];
    if (self.CallBackWithCloseWindow) {
        self.CallBackWithCloseWindow(@"2",goodsId);
    }

}


#pragma mark - UICollectionViewDataSource - UICollectionViewDelegate - UICollectionViewDelegateFlowLayout
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return self.dataSource.count;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSDictionary * dic = self.dataSource[section];
    NSArray * array = dic[@"StandardInfoList"];
    return array.count;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    SpecLabelCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:kSpecLabelCell forIndexPath:indexPath];
    NSDictionary * dic = self.dataSource[indexPath.section];
    NSArray * array = dic[@"StandardInfoList"];
    NSDictionary * dict = array[indexPath.item];
    cell.nameLabel.text = NSString(@"%@", dict[@"StandardName"]);
    cell.layer.cornerRadius = 5;
    cell.layer.masksToBounds = YES;
    
    
    ///不可选
    if ([self.seletedEnable containsObject:indexPath]) {
        cell.nameLabel.textColor = [UIColor lightGrayColor];
        cell.backImage.image = [[UIImage imageNamed:@"btn_isdeable_n"] imageWithAlignmentRectInsets:UIEdgeInsetsMake(4, 4, 4, 4)];
        cell.userInteractionEnabled = NO;
    }
    //可选
    else
    {
        cell.nameLabel.textColor = [UIColor darkGrayColor];
        cell.backImage.image = [[UIImage imageNamed:@"btn_selected_n"] imageWithAlignmentRectInsets:UIEdgeInsetsMake(4, 4, 4, 4)];
        cell.userInteractionEnabled = YES;
    }
    
    //选中
    if ([self.seletedIndexPaths containsObject:indexPath]) {
        cell.nameLabel.textColor = [UIColor whiteColor];
        cell.backImage.image = [[UIImage imageNamed:@"btn_selected_s"] imageWithAlignmentRectInsets:UIEdgeInsetsMake(4, 4, 4, 4)];
        cell.userInteractionEnabled = YES;
    }
    
    
    
    return cell;
}
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary * dic = self.dataSource[indexPath.section];
    NSArray * array = dic[@"StandardInfoList"];
    NSDictionary * dict = array[indexPath.item];
    NSString * string = NSString(@"%@", dict[@"StandardName"]);
    CGFloat width = (string.length + 2) * 14;
    return CGSizeMake(width, 25);
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    SpecHeadView * headView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:kSpecHeadView forIndexPath:indexPath];
    NSDictionary * dic = self.dataSource[indexPath.section];
    headView.nameLabel.text = NSString(@"%@", dic[@"StandardListName"]);
    
    if ([self.noSelectedHead containsObject:indexPath]) {
        headView.alertLabel.hidden = NO;
    }
    else
    {
        headView.alertLabel.hidden = YES;
    }
    
    if ([NSString(@"%@", dic[@"StandardListName"]) isEqualToString:@"成色"]) {
        if (![self.currentTitle isEqualToString:@"(null)"]) {
            headView.specInfo.text = NSString(@"*%@", self.currentTitle);
            headView.specInfo.hidden = NO;
            headView.alertLabel.hidden = YES;
        }
        else
        {
            headView.specInfo.hidden = YES;
        }
    }
    else
    {
        headView.specInfo.hidden = YES;
    }
    
   
    return headView;
}
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    return CGSizeMake(SCREEN_WIDTH, 30);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    ///取出SKUResult中所有可能的排列组合方式(keysArray)
    NSMutableArray * keysArray = [[NSMutableArray alloc]init];
    for (NSDictionary * dict in self.skuResult) {
        NSString * key = [[dict allKeys] firstObject];
        [keysArray addObject:key];
    }
    
    NSDictionary * dic = self.dataSource[indexPath.section];
   
    
    NSArray * array = dic[@"StandardInfoList"];
    NSDictionary * dict = array[indexPath.item];
    NSString * AttrValueId = NSString(@"%@", dict[@"AttrValueId"]);
    
    //取出所有选中状态的按钮标题
    //如果已经被选中则取消选中
    if ([self.seletedIndexPaths containsObject:indexPath]) {
        [self.seletedIndexPaths removeObjectAtIndex:indexPath.section];
        [self.seletedIndexPaths insertObject:@"0" atIndex:indexPath.section];
        [self.seletedIdArray removeObjectAtIndex:indexPath.section];
        [self.seletedIdArray insertObject:@"" atIndex:indexPath.section];
    }
    else
    {
        [self.seletedIndexPaths removeObjectAtIndex:indexPath.section];
        [self.seletedIndexPaths insertObject:indexPath atIndex:indexPath.section];
        [self.seletedIdArray removeObjectAtIndex:indexPath.section];
        [self.seletedIdArray insertObject:AttrValueId atIndex:indexPath.section];
    }
    
    [self.seletedEnable removeAllObjects];
    
    for (int i = 0; i < self.dataSource.count; i++) {
        NSDictionary * subDic = self.dataSource[i];
        NSArray *subArray = subDic[@"StandardInfoList"];
        for (int j = 0; j < subArray.count; j++) {
            NSDictionary * reSubDic = subArray[j];
            NSIndexPath * currentIndexPath = [NSIndexPath indexPathForItem:j inSection:i];
            NSString * currentId = NSString(@"%@", reSubDic[@"AttrValueId"]);
            NSMutableArray * tempArray = [[NSMutableArray alloc]initWithArray:self.seletedIdArray];
            
            [tempArray removeObjectAtIndex:i];
            [tempArray insertObject:currentId atIndex:i];
            NSMutableArray * resultArray = [[NSMutableArray alloc]init];
            for (NSString * str in tempArray) {
                if (![str isEqualToString:@""]) {
                    [resultArray addObject:str];
                }
            }
            NSArray * changeArray = [self change:resultArray];
            NSString * resultKey = [changeArray componentsJoinedByString:@";"];
            if (![keysArray containsObject:resultKey]) {
                [self.seletedEnable addObject:currentIndexPath];
            }
            
            
        }
        
    }
    
    
    [self price];
    
    NSString * StandardListName = dic[@"StandardListName"];
    if ([StandardListName isEqualToString:@"成色"]) {
        id obj = self.seletedIndexPaths[indexPath.section];
        if ([obj isKindOfClass:[NSIndexPath class]]) {
            self.currentTitle = self.alertInfo[indexPath.item];
        }
        else
        {
            self.currentTitle = @"(null)";
        }
    }
    
    
    [self.collectionView reloadData];
    
}

- (void)price
{
    NSMutableArray * resultArray = [[NSMutableArray alloc]init];
    for (NSString * str in self.seletedIdArray) {
        if (![str isEqualToString:@""]) {
            [resultArray addObject:str];
        }
    }
    NSArray * skeyArray =  [self change:resultArray];
    
    NSString * key = [skeyArray componentsJoinedByString:@";"];
    NSString * price = self.goodsprice;
//    NSString * count = @"0";
    for (NSDictionary * dic in self.skuResult) {
        NSString * skey = [[dic allKeys] firstObject];
        if ([key isEqualToString:skey]) {
            NSDictionary * dict = dic[key];
//            count = [NSString stringWithFormat:@"%@",dict[@"StocksNumber"]];
            NSArray * prices = dict[@"prices"];
            NSMutableArray * rPrices = [[NSMutableArray alloc]initWithArray:prices];
            NSArray * rePrices = [self change:rPrices];
            NSString * minPrice = [rePrices firstObject];
            NSString * maxPrice = [rePrices lastObject];
            if ([maxPrice isEqualToString:minPrice]) {
                price = [NSString stringWithFormat:@"￥%@",minPrice];
            }
            else
            {
                price = [NSString stringWithFormat:@"￥%@~￥%@",minPrice,maxPrice];
            }
        }
    }
    self.goodsPrice.text = price;

}





#pragma mark - SKU算法
- (void)createDataSource:(NSArray *)array
{
    NSMutableArray * keysArray = [[NSMutableArray alloc]init];
    NSMutableArray * valuesArray = [[NSMutableArray alloc]init];
    for (int i = 0; i < array.count; i++) {
        NSDictionary * dic = array[i];
        NSArray * keys = [dic allKeys];
        NSString * key = [keys firstObject];
        NSDictionary * value = [dic objectForKey:key];
        [keysArray addObject:key];
        [valuesArray addObject:value];
    }
    for (int j = 0; j < keysArray.count; j++) {
        NSString * key = keysArray[j];
        NSArray * subKeyAttrs = [key componentsSeparatedByString:@";"];
        NSMutableArray * muArray = [[NSMutableArray alloc]initWithArray:subKeyAttrs];
        NSArray * resultArray = [self change:muArray];
        
        NSArray * combArr = [self combInArray:resultArray];
        
        NSDictionary * sku = valuesArray[j];
        
        for (int k = 0; k < combArr.count; k++) {
            [self add2SKUResult:combArr[k] sku:sku];
        }
        NSString *keys = [resultArray componentsJoinedByString:@";"];
        NSString * price = [NSString stringWithFormat:@"%@",sku[@"Price"]];
        NSString * productId = NSString(@"%@", sku[@"ProductId"]);
        NSString * count = [NSString stringWithFormat:@"%@",sku[@"StocksNumber"]];
        NSMutableArray * prices = [[NSMutableArray alloc]init];
        NSMutableArray * productIds = [[NSMutableArray alloc]init];
        [prices addObject:price];
        [productIds addObject:productId];
        NSDictionary * dic = @{@"StocksNumber":count,@"prices":prices,@"productIds":productIds};
        NSDictionary * dict = @{keys:dic};
        [self.SKUResult addObject:dict];
    }
}



- (NSArray *)combInArray:(NSArray *)array
{
    if ([array isKindOfClass:[NSNull class]] || array.count == 0) {
        return @[];
    }
    
    int len = (int)array.count;
    NSMutableArray * aResult = [[NSMutableArray alloc]init];
    
    for (int n = 1; n < len; n++) {
        NSMutableArray * aaFlags = [[NSMutableArray alloc]initWithArray:[self getComFlags:len n:n]];
        
        while (aaFlags.count != 0) {
            NSMutableArray * aFlag = [[NSMutableArray alloc]initWithArray:[aaFlags firstObject]];
            [aaFlags removeObjectAtIndex:0];
            NSMutableArray * aComb = [[NSMutableArray alloc]init];
            for (int i = 0; i < len; i++) {
                if ([aFlag[i] intValue] == 1) {
                    [aComb addObject:array[i]];
                }
            }
            [aResult addObject:aComb];
            
        }
        
    }
    
    return aResult;
}

- (NSArray *)getComFlags:(int)m n:(int)n
{
    if (!n || n < 1) {
        return @[];
    }
    
    NSMutableArray * aFlag = [[NSMutableArray alloc]init];
    BOOL bNext = YES;
    
    for (int i = 0; i < m; i++) {
        int q = i < n ? 1 : 0;
        [aFlag addObject:[NSNumber numberWithInt:q]];
    }
    
    NSMutableArray * aResult = [[NSMutableArray alloc]init];
    [aResult addObject:[aFlag copy]];
    
    int iCnt1 = 0;
    while (bNext) {
        iCnt1 = 0;
        for (int i = 0; i < m - 1; i++) {
            if ([aFlag[i] intValue] == 1 && [aFlag[i+1] intValue] == 0) {
                for (int  j = 0; j < i; j++) {
                    int w = j < iCnt1 ? 1 : 0;
                    [aFlag removeObjectAtIndex:j];
                    [aFlag insertObject:[NSNumber numberWithInt:w] atIndex:j];
                }
                [aFlag removeObjectAtIndex:i];
                [aFlag insertObject:@(0) atIndex:i];
                [aFlag removeObjectAtIndex:i+1];
                [aFlag insertObject:@(1) atIndex:i+1];
                
                NSArray * aTmp = [aFlag copy];
                [aResult addObject:aTmp];
                
                int e = (int)aTmp.count;
                NSString * tempString;
                for (int r = e - n; r < e; r ++) {
                    tempString = [NSString stringWithFormat:@"%@%@",tempString,aTmp[r]];
                }
                if ([tempString rangeOfString:@"0"].location == NSNotFound) {
                    bNext = false;
                }
                
                break;
            }
            if ([aFlag[i] intValue] == 1) {
                iCnt1++;
            }
        }
    }
    return aResult;
}
- (void)add2SKUResult:(NSArray *)combArrItem sku:(NSDictionary *)sku
{
    NSString * key = [combArrItem componentsJoinedByString:@";"];
    NSMutableArray * keysArray = [[NSMutableArray alloc]init];
    for (NSDictionary * dic in self.SKUResult) {
        NSString * keys = [[dic allKeys] firstObject];
        [keysArray addObject:keys];
    }
    
    
    if ([keysArray containsObject:key]) {
        NSString * price = [NSString stringWithFormat:@"%@",sku[@"Price"]];
        NSString * productId = NSString(@"%@", sku[@"ProductId"]);
        NSString * count = [NSString stringWithFormat:@"%@",sku[@"StocksNumber"]];
        NSMutableDictionary * newDic = [[NSMutableDictionary alloc]init];
        int i = 0;
        for (NSDictionary * dict in self.SKUResult) {
            NSString * keys = [[dict allKeys] firstObject];
            if ([keys isEqualToString:key]) {
                NSMutableDictionary * tempDic = [[NSMutableDictionary alloc]init];
                NSDictionary * diction = dict[keys];
                NSString * scount = [NSString stringWithFormat:@"%@",diction[@"StocksNumber"]];
                int newCount = [scount intValue] + [count intValue];
                [tempDic setValue:[NSString stringWithFormat:@"%d",newCount] forKey:@"StocksNumber"];
                NSMutableArray * tempArray = [[NSMutableArray alloc]initWithArray:diction[@"prices"]];
                [tempArray addObject:price];
                NSMutableArray * productIds = [[NSMutableArray alloc]initWithArray:diction[@"productIds"]];
                [productIds addObject:productId];
                [tempDic setValue:tempArray forKey:@"prices"];
                [tempDic setValue:productIds forKey:@"productIds"];
                [newDic setValue:tempDic forKey:keys];
                [self.SKUResult removeObjectAtIndex:i];
                [self.SKUResult insertObject:newDic atIndex:i];
                break;
            }
            i++;
        }
        
    }
    else
    {
        NSString * price = [NSString stringWithFormat:@"%@",sku[@"Price"]];
        NSString * productId = NSString(@"%@", sku[@"ProductId"]);
        NSString * count = [NSString stringWithFormat:@"%@",sku[@"StocksNumber"]];
        NSMutableArray * productIds = [[NSMutableArray alloc]init];
        NSMutableArray * prices = [[NSMutableArray alloc]init];
        [productIds addObject:productId];
        [prices addObject:price];
        NSDictionary * dic = @{@"StocksNumber":count,@"prices":prices,@"productIds":productIds};
        NSDictionary * dict = @{key:dic};
        [self.SKUResult addObject:dict];
    }
}
///冒泡排序
- (NSArray *)change:(NSMutableArray *)array
{
    if (array.count > 1) {
        for (int  i =0; i<[array count]-1; i++) {
            
            for (int j = i+1; j<[array count]; j++) {
                
                if ([array[i] intValue]>[array[j] intValue]) {
                    
                    //交换
                    
                    [array exchangeObjectAtIndex:i withObjectAtIndex:j];
                    
                }
                
            }
            
        }
    }
    NSArray * resultArray = [[NSArray alloc]initWithArray:array];
    
    return resultArray;
}


#pragma mark - 懒加载
-(NSMutableArray *)dataSource
{
    if(_dataSource == nil)
    {
        _dataSource = [[NSMutableArray alloc]init];
    }
    return _dataSource;
}

-(NSMutableArray *)seletedIndexPaths
{
    if(_seletedIndexPaths == nil)
    {
        _seletedIndexPaths = [[NSMutableArray alloc]init];
    }
    return _seletedIndexPaths;
}


-(NSMutableArray *)seletedIdArray
{
    if(_seletedIdArray == nil)
    {
        _seletedIdArray = [[NSMutableArray alloc]init];
    }
    return _seletedIdArray;
}

-(NSMutableArray *)skuResult
{
    if(_skuResult == nil)
    {
        _skuResult = [[NSMutableArray alloc]init];
    }
    return _skuResult;
}


-(NSMutableArray *)noSelectedHead
{
    if(_noSelectedHead == nil)
    {
        _noSelectedHead = [[NSMutableArray alloc]init];
    }
    return _noSelectedHead;
}

-(NSMutableArray *)seletedEnable
{
    if(_seletedEnable == nil)
    {
        _seletedEnable = [[NSMutableArray alloc]init];
    }
    return _seletedEnable;
}

-(NSMutableArray *)alertInfo
{
    if(_alertInfo == nil)
    {
        _alertInfo = [[NSMutableArray alloc]init];
    }
    return _alertInfo;
}




-(NSMutableArray *)SKUResult
{
    if(_SKUResult == nil)
    {
        _SKUResult = [[NSMutableArray alloc]init];
    }
    return _SKUResult;
}



/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect {
 // Drawing code
 }
 */

@end
