//
//  AACPlayer.h
//  AudioToolboxDecodeAAC
//
//  Created by 刘文晨 on 2024/7/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AACPlayer;

@protocol AACPlayerDelegate <NSObject>

- (void)onPlayToEnd:(AACPlayer *)player;

@end

@interface AACPlayer : NSObject

@property (nonatomic, weak) id<AACPlayerDelegate> delegate;

- (void)play;
- (void)stop;
- (double)getCurrentTime;

@end

NS_ASSUME_NONNULL_END
