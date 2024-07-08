//
//  ViewController.m
//  AudioToolboxDecodeAAC
//
//  Created by 刘文晨 on 2024/7/8.
//

#import "ViewController.h"
#import "AACPlayer.h"

@interface ViewController () <AACPlayerDelegate>

@end

@implementation ViewController
{
    AACPlayer *player;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = UIColor.whiteColor;
    
    self.mLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 300, 100)];
    self.mLabel.textColor = UIColor.blackColor;
    self.mLabel.text = @"使用 Audio Toolbox 解码并播放 AAC";
    self.mLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.mCurrentTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 100)];
    self.mCurrentTimeLabel.textColor = [UIColor redColor];
    self.mCurrentTimeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.mButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    [self.mButton setTitle:@"play" forState:UIControlStateNormal];
    [self.mButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    self.mButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.mButton addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
    
    self.mDispalyLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateFrame)];
    self.mDispalyLink.preferredFramesPerSecond = 12;
    [self.mDispalyLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    [self.view addSubview:self.mLabel];
    [self.view addSubview:self.mCurrentTimeLabel];
    [self.view addSubview:self.mButton];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.mLabel.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:100],
        [self.mLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        
        [self.mCurrentTimeLabel.topAnchor constraintEqualToAnchor:self.mLabel.bottomAnchor constant:100],
        [self.mCurrentTimeLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        
        [self.mButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.mButton.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor]
    ]];
}

- (void)btnClick:(UIButton *)sender
{
    self.mButton.hidden = YES;
    player = [[AACPlayer alloc] init];
    // AACPlayer Delegate
    player.delegate = self;
    [player play];
}

- (void)updateFrame
{
    if (player)
    {
        self.mCurrentTimeLabel.text = [NSString stringWithFormat:@"当前播放时长：%.1fs", [player getCurrentTime]];
    }
}

#pragma mark - AACPlayer Delegate Method

- (void)onPlayToEnd:(AACPlayer *)player
{
    [self mButton];
    player = nil;
    self.mButton.hidden = NO;
    [self.mDispalyLink setPaused:YES];
}

@end
