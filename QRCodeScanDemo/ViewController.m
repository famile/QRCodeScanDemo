//
//  ViewController.m
//  QRCodeScanDemo
//
//  Created by 李涛 on 2018/5/29.
//  Copyright © 2018年 Tao_Lee. All rights reserved.
//

#import "ViewController.h"
#import "YXQRMaskView.h"
#import <AVFoundation/AVFoundation.h>
#import "YXQRHeader.h"

@interface ViewController ()<AVCaptureMetadataOutputObjectsDelegate,AVCaptureVideoDataOutputSampleBufferDelegate,UIGestureRecognizerDelegate>

@property (nonatomic, copy) NSString *contentStr;

@property (strong,nonatomic) YXQRMaskView *maskView;

@property (strong,nonatomic) AVCaptureVideoPreviewLayer *layer;

@property (nonatomic, strong) AVCaptureSession *session;

@property (nonatomic, strong) AVCaptureDevice *device;

@property (assign,nonatomic) CGFloat initialPinchZoom;

@property(nonatomic,strong)  AVCaptureStillImageOutput *stillImageOutput;//拍照

@property (nonatomic, assign) CGFloat maxZoom;

@property (nonatomic, strong) UIView *focusView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self initUI];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.session startRunning];
    
    [self.maskView repetitionAnimation];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.session stopRunning];
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate
-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);//震动提示
    //提示音
    SystemSoundID soundIDTest = 1052;
    AudioServicesPlaySystemSound(soundIDTest);
    
    if (metadataObjects != nil && metadataObjects.count > 0) {
        [self.session stopRunning];
        [_maskView stopAnimation];
        AVMetadataMachineReadableCodeObject *obj = metadataObjects[0];
        
        NSString *json = [obj stringValue];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"扫描结果" message:json preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self.session startRunning];
            
            [self.maskView repetitionAnimation];
        }];
        [alert addAction:okAction];
        [self presentViewController:alert animated:YES completion:nil];
    }else{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"扫描结果" message:@"无效的二维码" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self.session startRunning];
            [self.maskView repetitionAnimation];
        }];
        [alert addAction:okAction];
        [self presentViewController:alert animated:YES completion:nil];
    }
}


#pragma mark - httpRequest

#pragma mark - click
//双击
-(void)handleDoubleTap:(UITapGestureRecognizer *)recogniser {
    
    if (!_device)
        return;
    
    if (recogniser.state == UIGestureRecognizerStateBegan)
    {
        _initialPinchZoom = _device.videoZoomFactor;
    }
    
    NSError *error = nil;
    [_device lockForConfiguration:&error];
    
    if (!error) {
        
        CGFloat zoomFactor;
        
        if (_device.videoZoomFactor == 1.0f) {
            zoomFactor = _maxZoom;
        }
        else{
            zoomFactor = 1.0f;
        }
        
        _device.videoZoomFactor = zoomFactor;
        
        [_device unlockForConfiguration];
        
    }
    
}

