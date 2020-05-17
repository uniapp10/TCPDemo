//
//  SocketTool.h
//  SocketClient
//
//  Created by ZD on 2020/5/17.
//  Copyright © 2020 ZD. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class TCPClientTool;

typedef NS_ENUM(NSInteger, ConnectStatus) {
    ConnectStatusConnected    = 0,//链接成功
    ConnectStatusDisconnected       = 1 //断开
};

@protocol SocketToolDelegate <NSObject>

- (void)socket:(TCPClientTool *)tool receiveData:(NSData *)contentData;

- (void)socket:(TCPClientTool *)tool status:(ConnectStatus)status;

@end

@interface TCPClientTool : NSObject

@property (nonatomic, assign) BOOL needHeart;
@property (nonatomic, assign) CGFloat heartInterval;

+ (instancetype)shareInstance;

- (BOOL)connectToHost:(NSString*)host onPort:(uint16_t)port delegate:(id<SocketToolDelegate>)delegate;

- (void)sendData:(NSData *)contentData;

- (void)disconnect;

@end

NS_ASSUME_NONNULL_END
