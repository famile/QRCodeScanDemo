//
//  ZZMaskView.m
//  ZZQRCode
//
//  Created by POPLAR on 2017/6/6.
//  Copyright © 2017年 user. All rights reserved.
//

#import "YXQRMaskView.h"
#import <AVFoundation/AVFoundation.h>
#import "YXQRHeader.h"

@interface YXQRMaskView ()

@property (nonatomic, strong) CALayer *lineLayer;

@property (strong,nonatomic) UIImageView *sideImageView;
@property (strong,nonatomic) UIView *topView;
@property (strong,nonatomic) UIView *bottomView;
@property (strong,nonatomic) UIView *leftView;
@property (strong,nonatomic) UIView *rightView;

@end

@implementation YXQRMaskView

+ (instancetype)maskView {
    
    YXQRMaskView *maskView = [[YXQRMaskView alloc] init];
    
    return maskView;
    
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
    
}


#pragma mark - httpRequest

#pragma mark - click

#pragma mark - private method
// 照明灯的点击事件
- (void)light_buttonAction:(UIButton *)button {
    if (button.selected == NO) { // 点击打开照明灯
        [self turnOnLight:YES];
        button.selected = YES;
    } else { // 点击关闭照明灯
        [self turnOnLight:NO];
        button.selected = NO;
    }
}

- (void)turnOnLight:(BOOL)on {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([device hasTorch]) {
        [device lockForConfiguration:nil];
        if (on) {
            [device setTorchMode:AVCaptureTorchModeOn];
        } else {
            [device setTorchMode: AVCaptureTorchModeOff];
        }
        [device unlockForConfiguration];
    }
}

#pragma mark - setter

#pragma mark - init

-(void)setupUI{
    self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
    
    if (!_allAroundColor) {
        _allAroundColor = [UIColor blackColor];
    }
    
    if (!_allAroundAlpha) {
        _allAroundAlpha = 0.4;
    }
    
    //扫描区域
    UIImageView *sideImageView = [[UIImageView alloc] init];
    sideImageView.image = _sideImage;
    
    //上
    UIView *topView = [[UIView alloc] init];
    topView.backgroundColor = _allAroundColor;
    topView.alpha = _allAroundAlpha;
    
    //下
    UIView *bottomView = [[UIView alloc] init];
    bottomView.backgroundColor = _allAroundColor;
    bottomView.alpha = _allAroundAlpha;
    
    //左
    UIView *leftView = [[UIView alloc] init];
    leftView.backgroundColor = _allAroundColor;
    leftView.alpha = _allAroundAlpha;
    
    //右
    UIView *rightView = [[UIView alloc] init];
    rightView.backgroundColor = _allAroundColor;
    rightView.alpha = _allAroundAlpha;
    
    
   //--------布局
    
    if (!_scanSize) {
        _scanSize = screenW * 0.8;
    }
    
    CGFloat topViewH = (screenH-65*SCALE - _scanSize)/2;
    CGFloat bottomViewH = topViewH+65*SCALE;
    CGFloat leftAndRightViewW = (screenW - _scanSize)/2;
    CGFloat leftAndRightViewH = screenH - topViewH - bottomViewH;
    
    sideImageView.frame = CGRectMake((screenW - _scanSize)/2, (screenH-65*SCALE-_scanSize)/2, _scanSize, _scanSize);
    topView.frame = CGRectMake(0, 0, screenW,topViewH);
    bottomView.frame = CGRectMake(0, screenH-bottomViewH, screenW, bottomViewH);
    leftView.frame = CGRectMake(0, topViewH, leftAndRightViewW, leftAndRightViewH);
    rightView.frame = CGRectMake(screenW-leftAndRightViewW, topViewH, leftAndRightViewW, leftAndRightViewH);
    
    [self addSubview:sideImageView];
    [self addSubview:topView];
    [self addSubview:bottomView];
    [self addSubview:leftView];
    [self addSubview:rightView];

    //线
    self.lineLayer = [CALayer layer];
    self.lineLayer.contents = (id)_lineImage.CGImage;
    [self.layer addSublayer:self.lineLayer];
    [self repetitionAnimation];
    
    _sideImageView = sideImageView;
    _topView = topView;
    _bottomView = bottomView;
    _leftView = leftView;
    _rightView = rightView;
    
    
    // 提示Label
    UILabel *promptLabel = [[UILabel alloc] init];
    promptLabel.backgroundColor = [UIColor clearColor];
    CGFloat promptLabelX = 0;
    CGFloat promptLabelY = screenH-bottomViewH + 18;
    CGFloat promptLabelW = screenW;
    CGFloat promptLabelH = 25;
    promptLabel.frame = CGRectMake(promptLabelX, promptLabelY, promptLabelW, promptLabelH);
    promptLabel.textAlignment = NSTextAlignmentCenter;
    promptLabel.font = [UIFont boldSystemFontOfSize:13.0];
    promptLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.6];
    promptLabel.text = @"将取景框对准二维码, 即可自动扫描";
    [self addSubview:promptLabel];
    
    
    // 添加闪光灯按钮
    UIButton *light_button = [[UIButton alloc] init];
    CGFloat light_buttonX = screenW/2 - 45;
    CGFloat light_buttonY = screenH - 30 - 65;
    CGFloat light_buttonW = 90;
    CGFloat light_buttonH = 65;
    light_button.frame = CGRectMake(light_buttonX, light_buttonY, light_buttonW, light_buttonH);
    light_button.titleLabel.font = [UIFont systemFontOfSize:14];
    [light_button setImage:[UIImage imageNamed:@"home_flashlight_off"] forState:(UIControlStateNormal)];
    [light_button setImage:[UIImage imageNamed:@"home_flashlight_on"] forState:(UIControlStateSelected)];
    

    light_button.titleLabel.font = [UIFont systemFontOfSize:17];    
    [light_button addTarget:self action:@selector(light_buttonAction:) forControlEvents:UIControlEventTouchUpInside];

    
    [self addSubview:light_button];

}

