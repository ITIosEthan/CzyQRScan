//
//  TFScanView.m
//  TKFACE
//
//  Created by macOfEthan on 17/3/30.
//  Copyright © 2017年 macOfEthan. All rights reserved.
//

#define TF_PreViewLayerW 200
#define TF_PreViewLayerH 200
#define TF_Margin 25
#define ZNLScreen_Width [UIScreen mainScreen].bounds.size.width
#define ZNLScreen_Height [UIScreen mainScreen].bounds.size.height

#import "TFScanView.h"
#import <AVFoundation/AVFoundation.h>

#define kFullWidth [UIScreen mainScreen].bounds.size.width
#define kFullHeight [UIScreen mainScreen].bounds.size.height
#define kMargin 25

@interface TFScanView ()<AVCaptureMetadataOutputObjectsDelegate>
{
    CGFloat min;
    CGFloat max;
    UIView *_topV;
    UIView *_bottomV;
    UIView *_leftV;
    UIView *_rightV;
    UILabel *_topL;
    UILabel *_bottomL;
    UIImageView *_torchImageView;
    UILabel *_torchOnOffLab;
    
    //是否开关灯
    BOOL _isTorchOn;
    //重新扫描
    //UIButton *_againBtn;
}

@property (nonatomic, strong) UIImageView *bgImageView;

@property (nonatomic, strong) UIImageView *lineImageView;

@property (nonatomic, strong) AVCaptureMetadataOutput *output;

@property (nonatomic, strong) AVCaptureSession *session;

@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

@property (nonatomic, assign) BOOL isUp;

@property (nonatomic, strong) NSTimer *timer;


@end

@implementation TFScanView

- (UIImageView *)bgImageView
{
    if (!_bgImageView) {
        self.bgImageView = [[UIImageView alloc] init];
        UIImage * bgImage = [[UIImage imageNamed:@"TF_SCAN_BGV"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        self.bgImageView.image = bgImage;
        self.bgImageView.contentMode = UIViewContentModeScaleAspectFit;
        self.bgImageView.tintColor = [UIColor blueColor];
        [self addSubview:self.bgImageView];
    }
    return _bgImageView;
}

- (UIImageView *)lineImageView
{
    if (!_lineImageView) {
        self.lineImageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"scanline"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        self.lineImageView.tintColor = [UIColor blueColor];
        [self addSubview:self.lineImageView];
    }
    return _lineImageView;
}

- (AVCaptureSession *)session
{
    if (!_session) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
        AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc] init];
        [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
        //坐标原点在右上角 分别对应y/h, x/w, h/h, w/w
        output.rectOfInterest = CGRectMake((CGRectGetHeight([UIScreen mainScreen].applicationFrame)-44-200)/2/ZNLScreen_Height, (ZNLScreen_Width-200)/2/ZNLScreen_Width, 200/ZNLScreen_Height, 200/ZNLScreen_Width);
        self.session = [[AVCaptureSession alloc] init];
        
        if ([self.session canAddInput:input]) {
            [self.session addInput:input];
        }
        if ([self.session canAddOutput:output]) {
            [self.session addOutput:output];
        }
        output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode];
    }
    return _session;
}

- (AVCaptureVideoPreviewLayer *)previewLayer
{
    if (!_previewLayer) {
        self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
        [self.layer insertSublayer:self.previewLayer atIndex:0];
    }
    return _previewLayer;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self initialize];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self initialize];
    }
    return self;
}

#pragma mark - layoutSubviews
- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat width  = 200;
    CGFloat height = width;
    CGFloat leftW = (ZNLScreen_Width-width)/2;
    CGFloat rightW = leftW;
    CGFloat topH = (CGRectGetHeight([UIScreen mainScreen].applicationFrame)-44-height)/2;
    
    _leftV.frame = CGRectMake(0, 0, leftW, self.bounds.size.height);
    _rightV.frame = CGRectMake(ZNLScreen_Width-rightW, 0, rightW, self.bounds.size.height);
    _topV.frame = CGRectMake(leftW, 0, ZNLScreen_Width-leftW-rightW, topH);
    _bottomV.frame = CGRectMake(leftW, topH+height, ZNLScreen_Width-leftW-rightW, ZNLScreen_Height-topH-height);
    
    self.bgImageView.frame = CGRectMake(leftW, topH, width, height);
    self.lineImageView.frame = CGRectMake(CGRectGetMinX(self.bgImageView.frame)+kMargin,
                                          CGRectGetMinY(self.bgImageView.frame)+kMargin,
                                          CGRectGetWidth(self.bgImageView.frame)-2*kMargin,
                                          1);
    self.previewLayer.frame = self.bounds;
    
    _topL.frame = CGRectMake(-10, topH-20, width+20, 14);
    _bottomL.frame = CGRectMake(-10, 10, width+20, 14);
    _torchImageView.frame = CGRectMake(width/2-20, CGRectGetMaxY(_bottomL.frame)+40, 40, 40);
    _torchOnOffLab.frame = CGRectMake(0, CGRectGetMaxY(_torchImageView.frame)+5, width, 14);
