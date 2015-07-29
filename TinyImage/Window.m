//
//  Window.m
//  TinyImage
//
//  Created by Larry Emerson on 15/7/28.
//  Copyright (c) 2015年 LarryEmerson. All rights reserved.
//

#import "Window.h"
#import "TinyImageCore.h"

@interface Window()<TinyImageDelegate,NSComboBoxDelegate,NSComboBoxDataSource>
@end

@implementation Window{
    NSString *curLogString;
    
    IBOutlet NSTextField *curLog;
    IBOutlet NSButton *pickFolderButton;
    NSMutableArray *curList;
    NSMutableArray *curListCopy;
    NSString *curFolderPath;
    NSString *curListPath;
    NSFileManager *curFileManager;
    IBOutlet NSImageView *curImage;
    int totalCount;
    IBOutlet NSTextField *curProgressNum;
    IBOutlet NSProgressIndicator *curProgress;
    NSTimer *curTimer;
    
    NSUserDefaults *curDefaults; 
    IBOutlet NSTextField *curUsedKeyDisplay;
    NSString *curUsedKey;
    IBOutlet NSComboBox *curSavedKeyComboBox;
    //
    NSMutableArray *curKeyArray; 
}

- (IBAction)onKeyDelete:(id)sender {
    if(curSavedKeyComboBox.stringValue.length==32){
        int index=-1;
        for (int i=0; i<curKeyArray.count; i++) {
            if([[curKeyArray objectAtIndex:i] isEqualToString:curSavedKeyComboBox.stringValue]){
                index=i;
                break;
            }
        }
        curUsedKey=@"";
        if(index>=0){
            [curKeyArray removeObjectAtIndex:index];
            if(curKeyArray.count>0){
                curUsedKey=[curKeyArray objectAtIndex:0];
            }else{
            }
            [curDefaults setObject:[curKeyArray componentsJoinedByString:@"|"] forKey:@"TinyImageKeyArray"];
        } 
        [curSavedKeyComboBox reloadData];
        [self resetCurrentUsedKey];
        [curDefaults setObject:curUsedKey forKey:@"TinyImageKey"];
        [curDefaults synchronize];
    }
}
- (IBAction)onKeyAdd:(id)sender {
    if(curSavedKeyComboBox.stringValue.length==32){
        curUsedKey=curSavedKeyComboBox.stringValue;
        [curDefaults setObject:curUsedKey forKey:@"TinyImageKey"];
        [curDefaults synchronize];
        [self resetCurrentUsedKey];
        BOOL hasKey=NO;
        for (NSString *key in curKeyArray) {
            if([key isEqualToString:curUsedKey]){
                hasKey=YES;
                break;
            }
        }
        if(!hasKey){
            [curKeyArray addObject:curUsedKey];
            [curDefaults setObject:[curKeyArray componentsJoinedByString:@"|"] forKey:@"TinyImageKeyArray"];
        }
    }
}
//
- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox {
    return [curKeyArray count];
}
- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index {
    return [curKeyArray objectAtIndex:index];
}
- (void)comboBoxSelectionDidChange:(NSNotification *)notification{
    if(curSavedKeyComboBox.indexOfSelectedItem<curKeyArray.count){
        curUsedKey=[curKeyArray objectAtIndex:curSavedKeyComboBox.indexOfSelectedItem];
        [curDefaults setObject:curUsedKey forKey:@"TinyImageKey"];
        [curDefaults synchronize];
        [self resetCurrentUsedKey];
    }
}

