//
//  ViewController.m
//  SocketClient
//
//  Created by ZD on 2020/5/17.
//  Copyright © 2020 ZD. All rights reserved.
//

#import "ViewController.h"
#import "GCDAsyncSocket.h"
#import "TCPClientTool.h"

@interface ViewController ()<GCDAsyncSocketDelegate, SocketToolDelegate>

@property (nonatomic, strong) GCDAsyncSocket *clientSocket;
@property (nonatomic, strong) NSTimer *heartTimer;
@property (weak, nonatomic) IBOutlet UITextField *contentTF;
@property (nonatomic, strong) NSMutableData *dataBuffer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UIButton *btnOne = [self getBtnWithTitle:@"Connect" positionY:100 action:@selector(btnClick)];
    [self.view addSubview:btnOne];
    
    UIButton *btnOne2 = [self getBtnWithTitle:@"SendData" positionY:150 action:@selector(btnClick2)];
    [self.view addSubview:btnOne2];
    
    UIButton *btnOne3 = [self getBtnWithTitle:@"Stop" positionY:200 action:@selector(btnClick3)];
    [self.view addSubview:btnOne3];
}

- (UIButton *)getBtnWithTitle:(NSString *)title positionY:(CGFloat)positionY action:(SEL)selector {
    CGRect ScreenFrame = [UIScreen mainScreen].bounds;
    CGFloat ScreenWidth = ScreenFrame.size.width;
    CGFloat ScreenHeight = ScreenFrame.size.height;
    CGFloat margin = 10;
    UIButton *btn = [[UIButton alloc] init];
    btn.frame = CGRectMake(10, positionY, ScreenWidth - 2 * margin, 40);
    [btn setTitle:title forState:UIControlStateNormal];
    [btn addTarget:self action:selector forControlEvents:(UIControlEventTouchUpInside)];
    btn.backgroundColor = [UIColor orangeColor];
    return btn;
}

- (void)btnClick {
//    NSError *error;
//    [self.clientSocket connectToHost:@"127.0.0.1" onPort:5858 error:&error];
//    if (error) {
//        NSLog(@"error: %@", error);
//    }
    
//    [[TCPTool shareInstance] connectToHost:@"127.0.0.1" onPort:5858 delegate:self];
    [[TCPClientTool shareInstance] connectToHost:@"127.0.0.1" onPort:5858 delegate:self];
}



- (void)btnClick2 {
    
    if (self.contentTF.text.length == 0) {
        return;
    }
    NSData *contentData = [self.contentTF.text dataUsingEncoding:(NSUTF8StringEncoding)];
//    [self sendData:contentData];
    [[TCPClientTool shareInstance] sendData:contentData];
    
//    for (int i = 0; i < 100; i++) {
//        NSString *str = [NSString stringWithFormat:@"%d", i];
//        NSData *contentData = [str dataUsingEncoding:(NSUTF8StringEncoding)];
//
//        NSInteger dataLength = contentData.length;
//        NSData *lengthData = [NSData dataWithBytes:&dataLength length:sizeof(dataLength)];
//        NSData *headData = [lengthData subdataWithRange:NSMakeRange(0, 4)];
//
//        NSInteger datalength2 = 0;
//        [headData getBytes:&datalength2 length:sizeof(datalength2)];
//
//        NSMutableData *data = [NSMutableData dataWithData:headData];
//        [data appendData:contentData];
//
//        [self sendData: data];
//    }
}

- (void)btnClick3 {
//    if (self.clientSocket) {
//        [self.clientSocket disconnect];
//    }
    [[TCPClientTool shareInstance] disconnect];
}

#pragma mark - SocketToolDelegate

- (void)socket:(TCPClientTool *)tool receiveData:(NSData *)contentData {
//    NSLog(@"%@", contentData);
    NSString *clientStr = [[NSString alloc] initWithData:contentData encoding:(NSUTF8StringEncoding)];
    NSLog(@"收到内容: %@ 长度:%zd", clientStr, clientStr.length);
}

- (void)socket:(TCPClientTool *)tool status:(ConnectStatus)status {
    NSLog(@"%zd", status);
}

@end
