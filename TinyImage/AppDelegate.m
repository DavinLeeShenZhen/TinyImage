//
//  AppDelegate.m
//  TinyImage
//
//  Created by Larry Emerson on 15/7/24.
//  Copyright (c) 2015年 LarryEmerson. All rights reserved.
//

#import "AppDelegate.h"
#import "MF_Base64Additions.h"
#import "SBJson.h"
#import "Window.h"

@interface AppDelegate () <NSURLConnectionDelegate>

@property (weak) IBOutlet Window *window;

@end

@implementation AppDelegate{
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // 1- 搜索.png文件，并把路径写入待处理文件中
    // 2- 建立连接上传路径图片，并等待上传完成后下载图片数据，最后替换原来文件数据。在数据替换完成后把路径中待处理列表中删除，并保存待处理路径文件。
    // 3- 中途退出时，需要保存现有的待处理列表进度
    // 4- 下一次执行批处理图片减容操作前，先查找是否存在待处理列表，如果存在则继续处理。否则则开始步骤1
    [self.window initData];
} 
- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
