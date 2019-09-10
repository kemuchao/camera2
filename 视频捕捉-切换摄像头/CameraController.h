//
//  CameraController.h
//  视频捕捉-切换摄像头
//
//  Created by 柯木超 on 2019/9/6.
//  Copyright © 2019 柯木超. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN
/**
 * 其实这就是一个统一管理相机属性的类
 * 包括:输入，输出，session会话
 */
@interface CameraController : NSObject <AVCaptureFileOutputRecordingDelegate>

@property (strong, nonatomic) AVCaptureSession *captureSession;// 捕捉会话

// 配置回话信息
- (void)setupSession;

// 开始录制
- (void)startRecording;

//停止录制
- (void)stopRecording;

// 切换摄像头
- (void)changeCamera;

//聚焦
- (void)tappedToFocusAtPoint:(CGPoint)point;

@end

NS_ASSUME_NONNULL_END
