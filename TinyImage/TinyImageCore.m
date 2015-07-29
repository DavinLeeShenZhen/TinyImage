//
//  TinyImageCore.m
//  TinyImage
//
//  Created by Larry Emerson on 15/7/28.
//  Copyright (c) 2015年 LarryEmerson. All rights reserved.
//

#import "TinyImageCore.h"
#import "MF_Base64Additions.h"
#import "SBJson.h"


static NSString *TinyImageUrl=@"https://api.tinify.com/shrink";

@interface TinyImageCore () <NSURLConnectionDelegate>
@end

@implementation TinyImageCore{
    NSString *curFilePath;
    NSString *curFileName;
    id<TinyImageDelegate> delegate;
    BOOL isUploadFinished;
    NSString *TinyImageKey;
}

-(void) setKey:(NSString *) key RootPath:(NSString *) path FileName:(NSString *) fileName Delegate:(id) dele{
    curFilePath=path;
    curFileName=fileName;
    delegate=dele;
    TinyImageKey=key;
    if(delegate){
        [delegate onLog:[NSString stringWithFormat:@"开始处理 %@",fileName]];
    }
    //
    //
    //设置请求路径
    NSURL *URL=[NSURL URLWithString:TinyImageUrl];//不需要传递参数
    //创建请求对象
    NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:URL];//默认为get请求
    request.HTTPMethod=@"POST";//设置请求方法
    //设置请求体
    
    NSString *base64 = [@"api:" stringByAppendingString: TinyImageKey];
    base64 = [base64 stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    base64 = [base64 base64String];
    base64 = [@"Basic " stringByAppendingString:base64];
    [request setValue: base64 forHTTPHeaderField:@"Authorization"];
    request.HTTPBody=[NSData dataWithContentsOfFile:[curFilePath stringByAppendingString:curFileName]];
    
    [[NSURLConnection alloc] initWithRequest:request delegate:self];
    if(delegate){
        [delegate onLog:[NSString stringWithFormat:@"上传 %@ 中...",fileName]];
    }
}

// 服务器接收到请求时
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSLog(@"%s", __FUNCTION__);
}
// 当收到服务器返回的数据时触发, 返回的可能是资源片段
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    if(isUploadFinished){
        if(delegate) {
            [delegate onLog:[NSString stringWithFormat:@"已完成 %@",curFileName]];
            [delegate onDoneWithRootPath:curFilePath fileName:curFileName Data:data];
        }
    }else{
        NSString *response = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSDictionary *dic=[[[SBJsonParser alloc] init] objectWithString:response];
        NSString *outurl=[[dic objectForKey:@"output"] objectForKey:@"url"];
        if(outurl){
            NSURLRequest *curRequest=[[NSURLRequest alloc] initWithURL:[[NSURL alloc] initWithString:outurl]];
            [NSURLConnection connectionWithRequest:curRequest delegate:self];
            if(delegate){
                [delegate onLog:[NSString stringWithFormat:@"下载 %@ 中...",curFileName]];
            }
            isUploadFinished=YES;
        }else{
            if(delegate){
                [delegate onLog:[NSString stringWithFormat:@"!!! 获取 %@ 出错",curFileName]];
                [delegate onFailWithRootPath:curFilePath fileName:curFileName];
            }
        }
    }
    
    
    NSLog(@"%s", __FUNCTION__);
//    NSLog(@"Data %@",data);
}
// 当服务器返回所有数据时触发, 数据返回完毕
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSLog(@"%s", __FUNCTION__);
}
// 请求数据失败时触发
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"%s", __FUNCTION__);
    if(delegate){
        [delegate onFailWithRootPath:curFilePath fileName:curFileName];
    }
}

@end
