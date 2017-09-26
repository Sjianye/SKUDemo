//
//  BottomPopView.m
//  ToChangeTheCar
//
//  Created by 改车吧 on 16/11/4.
//  Copyright © 2016年 gaicheba. All rights reserved.
//

#import "BottomPopViewSKU.h"

#import "UICollectionViewLeftAlignedLayout.h"

#import "SpecHeadView.h"
#import "SpecLabelCell.h"
#import "ProductCountCell.h"


#define kSpecHeadView   @"SpecHeadView"
#define kSpecLabelCell  @"SpecLabelCell"
#define kScreenWidth ([UIScreen mainScreen].bounds.size.width)
#define kGAP 10.f

#define JY_Color(r, g, b) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1.0]
#define NSString(type,obj)   [NSString stringWithFormat:(type),(obj)]//强转字符串


@interface BottomPopViewSKU ()<UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout>
{
    NSInteger _currentCount;
    
    NSInteger _formatId;//规格ID
}
@property (weak, nonatomic) IBOutlet UIImageView *productImageView;
@property (weak, nonatomic) IBOutlet UILabel *productNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *priceLabel;

//展示规格的CollectionView
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

//确定按钮
@property (weak, nonatomic) IBOutlet UIButton *bottomSureButton;


@property (nonatomic ,strong)NSMutableArray * dataSource;//!<数据源
@property (nonatomic ,copy)void(^CallBackWithSiftSelected)(NSDictionary * dic);//!<回调规格选择的block
@property (nonatomic ,strong)NSMutableArray * skuResult;//!<可匹配规格
@property (nonatomic ,strong)NSMutableArray * seletedIndexPaths;//!<已经选中的规格数组
@property (nonatomic ,strong)NSMutableArray * seletedIdArray;//!<记录已选id
@property (nonatomic ,strong)NSMutableArray * seletedNameArray;//!<记录已选规格名称
@property (nonatomic ,strong)NSMutableArray * seletedEnable;//!<不可选indexPath
@property (nonatomic ,strong)NSMutableArray * noSelectedHead;//!<未选中的标题

@property (nonatomic ,strong)NSString * goodsId;//!<商品id
@property (nonatomic ,strong)NSString * goodsprice;//!<商品价格
@property (nonatomic ,strong)NSMutableArray * alertInfo;//!<提示信息
@property (nonatomic ,strong)NSString * currentTitle;//!<当前提示信息
@property (nonatomic ,strong)NSMutableArray * SKUResult;



@end

static  NSString *collectionNumberCellID = @"productcountcellid";

@implementation BottomPopViewSKU

- (void)awakeFromNib{
    [super awakeFromNib];
    _productImageView.layer.masksToBounds = YES;
    _productImageView.layer.cornerRadius = 5.f;
    _productImageView.layer.borderWidth = 2.f;
    _productImageView.layer.borderColor = [UIColor whiteColor].CGColor;
    _productImageView.backgroundColor = [UIColor lightGrayColor];
    [self bringSubviewToFront:_productNameLabel];

    //设置底部按钮选中样式
    CGRect rect=CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [[UIColor lightGrayColor] CGColor]);
    CGContextFillRect(context, rect);
    UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    [_bottomSureButton setBackgroundImage:theImage forState:UIControlStateSelected];
    
    [self.collectionView registerNib:[UINib nibWithNibName:kSpecLabelCell bundle:nil] forCellWithReuseIdentifier:kSpecLabelCell];
    [self.collectionView registerNib:[UINib nibWithNibName:kSpecHeadView bundle:nil] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:kSpecHeadView];
    [self.collectionView registerNib:[UINib nibWithNibName:@"ProductCountCell" bundle:nil] forCellWithReuseIdentifier:collectionNumberCellID];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    UICollectionViewLeftAlignedLayout * flowLayout = [[UICollectionViewLeftAlignedLayout alloc]init];
    flowLayout.minimumInteritemSpacing = 15;
    flowLayout.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10);
    [self.collectionView setCollectionViewLayout:flowLayout];
    //self.currentTitle = @"";
}

