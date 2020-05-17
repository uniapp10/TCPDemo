//
//  TCPServerTool.m
//  SocketServer
//
//  Created by ZD on 2020/5/17.
//  Copyright © 2020 ZD. All rights reserved.
//

#import "TCPServerTool.h"
#import "GCDAsyncSocket.h"

@interface TCPServerTool ()<GCDAsyncSocketDelegate>

@property (nonatomic, strong) GCDAsyncSocket *serverSocket;
@property (nonatomic, strong) NSMutableDictionary *heartDict;
@property (nonatomic, strong) NSMutableData *dataBuffer;
@property (nonatomic, strong) NSThread *checkThread;
@property (nonatomic, weak) id<TCPServerToolDelegate> delegate;

@end

@implementation TCPServerTool

+ (instancetype)shareInstance {
    static TCPServerTool *tool;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        tool = [self new];
    });
    return tool;
}

- (BOOL)listenOnPort:(uint16_t)port delegate:(id<TCPServerToolDelegate>)delegate {
    self.delegate = delegate;
    NSError *error;
    BOOL result = [self.serverSocket acceptOnPort:port error:&error];
    if (result) {
        return YES;
    }else {
        return NO;
    }
}

- (void)sendData:(NSData *)contentData to:(NSString *)client {
    GCDAsyncSocket *socket = self.clientDict[client];
    if (!socket) {
        return;
    }
    NSInteger dataLength = contentData.length;
    NSData *lengthData = [NSData dataWithBytes:&dataLength length:sizeof(dataLength)];
    NSData *headData = [lengthData subdataWithRange:NSMakeRange(0, 4)];
    NSMutableData *data = [NSMutableData dataWithData:headData];
    [data appendData:contentData];
    
    [socket writeData:data withTimeout:-1 tag:0];
}

- (void)disconnect:(NSString *)client {
    GCDAsyncSocket *socket = self.clientDict[client];
    if (socket) {
        [socket disconnect];
        self.clientDict[client] = nil;
    }
}

- (void)checkClientOnline{
    
    @autoreleasepool {
        [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(checkClient) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] run];
    }
}

- (void)checkClient{
    NSArray *allValues = [self.clientDict allValues];
    if (allValues.count == 0) {
        return;
    }
    NSDate *date = [NSDate date];
    NSDictionary *tempDic = [self.clientDict copy];
    [tempDic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, GCDAsyncSocket *obj, BOOL * _Nonnull stop) {
        if ([date timeIntervalSinceDate:self.heartDict[obj.connectedHost]] > 10) {
            self.clientDict[key] = nil;
        }
    }];
}

- (void)stopCheckThread {
    [self.checkThread cancel];
    self.checkThread = nil;
}

#pragma mark - GCDAsyncSocketDelegate
- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
//    NSLog(@"收到链接:%@: %d", newSocket.localAddress, newSocket.localPort);
    self.clientDict[newSocket.connectedHost] = newSocket;
    [self startCheckThread];
    if ([self.delegate respondsToSelector:@selector(socket: status:)]) {
        [self.delegate socket:self status:(ConnectStatusConnected)];
    }
    [newSocket readDataWithTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    [self.dataBuffer appendData:data];
    
    while (self.dataBuffer.length >= 4) {
        NSInteger dataLength = 0;
        //获取数据长度
        [[self.dataBuffer subdataWithRange:(NSMakeRange(0, 4))] getBytes:&dataLength length:sizeof(dataLength)];
        if (self.dataBuffer.length >= (dataLength+4)) {
            NSData *realData = [self.dataBuffer subdataWithRange:NSMakeRange(4, dataLength)];
            
            char hearBeat[4] = {0xab,0xcd,0x00,0x00};
            NSData *heartData = [NSData dataWithBytes:&hearBeat length:sizeof(hearBeat)];
            if ([realData isEqualToData:heartData]) {
                NSLog(@"收到心跳包: %@", sock.connectedHost);
                self.heartDict[sock.connectedHost] = [NSDate date];
            } else {
                if ([self.delegate respondsToSelector:@selector(socket: receiveData:)]) {
                    [self.delegate socket:self receiveData:realData];
                }
            }
            self.dataBuffer = [[self.dataBuffer subdataWithRange:NSMakeRange(4+dataLength, self.dataBuffer.length-4-dataLength)] mutableCopy];
            
        } else {
            break;
        }
    }
        
    [sock readDataWithTimeout:-1 tag:0];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(nullable NSError *)err {
    NSLog(@"断开链接: %@; error: %@", sock.connectedHost, err);
    if ([self.delegate respondsToSelector:@selector(socket: status:)]) {
        [self.delegate socket:self status:(ConnectStatusDisconnected)];
    }
}

#pragma mark - Property

- (GCDAsyncSocket *)serverSocket {
    if (!_serverSocket) {
        _serverSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    return _serverSocket;
}

- (NSMutableDictionary *)clientDict {
    if (!_clientDict) {
        _clientDict = [NSMutableDictionary dictionary];
    }
    return _clientDict;
}

- (NSMutableDictionary *)heartDict {
    if (!_heartDict) {
        _heartDict = [NSMutableDictionary dictionary];
    }
    return _heartDict;
}


- (void)startCheckThread {
    if (!_checkThread) {
        _checkThread = [[NSThread alloc] initWithTarget:self selector:@selector(checkClientOnline) object:nil];
        [_checkThread start];
    }
}

- (NSMutableData *)dataBuffer {
    if (!_dataBuffer) {
        _dataBuffer = [NSMutableData data];
    }
    return _dataBuffer;
}


@end