- (void)drawRect:(CGRect)rect
{
    if (!_sideImage) {
        
        if (!_scanSize) {
            _scanSize = screenW * 0.8;
        }
        
        CGFloat width = rect.size.width;
        CGFloat height = rect.size.height;
        CGFloat pickingFieldWidth = _scanSize;
        CGFloat pickingFieldHeight = _scanSize;
        
        CGContextRef contextRef = UIGraphicsGetCurrentContext();
        CGContextSaveGState(contextRef);
        CGContextSetRGBFillColor(contextRef, 0, 0, 0, 0.35);
        CGContextSetLineWidth(contextRef, 3);
        
        CGRect pickingFieldRect = CGRectMake((width - pickingFieldWidth) / 2, (height - pickingFieldHeight) / 2, pickingFieldWidth, pickingFieldHeight);
        
        UIBezierPath *pickingFieldPath = [UIBezierPath bezierPathWithRect:pickingFieldRect];
        UIBezierPath *bezierPathRect = [UIBezierPath bezierPathWithRect:rect];
        [bezierPathRect appendPath:pickingFieldPath];
        
        bezierPathRect.usesEvenOddFillRule = YES;
        [bezierPathRect fill];
        CGContextSetLineWidth(contextRef, 2);
        CGContextSetRGBStrokeColor(contextRef, 27/255.0, 181/255.0, 254/255.0, 1);
        [pickingFieldPath stroke];
        
        CGContextRestoreGState(contextRef);
        self.layer.contentsGravity = kCAGravityCenter;

    }
    
}


-(void)setScanSize:(CGFloat)scanSize{
    
    _scanSize = scanSize;
    
    CGFloat topAndBottomViewH = (screenH - scanSize)/2;
    CGFloat leftAndRightViewW = (screenW - scanSize)/2;
    CGFloat leftAndRightViewH = screenH - (topAndBottomViewH*2);
    
    _sideImageView.frame = CGRectMake((screenW - scanSize)/2, (screenH-scanSize)/2, scanSize, scanSize);
    _topView.frame = CGRectMake(0, 0, screenW,topAndBottomViewH);
    _bottomView.frame = CGRectMake(0, screenH-topAndBottomViewH, screenW, topAndBottomViewH);
    _leftView.frame = CGRectMake(0, topAndBottomViewH, leftAndRightViewW, leftAndRightViewH);
    _rightView.frame = CGRectMake(screenW-leftAndRightViewW, topAndBottomViewH, leftAndRightViewW, leftAndRightViewH);
    
   
}

-(void)setSideImage:(UIImage *)sideImage{
    _sideImage = sideImage;
    _sideImageView.image = _sideImage;
}

-(void)setLineImage:(UIImage *)lineImage{
    _lineImage = lineImage;
    _lineLayer.contents = (id)_lineImage.CGImage;
}

-(void)setLineDuration:(CGFloat)lineDuration{
    _lineDuration = lineDuration;
}

-(void)setAllAroundColor:(UIColor *)allAroundColor{
    _allAroundColor = allAroundColor;
    
    _topView.backgroundColor = allAroundColor;
    _bottomView.backgroundColor = allAroundColor;
    _leftView.backgroundColor = allAroundColor;
    _rightView.backgroundColor = allAroundColor;
}

-(void)setAllAroundAlpha:(CGFloat)allAroundAlpha{
    _allAroundAlpha = allAroundAlpha;
    
    _topView.alpha = allAroundAlpha;
    _bottomView.alpha = allAroundAlpha;
    _leftView.alpha = allAroundAlpha;
    _rightView.alpha = allAroundAlpha;
}


- (void)layoutSubviews
{
    [super layoutSubviews];
    [self setNeedsDisplay];
    
    self.lineLayer.frame = CGRectMake((self.frame.size.width - _scanSize) / 2, (self.frame.size.height - 65*SCALE - _scanSize) / 2, _scanSize, 2);
}

- (void)stopAnimation
{
    [self.lineLayer removeAnimationForKey:@"translationY"];
}

- (void)repetitionAnimation
{
    if (!_lineDuration) {
        _lineDuration = 2;
    }
    CABasicAnimation *basic = [CABasicAnimation animationWithKeyPath:@"transform.translation.y"];
    basic.fromValue = @(0);
    basic.toValue = @(_scanSize);
    basic.duration = _lineDuration;
    basic.repeatCount = NSIntegerMax;
    [self.lineLayer addAnimation:basic forKey:@"translationY"];
}




@end