//
-(void) initData{
    curKeyArray=[[NSMutableArray alloc] init];
    //
    [curSavedKeyComboBox setDelegate:self];
    [curSavedKeyComboBox setDataSource:self];
    
    curLogString=@"";
    curDefaults=[NSUserDefaults standardUserDefaults];
    curUsedKey=[curDefaults objectForKey:@"TinyImageKey"]; 
    if(!curUsedKey||curUsedKey.length==0){
//        curUsedKey=TinyImageKey;
//        [curDefaults setObject:curUsedKey forKey:@"TinyImageKey"];
//        [curDefaults synchronize];
//        [curKeyArray addObject:curUsedKey];
//        [curDefaults setObject:[curKeyArray componentsJoinedByString:@"|"] forKey:@"TinyImageKeyArray"];
        curUsedKey=@"";
    }
    curKeyArray=[[NSMutableArray alloc] initWithArray: [[curDefaults objectForKey:@"TinyImageKeyArray"] componentsSeparatedByString:@"|"]];
    [curSavedKeyComboBox reloadData];
    [self resetCurrentUsedKey];
    [self setOperationStatusAs:NO];
}
-(void) resetCurrentUsedKey{
    [curUsedKeyDisplay setStringValue:[@"当前使用的key：" stringByAppendingString:curUsedKey]];
    [curSavedKeyComboBox setStringValue:curUsedKey];
}
-(void) setOperationStatusAs:(BOOL) isOn{
    [pickFolderButton setHidden:isOn];
    [curProgress setHidden:!isOn];
    [curProgressNum setHidden:!isOn];
}
- (IBAction)onPickFolder:(id)sender {
    [self onLog:@"======================BEGIN====================="];
    curFileManager=[NSFileManager defaultManager];
    
    //
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseDirectories:YES]; //可以打开目录
    [panel setCanChooseFiles:NO]; //不能打开文件(我需要处理一个目录内的所有文件)
    [panel setPrompt:@"确定"];
    [panel beginSheetModalForWindow:self completionHandler:^(NSInteger result) {
        if (result == 1) {
            [self setOperationStatusAs:YES];
            curFolderPath=[panel.URL.absoluteString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            curFolderPath=[curFolderPath substringFromIndex:5];
            [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(scanPathAndFetchImages) userInfo:nil repeats:NO];
        }
    }];
}
-(void) scanPathAndFetchImages{
    [self onLog:[NSString stringWithFormat:@"已选择目录：%@",curFolderPath]];
    //我在console输出这个目录的地址
    curListPath=[curFolderPath stringByAppendingString:@"/TinyImageList"];
    //
    if([curFileManager fileExistsAtPath:curListPath]){
        curList = (NSMutableArray *) [[NSArray alloc] initWithContentsOfFile:curListPath];
        [self onLog:[NSString stringWithFormat:@"已存在待处理图片列表%d条",(int)curList.count]];
    }else{
        curList=[[NSMutableArray alloc] init];
        NSDirectoryEnumerator *direnum = [curFileManager enumeratorAtPath:[curFolderPath stringByExpandingTildeInPath]];
        if(direnum){
            NSString *filename;
            while (filename = [direnum nextObject]) {                   // 遍历字典容器，赋值给字符串filename
                if ([[filename pathExtension] isEqualTo:@"png"]) {      // 如果filename字符串内容匹配jpg后缀，则装入可变数组files
                    [curList addObject:filename];
                    [self onLog:[NSString stringWithFormat:@"添加图片%@到待处理图片列表",filename]];
                }
            }
            [curList writeToFile:curListPath atomically:YES];
        }
    }
    //
    curListCopy=[[NSMutableArray alloc] initWithArray:curList];
    totalCount=(int)curList.count;
    if(totalCount==0){
        [curFileManager removeItemAtPath:curListPath error:NULL];
        [self onLog:@"删除待处理图片列表"];
        [curProgressNum setStringValue:@"%100"];
        [curProgress stopAnimation:self];
        [pickFolderButton setEnabled:YES];
        
    }else{
        for (NSString *path in curList) {
            TinyImageCore *tiny=[[TinyImageCore alloc] init];
            [tiny setKey:curUsedKey RootPath:curFolderPath FileName:path Delegate:self];
        }
        [curProgress startAnimation:self];
        [curProgressNum setStringValue:@"%0"];
    }
}
-(void) appendLogString:(NSString *) log{
//    NSLog(log);
    curLogString=[curLogString stringByAppendingString:log];
    curLogString=[curLogString stringByAppendingString:@"\n"];
    [curLog setStringValue:curLogString];
}
-(void) onLog:(NSString *)log{
    [self appendLogString:log];
}
-(void) writeToFile:(NSTimer *) timer{
    NSDictionary *dic=[timer userInfo];
//    NSData *data= [[dic objectForKey:@"data"] dataUsingEncoding:NSUTF8StringEncoding];
    NSString *path=[dic objectForKey:@"path"];
    NSString *name=[dic objectForKey:@"name"];
//    [data writeToFile:[path stringByAppendingString:name] atomically:YES];

    NSImage *img=[[NSImage alloc] initWithData:[[NSData alloc] initWithContentsOfFile:[path stringByAppendingString:name]]];
    [curImage setImage:img];
    
    [timer invalidate];
}
-(void) onDoneWithRootPath:(NSString *) path fileName:(NSString *) name Data:(NSData *)data {
    NSImage *img=[[NSImage alloc] initWithData:[[NSData alloc] initWithContentsOfFile:[path stringByAppendingString:name]]];
    [curImage setImage:img];
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(writeToFile:) userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:path,@"path",name,@"name",[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding],@"data", nil] repeats:NO];
    [data writeToFile:[path stringByAppendingString:name] atomically:YES];
    int index=-1;
    for (int i=0; i<curListCopy.count; i++) {
        if([name isEqualToString:[curListCopy objectAtIndex:i]]){
            index=i;
            break;
        }
    }
    if(curListCopy.count>index){
        [curListCopy removeObjectAtIndex:index];
        //
        index=-1;
        for (int i=0; i<curList.count; i++) {
            if([name isEqualToString:[curList objectAtIndex:i]]){
                index=i;
                break;
            }
        }
        [curList removeObjectAtIndex:index];
        //
        int count=(int)(100.0*(totalCount-curList.count)/totalCount);
        [curProgressNum setStringValue:[NSString stringWithFormat:@"%%%d",count]];
        [curList writeToFile:curListPath atomically:YES];
        [self onLog:[NSString stringWithFormat:@"更新待处理图片列表为%d条",(int)curList.count]];
    }
    if(curListCopy.count==0){
        [self onDone];
    }
}
-(void) onFailWithRootPath:(NSString *) path fileName:(NSString *) name{
    int index=-1;
    for (int i=0; i<curListCopy.count; i++) {
        if([name isEqualToString:[curListCopy objectAtIndex:i]]){
            index=i;
            break;
        }
    }
    if(curListCopy.count>index){
        [curListCopy removeObjectAtIndex:index];
    }
    if(curListCopy.count==0){
        [self onDone];
    }
}
-(void) onDone{
    [curProgressNum setStringValue:@"%100"];
    [curProgress stopAnimation:self];
    [self setOperationStatusAs:NO];
    if(curList.count==0){
        [curFileManager removeItemAtPath:curListPath error:NULL];
        [self onLog:@"待处理图片列表全部完成！删除待处理图片列表！"];
    }
    [self onLog:@"======================END====================="];
}
@end