//双指触摸
- (void)pinchDetected:(UIPinchGestureRecognizer *)recogniser {
    
    if (!_device)
        return;
    
    if (recogniser.state == UIGestureRecognizerStateBegan)
    {
        _initialPinchZoom = _device.videoZoomFactor;
    }
    
    NSError *error = nil;
    [_device lockForConfiguration:&error];
    
    if (!error) {
        CGFloat zoomFactor;
        CGFloat scale = recogniser.scale;
        zoomFactor = scale * _initialPinchZoom;
        zoomFactor = MIN(_maxZoom, zoomFactor);
        zoomFactor = MAX(1.0f, zoomFactor);
        
        _device.videoZoomFactor = zoomFactor;
        
        [_device unlockForConfiguration];
        
        NSLog(@"%f",_device.videoZoomFactor);
    }
}
#pragma mark - private method
//手动对焦
- (void)focusGesture:(UITapGestureRecognizer*)gesture{
    CGPoint point = [gesture locationInView:gesture.view];
    [self focusAtPoint:point];
}
- (void)focusAtPoint:(CGPoint)point{
    CGSize size = self.view.bounds.size;
    CGPoint focusPoint = CGPointMake( point.y /size.height ,1-point.x/size.width );
    NSError *error;
    if ([self.device lockForConfiguration:&error]) {
        
        if ([self.device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            [self.device setFocusPointOfInterest:focusPoint];
            [self.device setFocusMode:AVCaptureFocusModeAutoFocus];
        }
        
        if ([self.device isExposureModeSupported:AVCaptureExposureModeAutoExpose ]) {
            [self.device setExposurePointOfInterest:focusPoint];
            [self.device setExposureMode:AVCaptureExposureModeAutoExpose];
        }
        
        [self.device unlockForConfiguration];
        _focusView.center = point;
        _focusView.hidden = NO;
        [UIView animateWithDuration:0.3 animations:^{
            _focusView.transform = CGAffineTransformMakeScale(1.25, 1.25);
        }completion:^(BOOL finished) {
            [UIView animateWithDuration:0.5 animations:^{
                _focusView.transform = CGAffineTransformIdentity;
            } completion:^(BOOL finished) {
                _focusView.hidden = YES;
            }];
        }];
    }
}
//自动对焦
- (void)subjectAreaDidChange:(NSNotification *)notification
{
    if (_device.focusMode == AVCaptureFocusModeContinuousAutoFocus) {
        return;
    }
    //先进行判断是否支持控制对焦
    if (_device.isFocusPointOfInterestSupported &&[_device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        NSError *error =nil;
        //对cameraDevice进行操作前，需要先锁定，防止其他线程访问，
        [_device lockForConfiguration:&error];
        //自动对焦
        [_device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
        [_device setFocusPointOfInterest:CGPointMake(0.5, 0.5)];
        //自动曝光
        [_device setExposureMode:(AVCaptureExposureModeContinuousAutoExposure)];
        [_device setExposurePointOfInterest:CGPointMake(0.5, 0.5)];
        //        [self focusAtPoint:CGPointMake(ScreenWidth/2, ScreenHeight/2 - 32.5*SCALE)];
        //操作完成后，记得进行unlock。
        [_device unlockForConfiguration];
    }
}
#pragma mark - setter

#pragma mark - init
- (void)initUI{
    
    _maskView = [YXQRMaskView maskView];
    _maskView.frame = CGRectMake(0, 0, screenW, screenH);
    
    _maskView.sideImage = [UIImage imageNamed:@"img_test_wide"];
    _maskView.lineImage = [UIImage imageNamed:@"img_test_wire"];
    
    [self setUpGesture];
    
    //    self.view.backgroundColor = [UIColor blueColor];
    
    [self.view addSubview:_maskView];
    
    _layer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    _layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    _layer.frame = self.view.layer.bounds;
    [self.view.layer insertSublayer:_layer atIndex:0];
    //    [self.view.layer addSublayer:_layer];
    
    
    
    _maxZoom = ([[_stillImageOutput connectionWithMediaType:AVMediaTypeVideo] videoMaxScaleAndCropFactor])/16;
    
    _focusView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 80, 80)];
    _focusView.layer.borderWidth = 1.0;
    _focusView.layer.borderColor =ColorFrom0xRGB(0xffea01).CGColor;
    _focusView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_focusView];
    _focusView.hidden = YES;
    
    //添加位置改变的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:)name:AVCaptureDeviceSubjectAreaDidChangeNotification object:self.device];
    
}
- (AVCaptureSession *)session{
    if (!_session) {
        _session = ({
            
            //获取摄像设备
            AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
            NSError *error =nil;
            NSLog(@"%@",@(device.focusMode));
            NSLog(@"%@",@(device.focusPointOfInterest));
            NSLog(@"%@",@(device.exposureMode));
            NSLog(@"%@",@(device.exposurePointOfInterest));
            [device lockForConfiguration:&error];
            device.subjectAreaChangeMonitoringEnabled=YES;
            [device unlockForConfiguration];
            _device = device;
            
            AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
            if (!input) {
                return nil;
            }
            
            //创建输出流
            AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc] init];
            AVCaptureVideoDataOutput *sampleOutput = [[AVCaptureVideoDataOutput alloc] init];
            _stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
            NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:
                                            AVVideoCodecJPEG, AVVideoCodecKey,
                                            nil];
            [_stillImageOutput setOutputSettings:outputSettings];
            
            //设置代理 主线程刷新
            [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
            [sampleOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
            
            //设置扫描区域
            //扫描区域（y,x,h,w）
            CGFloat width = screenW * 0.8;
            CGFloat x = (screenW-width)/2/screenW;
            CGFloat y = (screenH-width-65*SCALE)/2/screenH;
            output.rectOfInterest = CGRectMake(y, x, width/screenH, width/screenW);
            
            AVCaptureSession *session = [[AVCaptureSession alloc] init];
            //高质量采集率
            [session setSessionPreset:AVCaptureSessionPresetHigh];
            if ([session canAddInput:input])
            {
                [session addInput:input];
            }
            
            if ([session canAddOutput:output])
            {
                [session addOutput:output];
            }
            
            if ([session canAddOutput:sampleOutput])
            {
                [session addOutput:sampleOutput];
            }
            if ([session canAddOutput:_stillImageOutput])
            {
                [session addOutput:_stillImageOutput];
            }
            output.metadataObjectTypes = [self defaultMetaDataObjectTypes];
            session;
        });
    }
    return _session;
}

- (NSArray *)defaultMetaDataObjectTypes
{
    NSMutableArray *types = [@[AVMetadataObjectTypeQRCode,
                               AVMetadataObjectTypeUPCECode,
                               AVMetadataObjectTypeCode39Code,
                               AVMetadataObjectTypeCode39Mod43Code,
                               AVMetadataObjectTypeEAN13Code,
                               AVMetadataObjectTypeEAN8Code,
                               AVMetadataObjectTypeCode93Code,
                               AVMetadataObjectTypeCode128Code,
                               AVMetadataObjectTypePDF417Code,
                               AVMetadataObjectTypeAztecCode] mutableCopy];
    
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_8_0)
    {
        [types addObjectsFromArray:@[
                                     AVMetadataObjectTypeInterleaved2of5Code,
                                     AVMetadataObjectTypeITF14Code,
                                     AVMetadataObjectTypeDataMatrixCode
                                     ]];
    }
    
    return types;
}

//添加手势
- (void)setUpGesture{
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(focusGesture:)];
    tapGesture.numberOfTapsRequired = 1;
    tapGesture.numberOfTouchesRequired = 1;
    [self.maskView addGestureRecognizer:tapGesture];
    
    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchDetected:)];
    pinch.delegate = self;
    [self.maskView addGestureRecognizer:pinch];
    
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    doubleTap.numberOfTapsRequired = 2;
    doubleTap.numberOfTouchesRequired = 1;
    [self.maskView addGestureRecognizer:doubleTap];
    //双击识别失败再识别单击
    [tapGesture requireGestureRecognizerToFail:doubleTap];
}

@end
