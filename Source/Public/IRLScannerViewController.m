//
//  IRLScannerViewController
//
//  Created by Denis Martin on 28/06/2015.
//  Copyright (c) 2015 Denis Martin. All rights reserved.
//

#import "IRLScannerViewController.h"
#import "IRLCameraView.h"

@interface IRLScannerViewController () <IRLCameraViewProtocol>

@property (weak)                        id<IRLScannerViewControllerDelegate> camera_PrivateDelegate;

@property (weak, nonatomic, readwrite)  IBOutlet UIButton       *flash_toggle;
@property (weak, nonatomic, readwrite)  IBOutlet UIButton       *contrast_type;
@property (weak, nonatomic, readwrite)  IBOutlet UIButton       *detect_toggle;

@property (weak, nonatomic)             IBOutlet UIView         *adjust_bar;
@property (weak, nonatomic)             IBOutlet UILabel        *titleLabel;

@property (weak, nonatomic)             IBOutlet UIImageView *focusIndicator;

@property (weak, nonatomic)             IBOutlet IRLCameraView  *cameraView;

- (IBAction)captureButton:(id)sender;

@property (readwrite, nonatomic)        IRLScannerViewTypeN                   cameraViewType;

@property (readwrite, nonatomic)        IRLScannerDetectorType               dectorType;

@end

@implementation IRLScannerViewController

#pragma mark - Initializer

+ (instancetype)standardCameraViewWithDelegate:(id<IRLScannerViewControllerDelegate>)delegate {
    return [self cameraViewWithDefaultType:IRLScannerViewTypeNBlackAndWhite defaultDetectorType:IRLScannerDetectorTypeAccuracy withDelegate:delegate];
}

+ (instancetype)cameraViewWithDefaultType:(IRLScannerViewTypeN)type
                      defaultDetectorType:(IRLScannerDetectorType)detector
                             withDelegate:(id<IRLScannerViewControllerDelegate>)delegate {
    
    NSAssert(delegate != nil, @"You must provide a delegate");
    
    IRLScannerViewController*    cameraView = [[UIStoryboard storyboardWithName:@"IRLCamera" bundle:nil] instantiateInitialViewController];
    cameraView.cameraViewType = type;
    cameraView.dectorType = detector;
    cameraView.camera_PrivateDelegate = delegate;
    cameraView.showCountrols = YES;
    cameraView.detectionOverlayColor = [UIColor redColor];
    return cameraView;
}

#pragma mark - Setters

- (void)setCameraViewType:(IRLScannerViewTypeN)cameraViewType {
    _cameraViewType = cameraViewType;
    [self.cameraView setCameraViewType:cameraViewType];
}

- (void)setDectorType:(IRLScannerDetectorType)dectorType {
    _dectorType = dectorType;
    [self.cameraView setDectorType:dectorType];
}

- (void)setShowCountrols:(BOOL)showCountrols {
    _showCountrols = showCountrols;
    [self updateTitleLabel:nil];
}

- (void)setShowAutoFocusWhiteRectangle:(BOOL)showAutoFocusWhiteRectangle {
    _showAutoFocusWhiteRectangle = showAutoFocusWhiteRectangle;
    [self.cameraView setEnableShowAutoFocus:showAutoFocusWhiteRectangle];
}

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.cameraView setupCameraView];
    [self.cameraView setDelegate:self];
    [self.cameraView setOverlayColor:self.detectionOverlayColor];
    [self.cameraView setDectorType:self.dectorType];
    [self.cameraView setCameraViewType:self.cameraViewType];
    [self.cameraView setEnableShowAutoFocus:self.showAutoFocusWhiteRectangle];

    if (![self.cameraView hasFlash]){
        self.flash_toggle.enabled = NO;
        self.flash_toggle.hidden = YES;
    }
    
    [self.cameraView setEnableBorderDetection:YES];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateTitleLabel:nil];
    
    self.detect_toggle.selected     =  self.cameraView.dectorType       == IRLScannerDetectorTypePerformance;
    self.contrast_type.selected     =  self.cameraView.cameraViewType   == IRLScannerViewTypeNBlackAndWhite;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.cameraView start];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.cameraView stop];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (BOOL)shouldAutorotate{
    return NO;
}

#pragma mark - CameraVC Actions

- (IBAction)detctingQualityToggle:(id)sender {
    
    [self setDectorType:(self.dectorType == IRLScannerDetectorTypeAccuracy) ?
        IRLScannerDetectorTypePerformance : IRLScannerDetectorTypeAccuracy];

    [self updateTitleLabel:nil];
}

- (IBAction)filterToggle:(id)sender {
    
    switch (self.cameraViewType) {
        case IRLScannerViewTypeNBlackAndWhite:
            [self setCameraViewType:IRLScannerViewTypeNNormal];
            break;
        case IRLScannerViewTypeNNormal:
            [self setCameraViewType:IRLScannerViewTypeNUltraContrast];
            break;
        case IRLScannerViewTypeNUltraContrast:
            [self setCameraViewType:IRLScannerViewTypeNBlackAndWhite];
            break;
        default:
            break;
    }

    [self updateTitleLabel:nil];
}

- (IBAction)torchToggle:(id)sender {
    
    BOOL enable = !self.cameraView.isTorchEnabled;
    if ([sender isKindOfClass:[UIButton class]]) { [sender setSelected:enable]; }
    self.cameraView.enableTorch = enable;
}

#pragma mark - UI animations

