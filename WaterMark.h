//
//  WaterMark.h
//  SnapUpload
//
//  Created by pinssible on 15/12/5.
//  Copyright © 2015年 JellyKit Inc. All rights reserved.
//

#ifndef WaterMark_h
#define WaterMark_h

@interface WaterMark : NSObject

+ (void)mixVideo:(NSURL *)path image:(UIImage *)image block:(void(^)(NSData *videoData, NSError *error))block;
+ (void)mixVideo:(NSURL *)path image:(UIImage *)image isWaterMark:(BOOL)isWaterMark block:(void(^)(NSData *videoData, NSError *error))block;

+ (UIImage *)waterMarkImage:(UIImage *)backgroundImage withWaterMark:(UIImage *)waterMarkImage;

+ (CGRect)getWaterMarkFrameWithVideoUrl:(NSURL *)url fullScreen:(BOOL)fullScreen;
+ (CGRect)getWaterMarkFrameWithImage:(UIImage *)image fullScreen:(BOOL)fullScreen;

@end

#endif /* WaterMark_h */
