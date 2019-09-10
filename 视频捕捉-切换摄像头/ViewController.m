//
//  ViewController.m
//  视频捕捉-切换摄像头
//
//  Created by 柯木超 on 2019/9/6.
//  Copyright © 2019 柯木超. All rights reserved.
//

#import "ViewController.h"
#import "PreviewView.h"
#import "CameraController.h"

@interface ViewController ()<THPreviewViewDelegate>
@property (strong, nonatomic) PreviewView *previewView;
@property (strong, nonatomic) CameraController *cameraController;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.cameraController = [[CameraController alloc]init];
    [self.cameraController setupSession];
    self.previewView = [[PreviewView alloc]initWithFrame:self.view.bounds];
    [self.previewView setSession:self.cameraController.captureSession];
    self.previewView.delegate = self;
    [self.view addSubview:self.previewView];
    
    UIButton *button = [[UIButton alloc]initWithFrame:CGRectMake(60, 40, 80, 40)];
    [button setTitle:@"开始录制" forState:UIControlStateNormal];
    [self.view addSubview:button];
    [button addTarget:self action:@selector(stopAction:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *button1 = [[UIButton alloc]initWithFrame:CGRectMake(180, 40, 60, 40)];
    [button1 setTitle:@"切换摄像头" forState:UIControlStateNormal];
    [self.view addSubview:button1];
    [button1 addTarget:self action:@selector(changeAction) forControlEvents:UIControlEventTouchUpInside];
}

-(void)changeAction {
    [self.cameraController changeCamera];
}

-(void)stopAction:(UIButton *)button {
    if([button.titleLabel.text isEqualToString:@"开始录制"]) {
        [self.cameraController startRecording];
        [button setTitle:@"停止录制" forState:UIControlStateNormal];
    }else {
        [self.cameraController stopRecording];
        [button setTitle:@"开始录制" forState:UIControlStateNormal];
    }
}


#pragma THPreviewViewDelegate
-(void)tappedToFocusAtPoint:(CGPoint)point {
    NSLog(@"point x===%f",point.x);
    NSLog(@"point y===%f",point.y);
    [self.cameraController tappedToFocusAtPoint:point];
}


@end