- (void)updateTitleLabel:(NSString*)text {
    
    // CShow or not Controlle
    [self.adjust_bar setHidden:!self.showCountrols];
    
    // Update Button first
    BOOL detectorType = self.dectorType == IRLScannerDetectorTypePerformance;
    [self.detect_toggle setSelected:detectorType];
    
    [self.contrast_type setSelected:NO];
    [self.contrast_type setHighlighted:NO];

    switch (self.cameraViewType) {
        case IRLScannerViewTypeNBlackAndWhite:
            [self.contrast_type setSelected:YES];
            break;
        case IRLScannerViewTypeNNormal:
            break;
        case IRLScannerViewTypeNUltraContrast:
            [self.contrast_type setHighlighted:YES];
            break;
        default:
            break;
    }

    // Update Text
    if (!text && [self.camera_PrivateDelegate respondsToSelector:@selector(cameraViewWillUpdateTitleLabel:)]) {
        text = [self.camera_PrivateDelegate cameraViewWillUpdateTitleLabel:self];
    }
    
    if (text.length == 0 || !text) {
        self.titleLabel.hidden = YES;
        return;
    }
    
    self.titleLabel.hidden = NO;
    if ([text isEqualToString:self.titleLabel.text]) {
        return;
    }
    
    CATransition *animation = [CATransition animation];
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    animation.type = kCATransitionPush;
    animation.subtype = kCATransitionFromTop;
    animation.duration = 0.1;
    [self.titleLabel.layer addAnimation:animation forKey:@"kCATransitionFade"];
    self.titleLabel.text = text;
}

- (void)changeButton:(UIButton *)button targetTitle:(NSString *)title toStateEnabled:(BOOL)enabled {
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:(enabled) ? [UIColor colorWithRed:1 green:0.81 blue:0 alpha:1] : [UIColor whiteColor] forState:UIControlStateNormal];
}

#pragma mark - CameraVC Capture Image

- (IBAction)captureButton:(id)sender {
    
    // Getting a Preview
    UIImageView *imgView = [[UIImageView alloc] initWithImage:[self.cameraView latestCorrectedUIImage]];
    imgView.frame = self.cameraView.frame;
    imgView.contentMode = UIViewContentModeScaleAspectFit;
    imgView.backgroundColor = [UIColor clearColor];
    imgView.opaque = NO;
    imgView.alpha = 0.0f;
    imgView.transform = CGAffineTransformMakeScale(0.4f, 0.4f);
    [self.view addSubview:imgView];
    
    [UIView animateWithDuration:0.8f delay:0.5f usingSpringWithDamping:0.3f initialSpringVelocity:0.7f options:UIViewAnimationOptionCurveEaseInOut animations:^{
        imgView.transform = CGAffineTransformMakeScale(0.9f, 0.9f);
        imgView.alpha = 1.0f;

    } completion:nil];
    
    // Some Feedback to the User
    UIView *white = [[UIView alloc] initWithFrame:self.view.frame];
    [white setBackgroundColor:[UIColor whiteColor]];
    white.alpha = 0.0f;
    [self.view addSubview:white];
    [UIView animateWithDuration:0.5f animations:^{
        white.alpha = 0.9f;
        white.alpha = 0.0f;

    } completion:^(BOOL finished) {
        [white removeFromSuperview];
    }];
    
    // the Actual Capture
    [self.cameraView captureImageWithCompletionHander:^(id data)
    {
        UIImage *image = ([data isKindOfClass:[NSData class]]) ? [UIImage imageWithData:data] : data;
        if (self.camera_PrivateDelegate){
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 *NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [self.camera_PrivateDelegate pageSnapped:image from:self];
            });
        }
    }];
    
}

#pragma mark - IRLCameraViewProtocol

-(void)didLostConfidence:(IRLCameraView*)view {
    
    __weak  typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[weakSelf adjust_bar] setHidden:NO];
        [weakSelf updateTitleLabel:nil];
        [[weakSelf titleLabel] setBackgroundColor:[UIColor blackColor]];
    });

}

-(void)didDetectRectangle:(IRLCameraView*)view withConfidence:(NSUInteger)confidence {
    
    __weak  typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (confidence > view.minimumConfidenceForFullDetection) {
            
            NSInteger range     = view.maximumConfidenceForFullDetection - view.minimumConfidenceForFullDetection;
            CGFloat   delta     = 4.0f / range;
            NSInteger current   = view.maximumConfidenceForFullDetection - confidence;
            NSInteger value     = (range - range / current) * delta;
            
            [[weakSelf adjust_bar] setHidden:YES];
            if (value == 0) {
                [weakSelf.titleLabel setHidden:YES];
                
            } else {
                [weakSelf.titleLabel setHidden:NO];
                [weakSelf updateTitleLabel:[NSString stringWithFormat: @"... %ld ...", (long)value ]];
            }
            [[weakSelf titleLabel] setBackgroundColor:[[UIColor blackColor] colorWithAlphaComponent:0.5f]];
            
        } else {
            
            [[weakSelf adjust_bar] setHidden:NO];
            [weakSelf updateTitleLabel:nil];
            [[weakSelf titleLabel] setBackgroundColor:[UIColor blackColor]];
        }
    });

}

-(void)didGainFullDetectionConfidence:(IRLCameraView*)view {
    
    __weak  typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[weakSelf adjust_bar] setHidden:YES];
        [weakSelf.titleLabel setHidden:YES];
        [[weakSelf titleLabel] setBackgroundColor:[[UIColor blackColor] colorWithAlphaComponent:0.5f]];
    });
    
    [self captureButton:view];

}

@end
