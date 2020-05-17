//
//  ViewController.m
//  SocketServer
//
//  Created by ZD on 2020/5/16.
//  Copyright © 2020 ZD. All rights reserved.
//

#import "ViewController.h"
#import "TCPServerTool.h"

@interface ViewController ()<TCPServerToolDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UIButton *btnOne = [self getBtnWithTitle:@"Listen" positionY:100 action:@selector(btnClick)];
    [self.view addSubview:btnOne];
    
    UIButton *btnOne2 = [self getBtnWithTitle:@"SendData" positionY:150 action:@selector(btnClick2)];
    [self.view addSubview:btnOne2];
    
    UIButton *btnOne3 = [self getBtnWithTitle:@"Disconnect" positionY:200 action:@selector(btnClick3)];
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
//    BOOL result = [self.serverSocket acceptOnPort:5858 error:&error];
    BOOL result = [[TCPServerTool shareInstance] listenOnPort:5858 delegate:self];
    if (result) {
        NSLog(@"监听端口 5858 成功");
    }else {
//        NSLog(@"失败: %@, %@", error.domain, error.description);
        NSLog(@"失败");
    }
    
//
//    char hearBeat[4] = {0x10,0x00,0x00,0x00};
//    char hearBeat2[4] = {'a','b',0x00,0x00};
//    NSData *heartData = [NSData dataWithBytes:&hearBeat length:sizeof(hearBeat)];
////    char buffer[100];
//    NSInteger datalength = 0;
//    [heartData getBytes:&datalength length:sizeof(datalength)];

//    NSInteger dataLength2 = 100;
//    NSData *data2 = [NSData dataWithBytes:&dataLength2 length:sizeof(dataLength2)];
//
//    NSInteger datalength = 0;
//    [data2 getBytes:&datalength length:sizeof(datalength)];
//
//    NSLog(@"%@", datalength);
    
}

- (void)btnClick2 {
    for (int i = 0; i < 100; i++) {
        NSString *contentStr = [NSString stringWithFormat:@"%d", 1];
        NSData *data = [contentStr dataUsingEncoding: NSUTF8StringEncoding];
        [[TCPServerTool shareInstance] sendData:data to:@"127.0.0.1"];
    }
}

- (void)btnClick3 {
    [[TCPServerTool shareInstance] disconnect:@"127.0.0.1"];
}

#pragma mark - TCPServerToolDelegate

- (void)socket:(TCPServerTool *)tool receiveData:(NSData *)contentData {
    NSString *clientStr = [[NSString alloc] initWithData:contentData encoding:(NSUTF8StringEncoding)];
    NSLog(@"收到内容: %@ 长度:%zd", clientStr, clientStr.length);
}

- (void)socket:(TCPServerTool *)tool status:(ConnectStatus)status {
    NSLog(@"status: %zd", status);
}

@end
