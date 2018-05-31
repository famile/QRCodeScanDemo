//
//  YXQRHeader.h
//  QRCodeScanDemo
//
//  Created by 李涛 on 2018/5/29.
//  Copyright © 2018年 Tao_Lee. All rights reserved.
//

#ifndef YXQRHeader_h
#define YXQRHeader_h

#define screenW CGRectGetWidth([UIScreen mainScreen].bounds)
#define screenH CGRectGetHeight([UIScreen mainScreen].bounds)
//适配时放缩比例
#define SCALE ([UIScreen mainScreen].bounds.size.width/375.0) //以主流iPhone6为基准

#define ColorFrom0xRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#endif /* YXQRHeader_h */