//    _againBtn.frame = CGRectMake(CGRectGetMidX(_torchOnOffLab.frame)-100/2, CGRectGetMaxY(_torchOnOffLab.frame)+5, 100, 20);
    
    min = CGRectGetMinY(self.lineImageView.frame);
    max = CGRectGetMaxY(self.bgImageView.frame)-kMargin;
    
    self.output.rectOfInterest = self.bgImageView.frame;
}

#pragma mark - 初始化
- (void)initialize
{
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(update) userInfo:nil repeats:YES];
    [self.timer setFireDate:[NSDate distantFuture]];
    
    _topV = [[UIView alloc] init];
    _topV.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:.5];
    [self addSubview:_topV];
    
    _topL = [[UILabel alloc] init];
    _topL.text = @"请扫描iPhone版WIFI二维码";
    _topL.textColor = [UIColor blueColor];
    _topL.font = [UIFont systemFontOfSize:14];
    _topL.textAlignment = NSTextAlignmentCenter;
    _topL.backgroundColor = [UIColor clearColor];
    [_topV addSubview:_topL];
    
    _bottomV = [[UIView alloc] init];
    _bottomV.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:.5];
    [self addSubview:_bottomV];
    
    _bottomL = [[UILabel alloc] init];
    _bottomL.text = @"将二维码放入框内即可自动扫描";
    _bottomL.textColor = [UIColor blueColor];
    _bottomL.font = [UIFont systemFontOfSize:14];
    _bottomL.textAlignment = NSTextAlignmentCenter;
    _bottomL.backgroundColor = [UIColor clearColor];
    [_bottomV addSubview:_bottomL];
    
    _isTorchOn = NO;
    
    _torchImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    _torchImageView.image = [[UIImage imageNamed:@"torch_off"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    _torchImageView.tintColor = [UIColor lightGrayColor];
    [_bottomV addSubview:_torchImageView];
    
    UITapGestureRecognizer * torchTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(torchTap:)];
    _bottomV.userInteractionEnabled = YES;
    _torchImageView.userInteractionEnabled = YES;
    [_torchImageView addGestureRecognizer:torchTap];
    
    _torchOnOffLab = [[UILabel alloc] init];
    _torchOnOffLab.text = @"开灯";
    _torchOnOffLab.textColor = [UIColor lightGrayColor];
    _torchOnOffLab.font = [UIFont systemFontOfSize:14];
    _torchOnOffLab.textAlignment = NSTextAlignmentCenter;
    _torchOnOffLab.backgroundColor = [UIColor clearColor];
    [_bottomV addSubview:_torchOnOffLab];
     
    _leftV = [[UIView alloc] init];
    _leftV.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:.5];
    [self addSubview:_leftV];
    
    _rightV = [[UIView alloc] init];
    _rightV.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:.5];
    [self addSubview:_rightV];
    
    
    [self layoutSubviews];
}

#pragma mark - 开始扫描
- (void)startScan
{
    [self.session startRunning];
    [self.timer setFireDate:[NSDate distantPast]];
}

#pragma mark - 设置动态UI
- (void)update
{
    CGRect frame = self.lineImageView.frame;
    
    if (frame.origin.y <= min) {
        self.isUp = NO;
    }else if (frame.origin.y >= max){
        self.isUp = YES;
    }
    
    if (self.isUp == NO) {
        frame.origin.y++;
    }else{
        frame.origin.y--;
    }
    
    self.lineImageView.frame = frame;
}

#pragma mark - 扫描结果
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    if (metadataObjects.count > 0) {
        
        [self.session stopRunning];
        
        [self.timer setFireDate:[NSDate distantFuture]];
        
        for (AVMetadataObject * metaDataObj in metadataObjects) {
            
            if ([metaDataObj isKindOfClass:[AVMetadataMachineReadableCodeObject class]]) {
                
                if (self.scanResult) {
                    
                    self.scanResult([metadataObjects.firstObject stringValue]);
                }
            }
        }
    }
}

#pragma mark - 开关灯
- (void)torchTap:(UITapGestureRecognizer *)tap
{
    _isTorchOn = !_isTorchOn;
    
    UIImageView * torchImageView = (UIImageView *)tap.view;
    
    if (_isTorchOn) {
        
        torchImageView.image = [[UIImage imageNamed:@"torch_on"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        torchImageView.tintColor = [UIColor blueColor];
        _torchOnOffLab.text = @"关灯";
        _torchOnOffLab.textColor = [UIColor blueColor];
        
    }else{
    
        torchImageView.image = [[UIImage imageNamed:@"torch_off"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        torchImageView.tintColor = [UIColor lightGrayColor];
        _torchOnOffLab.text = @"开灯";
        _torchOnOffLab.textColor = [UIColor lightGrayColor];
    }
    
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    
    if (captureDeviceClass != nil) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if ([device hasTorch] && [device hasFlash]){
            
            [device lockForConfiguration:nil];
            if (_isTorchOn) {
                [device setTorchMode:AVCaptureTorchModeOn];
                [device setFlashMode:AVCaptureFlashModeOn];
            } else {
                [device setTorchMode:AVCaptureTorchModeOff];
                [device setFlashMode:AVCaptureFlashModeOff];
            }
            [device unlockForConfiguration];
        }
    }
}

#pragma mark - 重新扫描
- (void)scanAgain:(UIButton *)sender
{
    [self startScan];
}

@end

