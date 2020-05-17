# TCPDemo
App开发中当遇到行情价格、聊天场景中, 为了让消息及时到达, App 端往往采用 Socket 的方式和服务器实现长连接. 服务器最常见的就是部署在云端,  从根本上来说就是一台主机或者虚拟机. 从互联网的组成结构来看, 任何一个节点上的计算机, 都可以作为服务器来使用. iPhone 智能手机作为连接在网络上的硬件, 从理论上来说是可以作为服务器使用的. 

对于上面所述, 以前只是感性上的调侃, 这两天查找资料, 竟然发现了早就有大神实现了该功能: [CocoaAsyncSocket](https://github.com/robbiehanson/CocoaAsyncSocket) , 赶快下载下来体验一番.

##### 1 Socket 
`Socket` 翻译成中文称为"套接字", 有人将 Socket 等价于 TCP/IP, 个人认为这样不是太准确, 因为使用 Socket 还可以实现 UDP 协议的发送. 可以把 Socket 看做比 TCP/IP 更高级的接口层, 可以用下图形象的理解:

![TCP/IP](https://tva1.sinaimg.cn/large/007S8ZIlgy1gevmv4u1c2j30xq0tqn8f.jpg)

使用`Socket`进行客户端和服务端的链接过程如下:

![Socket](https://tva1.sinaimg.cn/large/007S8ZIlgy1gevmvd9le5j30u00vrk0r.jpg)

##### 2 Server
使用 `GCDAsyncSocket` 创建服务端, 监听端口 `5858`:
```
- (GCDAsyncSocket *)serverSocket {
    if (!_serverSocket) {
        _serverSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    return _serverSocket;
}

NSError *error;
BOOL result = [self.serverSocket acceptOnPort:port error:&error];

```
`delegateQueue` 要求是顺序队列, 保证`Socket`中传输的数据按顺序读取或者存储. 
从 `Socket` 链接过程图中, 能够看出分为`链接成功`/`接收数据`/`断开链接` 3 个过程, GCDAsyncSocket 通过代理方法来实现:
```
#pragma mark - GCDAsyncSocketDelegate
- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
     NSLog(@"收到链接:%@: %d", newSocket.localAddress, newSocket.localPort);   
    [newSocket readDataWithTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    NSString *clientStr = [[NSString alloc] initWithData:data encoding:(NSUTF8StringEncoding)];
    NSLog(@"收到内容: %@ 长度:%zd", clientStr, clientStr.length);
        
    [sock readDataWithTimeout:-1 tag:0];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(nullable NSError *)err {
    NSLog(@"断开链接: %@; error: %@", sock.connectedHost, err);   
}
```
`readDataWithTimeout` 中设置为`-1`, 表示超时时间无限大, 保证数据写入到`Socket`中的`dataBuffer`. `tag`值为数据包的标识, 过程中可以通过该标识识别数据包, 比如传输失败的代理方法/服务端接收到数据的代理方法中.

##### 3 Client
客户端通过`GCDAsyncSocket`链接到主机端口:
```
- (GCDAsyncSocket *)clientSocket {
    if (!_clientSocket) {
        _clientSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:self.sockeQueue];
    return _clientSocket;
}
NSError *error = nil;
[self.clientSocket connectToHost:host onPort:port error:&error];
if (error) {
    return NO;
}else {
    return YES;
}
```
在链接成功后使用 `socket` 向服务端口发送数据包:
```
- (void)socket:(GCDAsyncSocket *)socket didConnectToHost:(NSString *)host port:(uint16_t)port {
   NSData *contentData = [@"client: 123" dataUsingEncoding:(NSUTF8StringEncoding)];
   [socket writeData:data withTimeout:-1 tag:0];
}
```
##### 4 粘包
手动点击`button`发送小数据, 不会出现数据错乱的问题, 当大量数据通过`Socket`同时发送时, 在服务端会出现数据链接错乱的情况. 链接成功后, 向服务端发送 `100` 个数据:
```
- (void)sendData:(GCDAsyncSocket *)socket {
    for (int i = 0; i < 100; i++) {
        NSString *str = [NSString stringWithFormat:@"%d", i];
        NSData *contentData = [str dataUsingEncoding:(NSUTF8StringEncoding)];
        [socket writeData:data withTimeout:-1 tag:0];
    }
}
```
在服务端接收的数据如下:
```
SocketServer[70565:1560844] 收到内容: 0 长度:1
SocketServer[70565:1560844] 收到内容: 1234 长度:4
SocketServer[70565:1560844] 收到内容: 5678910111213141516171819202122 长度:31
SocketServer[70565:1560844] 收到内容: 2324252627282930313233343536 长度:28
SocketServer[70565:1560844] 收到内容: 373839404142434445464748495051 长度:30
SocketServer[70565:1560844] 收到内容: 5253545556575859606162636465666768697071727374 长
SocketServer[70565:1560844] 收到内容: 7576777879808182838485868788899091929394959697 长
SocketServer[70565:1560844] 收到内容: 9899 长度:4

```
能够看出接收的数据, 保持了客户端发送`123...`的顺序,  但是并没有按照 `Socket` 发送的 `1, 2, 3...`相互分割的方式去读取, 这就是`Socket`的`粘包`现象. `粘包`导致服务端接收数据后, 无法分辨出客户端发送数据的起始和终止位置, 会导致解析出错误数据. 

`粘包的原因`
TCP是面向连接的，面向流的，提供高可靠性服务。收发两端（客户端和服务器端）都要有一一成对的socket，因此，发送端为了将多个发往接收端的包，更有效的发到对方，使用了优化方法（Nagle算法），将多次间隔较小且数据量小的数据，合并成一个大的数据块，然后进行封包。


`粘包的解决方式`:
1. 禁用`Nagle`算法；
2. 当填入数据后调用push操作指令强制数据立即传送，而不必等待发送缓冲区填充；
3. 数据包中加头，头部信息为整个数据的长度（最广泛最常用）；

`发送数据`
```
- (void)sendData:(NSData *)contentData {
    NSInteger dataLength = contentData.length;
    NSData *lengthData = [NSData dataWithBytes:&dataLength length:sizeof(dataLength)];
    NSData *headData = [lengthData subdataWithRange:NSMakeRange(0, 4)];
    NSMutableData *data = [NSMutableData dataWithData:headData];
    [data appendData:contentData];
    
    [self.clientSocket writeData:data withTimeout:-1 tag:0];
}
```
`接收数据`
```
- (NSMutableData *)dataBuffer {
    if (!_dataBuffer) {
        _dataBuffer = [NSMutableData data];
    }
    return _dataBuffer;
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    [self.dataBuffer appendData:data];
    while (self.dataBuffer.length >= 4) {
        NSInteger dataLength = 0;
        //获取数据长度
        [[self.dataBuffer subdataWithRange:(NSMakeRange(0, 4))] getBytes:&dataLength length:sizeof(dataLength)];
        if (self.dataBuffer.length >= (dataLength+4)) {
            NSData *realData = [self.dataBuffer subdataWithRange:NSMakeRange(4, dataLength)];
            NSString *clientStr = [[NSString alloc] initWithData:realData encoding:(NSUTF8StringEncoding)];
    NSLog(@"收到内容: %@ 长度:%zd", clientStr, clientStr.length);
            self.dataBuffer = [[self.dataBuffer subdataWithRange:NSMakeRange(4+dataLength, self.dataBuffer.length-4-dataLength)] mutableCopy];            
        } else {
            break;
        }
    }
    [sock readDataWithTimeout:-1 tag:0];
}
```
`注:`
`data` 的`getBytes: length:`方法, 将`data`的`length`部分拷贝到`getBytes`的容器中, 当`length`大于`data`长度时, 拷贝`data`的全部. 初始化` NSInteger dataLength = 0`, 将`data`头部的`4`个长度数据的字节, 存储到长度为`8` 的`dataLength` 空间.

##### 5 Demo
实现了`Client`和`Server`的工程: [Demo](https://github.com/uniapp10/TCPDemo)

##### 感谢Start~
参考:
1 [CocoaAsyncSocket使用](https://www.jianshu.com/p/321bc95d077f)
2 [CocoaAsyncSocket介绍与使用](https://www.jianshu.com/p/7c3045776f9d)
3 [CocoaAsyncSocket 读/写操作以及粘包处理](https://www.jianshu.com/p/1f87d8ba157d)