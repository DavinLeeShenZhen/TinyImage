//
//  TinyImageCore.h
//  TinyImage
//
//  Created by Larry Emerson on 15/7/28.
//  Copyright (c) 2015年 LarryEmerson. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TinyImageDelegate <NSObject>

-(void) onDoneWithRootPath:(NSString *) path fileName:(NSString *) name Data:(NSData *) data;
-(void) onLog:(NSString *) log;
-(void) onFailWithRootPath:(NSString *) path fileName:(NSString *) name;

@end
@interface TinyImageCore : NSObject
-(void) setKey:(NSString *) key RootPath:(NSString *) path FileName:(NSString *) fileName Delegate:(id) dele;
@end
