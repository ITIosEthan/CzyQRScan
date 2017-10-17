//
//  TFScanView.h
//  TKFACE
//
//  Created by macOfEthan on 17/3/30.
//  Copyright © 2017年 macOfEthan. All rights reserved.
//

#import <UIKit/UIKit.h>

// >!返回扫描结果
typedef void(^ScanResult)(NSString *);

@interface TFScanView : UIView

@property (nonatomic, strong) ScanResult scanResult;

// >!开始扫描
- (void)startScan;

@end
