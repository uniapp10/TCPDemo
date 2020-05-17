//
//  TCPServerTool.h
//  SocketServer
//
//  Created by ZD on 2020/5/17.
//  Copyright © 2020 ZD. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class TCPServerTool;

typedef NS_ENUM(NSInteger, ConnectStatus) {
    ConnectStatusConnected    = 0,//链接成功
    ConnectStatusDisconnected = 1 //断开
};

@protocol TCPServerToolDelegate <NSObject>

- (void)socket:(TCPServerTool *)tool receiveData:(NSData *)contentData;

- (void)socket:(TCPServerTool *)tool status:(ConnectStatus)status;

@end
@interface TCPServerTool : NSObject

@property (nonatomic, strong) NSMutableDictionary *clientDict;

+ (instancetype)shareInstance;

- (BOOL)listenOnPort:(uint16_t)port delegate:(id<TCPServerToolDelegate>)delegate;

- (void)sendData:(NSData *)contentData to:(NSString *)client;

- (void)disconnect:(NSString *)client;

- (void)stopCheckThread;

@end

NS_ASSUME_NONNULL_END
