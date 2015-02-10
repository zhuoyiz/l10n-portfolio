//
//  NSFileManager+DirectoryInfo.m
//  FileSystemView
//
//  Created by Nathanial Woolls on 10/18/12.
//

// This code is distributed under the terms and conditions of the MIT license.

// Copyright (c) 2012 Nathanial Woolls
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "NSFileManager+DirectoryInfo.h"

@implementation NSFileManager (DirectoryInfo)

+ (void)subFileCount:(long*)fileCount andSubFileSize:(long*)fileSize forDirectory:(NSString*)filePath {
    
    NSArray *subpaths = [[self defaultManager] subpathsOfDirectoryAtPath:filePath error:nil];
    
    *fileCount = 0;
    *fileSize = 0;
    
    for (NSString *subpath in subpaths) {
        
        NSString *fullPath = [filePath stringByAppendingPathComponent:subpath];
        
        NSDictionary *fileAttributes = [[self defaultManager] attributesOfItemAtPath:fullPath error:nil];
        NSNumber *fileSizeNumber = fileAttributes[NSFileSize];
        
        *fileSize = *fileSize + [fileSizeNumber longValue];
        
        BOOL isDirectory;
        [[self defaultManager] fileExistsAtPath:fullPath isDirectory:&isDirectory];
        if (!isDirectory) {
            *fileCount = *fileCount + 1;
        }
    }
    
}

@end
