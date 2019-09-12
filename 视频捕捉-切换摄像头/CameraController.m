//
//  CameraController.m
//  视频捕捉-切换摄像头
//
//  Created by 柯木超 on 2019/9/6.
//  Copyright © 2019 柯木超. All rights reserved.
//

#import "CameraController.h"
#import "NSFileManager+THAdditions.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <UIKit/UIKit.h>
@interface CameraController()
@property (strong, nonatomic) NSURL *outputURL;
@property (assign, nonatomic) NSUInteger cameraCount; // 当前设备数量
@property (assign, nonatomic) BOOL canSwitchCamera; // 能否切换摄像头
@property (strong, nonatomic) AVCaptureDeviceInput *activeVideoInput;// 当前正在使用的摄像头的输入
@property (strong, nonatomic) AVCaptureDevice *activeCamera;// 当前正在使用的摄像头的输入
@property (strong, nonatomic) dispatch_queue_t videoQueue; //视频队列
@property (strong, nonatomic) AVCaptureMovieFileOutput *movieOutput;
@property (strong, nonatomic) AVCapturePhotoOutput *imageOutput;
@property (strong, nonatomic) AVCaptureStillImageOutput *stillImageOutput;

@end

@implementation CameraController

-(void)setupSession {
    // 创建secssion
    self.captureSession = [[AVCaptureSession alloc]init];
    
    /*
     AVCaptureSessionPresetHigh
     AVCaptureSessionPresetMedium
     AVCaptureSessionPresetLow
     AVCaptureSessionPreset640x480
     AVCaptureSessionPreset1280x720
     AVCaptureSessionPresetPhoto
     */
    //设置图像的分辨率
    self.captureSession.sessionPreset = AVCaptureSessionPresetHigh;
    
    // 1、添加device 拿到默认视频捕捉设备 iOS系统返回后置摄像头
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    // 2、给device封装 AVCaptureDeviceInput
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    self.activeVideoInput = deviceInput;
    // 3、捕捉设备输出
    //判断videoInput是否有效
    if (deviceInput){
        if([self.captureSession canAddInput:deviceInput]) {
            [self.captureSession addInput:deviceInput];
        }
    }
    
    // 5、视频输出
    self.movieOutput = [[AVCaptureMovieFileOutput alloc]init];
    if([self.captureSession canAddOutput:self.movieOutput]) {
        [self.captureSession addOutput:self.movieOutput];
    }
    
    //6、静态图片输出
    if (@available(iOS 10.0, *)) {
        self.imageOutput = [[AVCapturePhotoOutput alloc]init];
        //输出连接 判断是否可用，可用则添加到输出连接中去
        if ([self.captureSession canAddOutput:self.imageOutput])
        {
            [self.captureSession addOutput:self.imageOutput];
        }
    }else {
        //AVCaptureStillImageOutput 实例 从摄像头捕捉静态图片
        self.stillImageOutput = [[AVCaptureStillImageOutput alloc]init];
        //配置字典：希望捕捉到JPEG格式的图片
        self.stillImageOutput.outputSettings = @{AVVideoCodecKey:AVVideoCodecTypeJPEG};
        if ([self.captureSession canAddOutput:self.stillImageOutput])
        {
            [self.captureSession addOutput:self.stillImageOutput];
        }
    }

    self.videoQueue = dispatch_queue_create("cc.VideoQueue", NULL);
    //使用同步调用会损耗一定的时间，则用异步的方式处理
    dispatch_async(self.videoQueue, ^{
        [self.captureSession startRunning];
    });
}

