//
//  NSFileManager+THAdditions.h
//  摄像机画面的捕捉和预览
//
//  Created by 柯木超 on 2019/9/6.
//  Copyright © 2019 柯木超. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSFileManager (THAdditions)

- (NSString *)temporaryDirectoryWithTemplateString:(NSString *)templateString;
@end

NS_ASSUME_NONNULL_END
