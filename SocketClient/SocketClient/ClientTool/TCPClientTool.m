//
//  SocketTool.m
//  SocketClient
//
//  Created by ZD on 2020/5/17.
//  Copyright © 2020 ZD. All rights reserved.
//

#import "TCPClientTool.h"
#import "GCDAsyncSocket.h"

@interface TCPClientTool ()<GCDAsyncSocketDelegate>
@property (nonatomic, strong) GCDAsyncSocket *clientSocket;
@property (nonatomic, strong) NSTimer *heartTimer;
@property (nonatomic, weak) id<SocketToolDelegate> delegate;
@property (nonatomic, assign) BOOL connected;
@property (nonatomic, strong) dispatch_queue_t sockeQueue;
@property (nonatomic, strong) NSMutableData *dataBuffer;
@end

@implementation TCPClientTool

+ (instancetype)shareInstance {
    static TCPClientTool *tool;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        tool = [self new];
        tool.needHeart = YES;
        tool.heartInterval = 5;
    });
    return tool;
}

- (BOOL)connectToHost:(NSString*)host onPort:(uint16_t)port delegate:(id<SocketToolDelegate>)delegate {
    self.delegate = delegate;
    NSError *error = nil;
    [self.clientSocket connectToHost:host onPort:port error:&error];
    if (error) {
        return NO;
    }else {
        return YES;
    }
}

- (void)startHeartTimer {
    [self stopHeartTimer];
    //主线程初始化 Timer
    dispatch_async(dispatch_get_main_queue(), ^{
        self.heartTimer = [NSTimer scheduledTimerWithTimeInterval:self.heartInterval target:self selector:@selector(sendHeartData) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:self.heartTimer forMode:NSRunLoopCommonModes];
    });
}

- (void)stopHeartTimer {
    if (self.heartTimer) {
        [self.heartTimer invalidate];
        self.heartTimer = nil;
    }
}

- (void)sendHeartData {
    char hearBeat[4] = {0xab,0xcd,0x00,0x00};
    NSData *heartData = [NSData dataWithBytes:&hearBeat length:sizeof(hearBeat)];
    [self sendData:heartData];
    NSLog(@"发送心跳");
}

- (void)sendData:(NSData *)contentData {
    NSInteger dataLength = contentData.length;
    NSData *lengthData = [NSData dataWithBytes:&dataLength length:sizeof(dataLength)];
    NSData *headData = [lengthData subdataWithRange:NSMakeRange(0, 4)];
    NSMutableData *data = [NSMutableData dataWithData:headData];
    [data appendData:contentData];
    
    [self.clientSocket writeData:data withTimeout:-1 tag:0];
}

- (void)disconnect {
    if (self.connected) {
        [self.clientSocket disconnect];
    }
}

#pragma mark - GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    self.connected = YES;
    if ([self.delegate respondsToSelector:@selector(socket: status:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate socket:self status:(ConnectStatusConnected)];
        });
    }
    NSLog(@"%@", [NSThread currentThread]);
    [sock readDataWithTimeout:-1 tag:0];
    if (self.needHeart) {
        //开始发送心跳
        [self startHeartTimer];
    }
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    [self.dataBuffer appendData:data];
    while (self.dataBuffer.length >= 4) {
        NSInteger dataLength = 0;
        //获取数据长度
        [[self.dataBuffer subdataWithRange:(NSMakeRange(0, 4))] getBytes:&dataLength length:sizeof(dataLength)];
        if (self.dataBuffer.length >= (dataLength+4)) {
            NSData *realData = [self.dataBuffer subdataWithRange:NSMakeRange(4, dataLength)];
            if ([self.delegate respondsToSelector:@selector(socket: receiveData:)]) {
                [self.delegate socket:self receiveData:realData];
            }
            self.dataBuffer = [[self.dataBuffer subdataWithRange:NSMakeRange(4+dataLength, self.dataBuffer.length-4-dataLength)] mutableCopy];
            
        } else {
            break;
        }
    }
    [sock readDataWithTimeout:-1 tag:0];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(nullable NSError *)err {
    self.connected = FALSE;
    if ([self.delegate respondsToSelector:@selector(socket: status:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
             [self.delegate socket:self status:(ConnectStatusDisconnected)];
        });
    }
    NSLog(@"%@", [NSThread currentThread]);
    [self stopHeartTimer];
}

#pragma mark - Property

- (GCDAsyncSocket *)clientSocket {
    if (!_clientSocket) {
        _clientSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:self.sockeQueue];
//        _clientSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    return _clientSocket;
}

//串行队列进行socket数据读写
- (dispatch_queue_t)sockeQueue {
    if (!_sockeQueue) {
        _sockeQueue = dispatch_queue_create("sockeQueue", DISPATCH_QUEUE_SERIAL);
    }
    return _sockeQueue;
}

- (NSMutableData *)dataBuffer {
    if (!_dataBuffer) {
        _dataBuffer = [NSMutableData data];
    }
    return _dataBuffer;
}

@end