// 从流中获取照片
-(void)getPhoto {
    // 拍照
    if (@available(iOS 10.0, *)) {
        AVCapturePhotoOutput * output = (AVCapturePhotoOutput *)self.imageOutput;
        AVCapturePhotoSettings * settings = [AVCapturePhotoSettings photoSettings];
        [output capturePhotoWithSettings:settings delegate:self];
    }else{
        AVCaptureStillImageOutput * stillImageOutput = (AVCaptureStillImageOutput *)self.stillImageOutput;
        //从 AVCaptureStillImageOutput 中取得 AVCaptureConnection
        AVCaptureConnection *connection = [stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
        [stillImageOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:^(CMSampleBufferRef  _Nullable imageDataSampleBuffer, NSError * _Nullable error) {
            if (imageDataSampleBuffer != nil) {
                NSData * data = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                UIImage *image = [[UIImage alloc]initWithData:data];
                //重点：捕捉图片成功后，将图片传递出去
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
            }
        }];
    }
    
}

-(void)startRecording {
    self.outputURL = [self uniqueURL];
    NSLog(@"outputURL=%@",self.outputURL);
    //在捕捉输出上调用方法 参数1:录制保存路径  参数2:代理
    [self.movieOutput startRecordingToOutputFileURL: self.outputURL  recordingDelegate:self];
}

-(void)stopRecording {
     [self.movieOutput stopRecording];
}

-(NSUInteger)cameraCount {
    return [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count];
}

-(void)tappedToFocusAtPoint:(CGPoint)point {
    //[self.activeCamera isFocusPointOfInterestSupported] 是否支持对焦 iPhone6以上才支持
    //[self.activeCamera isFocusPointOfInterestSupported] 是否支持自动对焦模式
    NSLog(@"对焦%f",point.x);
    NSLog(@"对焦%f",point.y);
    if ([self.activeCamera isFocusPointOfInterestSupported] && [self.activeCamera isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        // 因为设备有多个，所以需要锁定
        if([self.activeCamera lockForConfiguration:nil]){
          
            // 设置聚焦位置
            self.activeCamera.focusPointOfInterest = point;
            // 设置对焦模式
            self.activeCamera.focusMode = AVCaptureFocusModeAutoFocus;
            
            // 释放锁
            [self.activeCamera unlockForConfiguration];
        }
    }
}

-(AVCaptureDevice *)activeCamera {
    return self.activeVideoInput.device;
}

-(BOOL)canSwitchCamera {
    return [self cameraCount] > 1;
}

-(void)changeCamera {
    if ([self canSwitchCamera]) {
//        [self.movieOutput pauseRecording];
        // 如果当前是后置摄像头，就便利设备，找到前置摄像头，进行切换
        if (self.activeCamera.position == AVCaptureDevicePositionBack) {
            //获取可用视频设备
            NSArray *devicess = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
            //遍历可用的视频设备 并返回position 参数值
            for (AVCaptureDevice *device in devicess)
            {
                if (device.position == AVCaptureDevicePositionFront) {
                    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
                    // 开始配置
                    if (deviceInput){
                        [self.captureSession beginConfiguration];
                        [self.captureSession removeInput:self.activeVideoInput];
                        [self.captureSession setSessionPreset:AVCaptureSessionPresetHigh];
                        if([self.captureSession canAddInput:deviceInput]){
                            [self.captureSession addInput:deviceInput];
                            self.activeVideoInput = deviceInput;
                        }else {
                            [self.captureSession addInput:self.activeVideoInput];
                        }
                        [self.captureSession commitConfiguration];
                    }
                }
            }
        }else {
            // 如果当前是前置摄像头，就便利设备，找到后置摄像头，进行切换
            //获取可用视频设备
            NSArray *devicess = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
            //遍历可用的视频设备 并返回 AVCaptureDevicePositionBack
            for (AVCaptureDevice *device in devicess)
            {
                if (device.position == AVCaptureDevicePositionBack) {
                    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
                    // 开始配置
                    if (deviceInput){
                        [self.captureSession beginConfiguration];
                        [self.captureSession removeInput:self.activeVideoInput];
                        [self.captureSession setSessionPreset:AVCaptureSessionPresetHigh];
                        if([self.captureSession canAddInput:deviceInput]){
                            [self.captureSession addInput:deviceInput];
                            self.activeVideoInput = deviceInput;
                        }else {
                            [self.captureSession addInput:self.activeVideoInput];
                        }
                        [self.captureSession commitConfiguration];
                    }
                }
            }
        }
    }
}


//写入视频唯一文件系统URL
- (NSURL *)uniqueURL {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    //temporaryDirectoryWithTemplateString  可以将文件写入的目的创建一个唯一命名的目录；
    NSString *dirPath = [fileManager temporaryDirectoryWithTemplateString:@"kamera.XXXXXX"];
    
    if (dirPath) {
        
        NSString *filePath = [dirPath stringByAppendingPathComponent:@"kamera_movie.mov"];
        return  [NSURL fileURLWithPath:filePath];
    }
    return nil;
}

#pragma AVCaptureFileOutputRecordingDelegate
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput
didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL
      fromConnections:(NSArray *)connections
                error:(NSError *)error {
     NSLog(@"录制完成");
    UISaveVideoAtPathToSavedPhotosAlbum([outputFileURL path], nil, nil, nil);
}

#pragma mark - 视频输出代理
-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections{
    NSLog(@"开始录制...");
}

#pragma mark AVCapturePhotoCaptureDelegate
- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(NSError *)error {
    if (error) {
        NSLog(@"获取图片错误 --- %@",error.localizedDescription);
    }
    if (photo) {
        if (@available(iOS 11.0, *)) {
            
            CGImageRef cgImage = [photo CGImageRepresentation];
            UIImage * image = [UIImage imageWithCGImage:cgImage];
            NSLog(@"获取图片成功 --- %@",image);
            
            //前置摄像头拍照会旋转180解决办法
            if (self.activeVideoInput.device.position == AVCaptureDevicePositionFront) {
                UIImageOrientation imgOrientation = UIImageOrientationLeftMirrored;
                image = [[UIImage alloc]initWithCGImage:cgImage scale:1.0f orientation:imgOrientation];
            }else {
                UIImageOrientation imgOrientation = UIImageOrientationRight;
                image = [[UIImage alloc]initWithCGImage:cgImage scale:1.0f orientation:imgOrientation];
            }
            //重新画一张图片(将时间/个人信息/地址信息画上去)
//            self.image = [self drawMarkImage:image];
            
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
        } else {
            NSLog(@"不是走这个代理方法");
        }
    }
}

@end
