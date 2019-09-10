//
//  NSFileManager+THAdditions.m
//  摄像机画面的捕捉和预览
//
//  Created by 柯木超 on 2019/9/6.
//  Copyright © 2019 柯木超. All rights reserved.
//

#import "NSFileManager+THAdditions.h"

@implementation NSFileManager (THAdditions)

- (NSString *)temporaryDirectoryWithTemplateString:(NSString *)templateString {
    
    NSString *mkdTemplate =
    [NSTemporaryDirectory() stringByAppendingPathComponent:templateString];
    
    const char *templateCString = [mkdTemplate fileSystemRepresentation];
    char *buffer = (char *)malloc(strlen(templateCString) + 1);
    strcpy(buffer, templateCString);
    
    NSString *directoryPath = nil;
    
    char *result = mkdtemp(buffer);
    if (result) {
        directoryPath = [self stringWithFileSystemRepresentation:buffer
                                                          length:strlen(result)];
    }
    free(buffer);
    return directoryPath;
}

@end