///接收通知处理数据
- (void)reloadWindow:(NSDictionary *)object
{
    NSArray * skuResult = self.SKUResult;
    [self.skuResult removeAllObjects];
    [self.seletedEnable removeAllObjects];
    [self.seletedIdArray removeAllObjects];
    [self.seletedIndexPaths removeAllObjects];
    [self.skuResult addObjectsFromArray:skuResult];
    
    ///取出SKUResult中所有可能的排列组合方式(keysArray)
    NSMutableArray * keysArray = [[NSMutableArray alloc]init];
    for (NSDictionary * dict in self.skuResult) {
        NSString * key = [[dict allKeys] firstObject];
        [keysArray addObject:key];
    }
    
//    NSDictionary * dic = result[@"Result"];
//    self.goodsId = NSString(@"%@", dic[@"MinId"]);
    [self.dataSource removeAllObjects];
    NSArray * array = [object objectForKey:@"standType"];
    
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
    
    self.priceLabel.text = price;
    self.goodsprice = price;
    
    for (NSDictionary * dic in array) {
        [self.seletedIndexPaths addObject:@"0"];
        [self.seletedIdArray addObject:@""];
        [self.seletedNameArray addObject:@""];
        
        [self.dataSource addObject:dic];
    }
    
    [self.seletedEnable removeAllObjects];
    
    for (int i = 0; i < self.dataSource.count; i++) {
        NSDictionary * subDic = self.dataSource[i];
        NSArray *subArray = subDic[@"standard"];
        for (int j = 0; j < subArray.count; j++) {
            NSDictionary * reSubDic = subArray[j];
            NSIndexPath * currentIndexPath = [NSIndexPath indexPathForItem:j inSection:i];
            NSString * currentId = NSString(@"%@", reSubDic[@"id"]);
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







#pragma mark - SKU算法
- (void)createDataSource:(NSArray *)array
{
    NSMutableArray * keysArray = [[NSMutableArray alloc]init];
    NSMutableArray * valuesArray = [[NSMutableArray alloc]init];
    for (int i = 0; i < array.count; i++) {
        
        
        
        NSDictionary * dic = array[i];
        [keysArray addObject:[dic valueForKey:@"skuIds"]];
        [valuesArray addObject:dic];
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
        NSString * price = [NSString stringWithFormat:@"%@",sku[@"price"]];
        NSString * skuId = NSString(@"%@", sku[@"skuId"]);
        NSMutableArray * prices = [[NSMutableArray alloc]init];
        NSMutableArray * skuIds = [[NSMutableArray alloc]init];
        [prices addObject:price];
        [skuIds addObject:skuId];
        NSDictionary * dic = @{@"prices":prices,@"skuIds":skuIds};
        NSDictionary * dict = @{keys:dic};
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
        NSString * price = [NSString stringWithFormat:@"%@",sku[@"price"]];
        NSString * skuId = NSString(@"%@", sku[@"skuId"]);
        NSMutableDictionary * newDic = [[NSMutableDictionary alloc]init];
        int i = 0;
        for (NSDictionary * dict in self.SKUResult) {
            NSString * keys = [[dict allKeys] firstObject];
            if ([keys isEqualToString:key]) {
                NSMutableDictionary * tempDic = [[NSMutableDictionary alloc]init];
                NSDictionary * diction = dict[keys];
                NSMutableArray * tempArray = [[NSMutableArray alloc]initWithArray:diction[@"prices"]];
                [tempArray addObject:price];
                NSMutableArray * skuIds = [[NSMutableArray alloc]initWithArray:diction[@"skuIds"]];
                [skuIds addObject:skuId];
                [tempDic setValue:tempArray forKey:@"prices"];
                [tempDic setValue:skuIds forKey:@"skuIds"];
                [newDic setValue:tempDic forKey:keys];
                [self.SKUResult removeObjectAtIndex:i];
                [self.SKUResult insertObject:newDic atIndex:i];
                break;
            }
            i++;
        }
        
    }else{
        NSString * price = [NSString stringWithFormat:@"%@",sku[@"price"]];
        NSString * skuId = NSString(@"%@", sku[@"skuId"]);
        NSMutableArray * skuIds = [[NSMutableArray alloc]init];
        NSMutableArray * prices = [[NSMutableArray alloc]init];
        [skuIds addObject:skuId];
        [prices addObject:price];
        NSDictionary * dic = @{@"prices":prices,@"productIds":skuIds};
        NSDictionary * dict = @{key:dic};
        [self.SKUResult addObject:dict];
    }
}
#pragma mark - UICollectionViewDataSource - UICollectionViewDelegate - UICollectionViewDelegateFlowLayout
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return self.dataSource.count + 1;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (section == self.dataSource.count) {
        return 1;
    }
    NSDictionary * dic = self.dataSource[section];
    NSArray * array = dic[@"standard"];
    return array.count;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (indexPath.section == self.dataSource.count) {
        ProductCountCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:collectionNumberCellID forIndexPath:indexPath];
        cell.count = _currentCount;
        cell.jyProductCountCallBack = ^(NSInteger count){
            _currentCount = count;
        };
        return cell;
    }
    
    
    
    SpecLabelCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:kSpecLabelCell forIndexPath:indexPath];
    NSDictionary * dic = self.dataSource[indexPath.section];
    NSArray * array = dic[@"standard"];
    NSDictionary * dict = array[indexPath.item];
    cell.nameLabel.text = NSString(@"%@", dict[@"name"]);
    cell.layer.cornerRadius = 5;
    cell.layer.masksToBounds = YES;
    
    
    ///不可选
    if ([self.seletedEnable containsObject:indexPath]) {
        cell.nameLabel.textColor = JY_Color(205, 205, 205);
        cell.backImage.image = [self getImageWithColor:JY_Color(250, 250, 250)];
        cell.userInteractionEnabled = NO;
    }
    //可选
    else
    {
        cell.nameLabel.textColor = [UIColor darkGrayColor];
        cell.backImage.image = [self getImageWithColor:JY_Color(240, 240, 240)];

        cell.userInteractionEnabled = YES;
    }
    
    //选中
    if ([self.seletedIndexPaths containsObject:indexPath]) {
        cell.nameLabel.textColor = [UIColor whiteColor];
        cell.backImage.image = [self getImageWithColor:JY_Color(136, 39, 44)];

        cell.userInteractionEnabled = YES;
    }
    
    
    
    return cell;
}
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (indexPath.section == self.dataSource.count) {
        return CGSizeMake(kScreenWidth - 20.f, 45.f);
    }

    
    NSDictionary * dic = self.dataSource[indexPath.section];
    NSArray * array = dic[@"standard"];
    NSDictionary * dict = array[indexPath.item];
    NSString * string = NSString(@"%@", dict[@"name"]);
    CGFloat width = [self widthForString:string];
    return CGSizeMake(width, 25);
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == self.dataSource.count) {
        return [[UICollectionViewCell alloc] init];
    }

    SpecHeadView * headView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:kSpecHeadView forIndexPath:indexPath];
    NSDictionary * dic = self.dataSource[indexPath.section];
    headView.nameLabel.text = NSString(@"%@", dic[@"typename"]);

    
    return headView;
}
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    if (section == self.dataSource.count) {
        return CGSizeZero;
    }

    return CGSizeMake(kScreenWidth - 20, 20);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (indexPath.section == self.dataSource.count) {
        return;
    }
    
    ///取出SKUResult中所有可能的排列组合方式(keysArray)
    NSMutableArray * keysArray = [[NSMutableArray alloc]init];
    for (NSDictionary * dict in self.skuResult) {
        NSString * key = [[dict allKeys] firstObject];
        [keysArray addObject:key];
    }
    
    NSDictionary * dic = self.dataSource[indexPath.section];
    
    
    NSArray * array = dic[@"standard"];
    NSDictionary * dict = array[indexPath.item];
    NSString * AttrValueId = NSString(@"%@", dict[@"id"]);
    NSString * selectName = NSString(@"%@", dict[@"name"]);
    
    //取出所有选中状态的按钮标题
    //如果已经被选中则取消选中
    if ([self.seletedIndexPaths containsObject:indexPath]) {
        [self.seletedIndexPaths removeObjectAtIndex:indexPath.section];
        [self.seletedIndexPaths insertObject:@"0" atIndex:indexPath.section];
        [self.seletedIdArray removeObjectAtIndex:indexPath.section];
        [self.seletedIdArray insertObject:@"" atIndex:indexPath.section];
        [self.seletedNameArray removeObjectAtIndex:indexPath.section];
        [self.seletedNameArray insertObject:@"" atIndex:indexPath.section];
    }
    else
    {
        [self.seletedIndexPaths removeObjectAtIndex:indexPath.section];
        [self.seletedIndexPaths insertObject:indexPath atIndex:indexPath.section];
        [self.seletedIdArray removeObjectAtIndex:indexPath.section];
        [self.seletedIdArray insertObject:AttrValueId atIndex:indexPath.section];
        [self.seletedNameArray removeObjectAtIndex:indexPath.section];
        [self.seletedNameArray insertObject:selectName atIndex:indexPath.section];
    }
    
    NSMutableArray *mutArray = [NSMutableArray array];
    for (NSString *str in self.seletedNameArray) {
        if (![str isEqualToString:@""]) {
            [mutArray addObject:[NSString stringWithFormat:@"\"%@\"",str]];
        }
    }
    NSString *skusStr = [mutArray componentsJoinedByString:@","];
    _productNameLabel.text = [NSString stringWithFormat:@"已选:%@",skusStr];
    
    [self.seletedEnable removeAllObjects];
    
    for (int i = 0; i < self.dataSource.count; i++) {
        NSDictionary * subDic = self.dataSource[i];
        NSArray *subArray = subDic[@"standard"];
        for (int j = 0; j < subArray.count; j++) {
            NSDictionary * reSubDic = subArray[j];
            NSIndexPath * currentIndexPath = [NSIndexPath indexPathForItem:j inSection:i];
            NSString * currentId = NSString(@"%@", reSubDic[@"id"]);
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

    if (isAllSelected) {
        _bottomSureButton.userInteractionEnabled = YES;
        _bottomSureButton.selected = NO;
    }else{
        _bottomSureButton.userInteractionEnabled = NO;
        _bottomSureButton.selected = YES;
    }
    
    
    [self.collectionView reloadData];
    
}
- (void)price{
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
    self.priceLabel.text = price;
    
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

-(NSMutableArray *)seletedNameArray{
    if (_seletedNameArray == nil) {
        _seletedNameArray = [NSMutableArray array];
    }
    return _seletedNameArray;
}



-(NSMutableArray *)noSelectedHead
{
    if(_noSelectedHead == nil)
    {
        _noSelectedHead = [[NSMutableArray alloc]init];
    }
    return _noSelectedHead;
}


//传入SKU数组
- (void)setResponseDic:(NSDictionary *)dic{
    
    
    NSDictionary *dataDic = [dic objectForKey:@"data"];
    NSArray *array = [dataDic objectForKey:@"skuDate"];
    
    [self createDataSource:array];
    [self reloadWindow:dataDic];

}

//商品详情页面修改数量(传入的为商品模型)
- (void)setProductModel:(ProductModel *)productModel{
    _productModel = productModel;
    

    _productNameLabel.text = @"已选:无";
    [self.seletedNameArray removeAllObjects];
    [self.seletedIdArray removeAllObjects];

    //关闭点击事件(SKU产品无默认选中)
    _bottomSureButton.userInteractionEnabled = NO;
    _bottomSureButton.selected = YES;
}






//关闭按钮
- (IBAction)closeBtnClick:(UIButton *)sender {
    if (_jyPopViewCloseClick) {
        _jyPopViewCloseClick();
    }
}
//确定按钮
- (IBAction)sureBtnClick:(UIButton *)sender {
    if (_jyPopViewSureClick) {
        
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
        
        NSMutableArray * resultArray = [[NSMutableArray alloc]init];
        for (NSString * str in self.seletedIdArray) {
            if (![str isEqualToString:@""]) {
                [resultArray addObject:str];
            }
        }
        NSArray * skeyArray =  [self change:resultArray];
        
        NSString * key = [skeyArray componentsJoinedByString:@";"];
        NSString * price = self.goodsprice;
        for (NSDictionary * dic in self.skuResult) {
            NSString * skey = [[dic allKeys] firstObject];
            if ([key isEqualToString:skey]) {
                NSDictionary * dict = dic[key];
                NSArray * prices = dict[@"prices"];
                NSMutableArray * rPrices = [[NSMutableArray alloc]initWithArray:prices];
                NSArray * rePrices = [self change:rPrices];
                NSString * minPrice = [rePrices firstObject];
                NSString * maxPrice = [rePrices lastObject];
                if ([maxPrice isEqualToString:minPrice]) {
                    price = [NSString stringWithFormat:@"%@",maxPrice];
                }else{
                    return;
                }
            }
        }

        NSString *skusStr = [self.seletedNameArray componentsJoinedByString:@","];

        
        _jyPopViewSureClick(_productModel);
        
    }
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
    
    NSArray * goodsIds;
    for (NSDictionary * dic in self.skuResult) {
        NSString * skey = [[dic allKeys] firstObject];
        if ([key isEqualToString:skey]) {
            NSDictionary * dict = dic[key];
            NSArray * productIds = dict[@"skuIds"];
            goodsIds = productIds;
        }
    }
    return goodsIds;
    
}


- (CGFloat)widthForString:(NSString *)string {
    //宽度加 heightForCell 为了两边圆角。
    UILabel *label = [[UILabel alloc] init];
    label.text = string;
    label.font = [UIFont systemFontOfSize:14.f];
    
    CGSize textSize = [label.text sizeWithAttributes:@{NSFontAttributeName:label.font}];

    if (textSize.width >= kScreenWidth) {
        textSize.width = kScreenWidth - 2*kGAP;
    }else if (textSize.width <= 5*kGAP) {
        textSize.width = 5*kGAP;
    }else {
        textSize.width += 2*kGAP;
    }
    return textSize.width;
}

- (UIImage *)getImageWithColor:(UIColor *)color{
    CGRect rect=CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return theImage;
}



@end
