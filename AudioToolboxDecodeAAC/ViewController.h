//
//  ViewController.h
//  AudioToolboxDecodeAAC
//
//  Created by 刘文晨 on 2024/7/8.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (nonatomic, strong) UILabel *mLabel;
@property (nonatomic , strong) UILabel *mCurrentTimeLabel;
@property (nonatomic, strong) UIButton *mButton;
@property (nonatomic, strong) CADisplayLink *mDispalyLink;

@end

