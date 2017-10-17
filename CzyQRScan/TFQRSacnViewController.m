//
//  TFQRSacnViewController.m
//  TKFACE
//
//  Created by macOfEthan on 17/3/30.
//  Copyright © 2017年 macOfEthan. All rights reserved.
//

#import "TFQRSacnViewController.h"
#import "TFScanView.h"

@interface TFQRSacnViewController ()
@property (nonatomic, strong) TFScanView *sv;

@end

@implementation TFQRSacnViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.sv startScan];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.sv = [[TFScanView alloc] initWithFrame:self.view.bounds];
    
    [self.view addSubview:self.sv];
    
    self.sv.scanResult = ^(NSString *value)
    {
        NSLog(@"value = %@", value);
    };
    
    [self.sv startScan];
}



@end









