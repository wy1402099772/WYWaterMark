//
//  WaterMark.m
//  SnapUpload
//
//  Created by pinssible on 15/12/5.
//  Copyright © 2015年 JellyKit Inc. All rights reserved.
//

//pay attentation  : watermark location is dependended on iphone6 375x667

#import <Foundation/Foundation.h>
#import "WaterMark.h"
#import <AVFoundation/AVFoundation.h>
#import "VideoPortrait.h"
#import "ErrorCode.h"

static NSUInteger useTime = 0;

@implementation WaterMark

#pragma mark - Public methods
+ (void)mixVideo:(NSURL *)path image:(UIImage *)image block:(void (^)(NSData *, NSError *))block
{
    [WaterMark mixVideo:path image:image isWaterMark:YES block:block];
}

+ (void)mixVideo:(NSURL *)path image:(UIImage *)image isWaterMark:(BOOL)isWaterMark block:(void (^)(NSData *, NSError *))block {
    
    NSError *error = nil;
    NSData *tmpData = [NSData dataWithContentsOfURL:path options:NSDataReadingMappedAlways error:&error];
    if (!isWaterMark) {
        
        if (error) {
            NSLog(@"get data of url:%@ error:%@", path, error);
        } else {
            block(tmpData, nil);
        }
    } else {
        NSString *presetName = AVAssetExportPresetMediumQuality;
        NSString *tmpPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%lu%@", (unsigned long)useTime++, @"tmpWaterMarkMov.mp4"]];
        [self deleteTmpFile:tmpPath];
        AVURLAsset *videoAsset = [[AVURLAsset alloc] initWithURL:path options:nil];
        AVMutableComposition *mixComposition = [AVMutableComposition composition];
        
        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:presetName];
        exportSession.videoComposition = [self getVideoComposition:videoAsset composition:mixComposition withImage:image];
        
        exportSession.outputURL = [NSURL fileURLWithPath:tmpPath];
        exportSession.outputFileType = AVFileTypeMPEG4;
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            
            switch (exportSession.status)
            {
                case AVAssetExportSessionStatusFailed: {
                    NSLog(@"Export failed: %@", [[exportSession error] localizedDescription]);
                }
                    break;
                case AVAssetExportSessionStatusCancelled: {
                    NSLog(@"Export canceled");
                }
                    break;
                    
                case AVAssetExportSessionStatusCompleted: {
                    NSLog(@"Export completed");
                    NSURL *tmpURL = [NSURL fileURLWithPath:tmpPath];
                    NSError *error = nil;
                    NSData *tmpData = [NSData dataWithContentsOfURL:tmpURL options:NSDataReadingMappedAlways error:&error];
                    block(tmpData, error);
                }
                    break;
                    
                default:
                    break;
            }
            
            [WaterMark deleteTmpFile:tmpPath];
        }];
    }
}

+ (UIImage *)waterMarkImage:(UIImage *)backgroundImage withWaterMark:(UIImage *)waterMarkImage
{
    CGSize StandardSize = CGSizeMake(375, 667);
    CGFloat tmpWidth = backgroundImage.size.width;
    
    CGFloat scale = StandardSize.width / tmpWidth * waterMarkImage.size.width / 180;
    waterMarkImage = [UIImage imageWithCGImage:waterMarkImage.CGImage scale:scale * waterMarkImage.scale orientation:waterMarkImage.imageOrientation];
    UIGraphicsBeginImageContext(backgroundImage.size);
    [backgroundImage drawInRect:CGRectMake(0, 0, backgroundImage.size.width, backgroundImage.size.height)];
    
    CGRect drawRect = CGRectMake(backgroundImage.size.width - waterMarkImage.size.width - 10 / StandardSize.width * tmpWidth, backgroundImage.size.height - waterMarkImage.size.height - 10 / StandardSize.width * tmpWidth, waterMarkImage.size.width, waterMarkImage.size.height);
    [waterMarkImage drawInRect:drawRect];
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return result;
}

+ (CGRect)getWaterMarkFrameWithVideoUrl:(NSURL *)url fullScreen:(BOOL)fullScreen {
    
    AVURLAsset *tmpVideoAssert = [AVURLAsset assetWithURL:url];
    if(![[tmpVideoAssert tracksWithMediaType:AVMediaTypeVideo] count])
        return CGRectZero;
    CGSize tmpSize = [[[tmpVideoAssert tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] naturalSize];
    
    NSLog(@"【Watermark Frame】tmpSize origin:(%lf,%lf)", tmpSize.width, tmpSize.height);
    
    if([VideoPortrait isVideoPortrait:tmpVideoAssert.URL])
    {
        tmpSize = CGSizeMake(tmpSize.height, tmpSize.width);
    }
    
    CGSize standardSize =  CGSizeMake(375, 667);
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    if (!fullScreen) {
        screenSize.height = screenSize.height - 64;
    }
    
    CGFloat scale;
    if(tmpSize.width && tmpSize.height)
    {
        if(tmpSize.width / tmpSize.height >= screenSize.width / screenSize.height)  //v video
        {
            tmpSize.height = tmpSize.height / tmpSize.width * screenSize.width;
            tmpSize.width = screenSize.width;
            scale = tmpSize.width / standardSize.width;
        }
        else //h video
        {
            tmpSize.width = tmpSize.width / tmpSize.height * screenSize.height;
            tmpSize.height = screenSize.height;
            scale = tmpSize.height / standardSize.height;
        }
        
        NSLog(@"【Watermark Frame】tmpSize:(%lf,%lf)", tmpSize.width, tmpSize.height);
        CGRect tmpVideoFrame = CGRectMake((screenSize.width - tmpSize.width) / 2, (screenSize.height - tmpSize.height) / 2, tmpSize.width, tmpSize.height);
        NSLog(@"【Watermark Frame】tmpVideoFrame:(%lf,%lf,%lf,%lf)",tmpVideoFrame.origin.x, tmpVideoFrame.origin.y, tmpVideoFrame.size.width, tmpVideoFrame.size.height);
        CGRect waterMarkFrame = CGRectMake(CGRectGetMaxX(tmpVideoFrame) - (180 + 10) * scale, CGRectGetMaxY(tmpVideoFrame) - (10 + 20) * scale, 180 * scale, 20 * scale);
        NSLog(@"【Watermark Frame】waterMarkFrame:(%lf,%lf,%lf,%lf)",waterMarkFrame.origin.x, waterMarkFrame.origin.y, waterMarkFrame.size.width, waterMarkFrame.size.height);
        
        return waterMarkFrame;
    }
    
    return CGRectZero;
}

+ (CGRect)getWaterMarkFrameWithImage:(UIImage *)image fullScreen:(BOOL)fullScreen {
    
    CGSize tmpSize = image.size;
    
    NSLog(@"【Watermark Frame】tmpSize origin:(%lf,%lf)", tmpSize.width, tmpSize.height);
    
    CGSize standardSize =  CGSizeMake(375, 667);
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    if (!fullScreen) {
        screenSize.height = screenSize.height - 64;
    }

    CGFloat scale;
    if(tmpSize.width && tmpSize.height)
    {
        if(tmpSize.width / tmpSize.height >= screenSize.width / screenSize.height)  //v video
        {
            tmpSize.height = tmpSize.height / tmpSize.width * screenSize.width;
            tmpSize.width = screenSize.width;
            scale = tmpSize.width / standardSize.width;
        }
        else //h video
        {
            tmpSize.width = tmpSize.width / tmpSize.height * screenSize.height;
            tmpSize.height = screenSize.height;
            scale = tmpSize.height / standardSize.height;
        }
        
        NSLog(@"【Watermark Frame】tmpSize:(%lf,%lf)", tmpSize.width, tmpSize.height);
        CGRect tmpImageFrame = CGRectMake((screenSize.width - tmpSize.width) / 2, (screenSize.height - tmpSize.height) / 2, tmpSize.width, tmpSize.height);
        NSLog(@"【Watermark Frame】tmpImageFrame:(%lf,%lf,%lf,%lf)",tmpImageFrame.origin.x, tmpImageFrame.origin.y, tmpImageFrame.size.width, tmpImageFrame.size.height);
        CGRect waterMarkFrame = CGRectMake(CGRectGetMaxX(tmpImageFrame) - (180 + 10) * scale, CGRectGetMaxY(tmpImageFrame) - (10 + 20) * scale, 180 * scale, 20 * scale);
        NSLog(@"【Watermark Frame】waterMarkFrame:(%lf,%lf,%lf,%lf)",waterMarkFrame.origin.x, waterMarkFrame.origin.y, waterMarkFrame.size.width, waterMarkFrame.size.height);
        
        return waterMarkFrame;
    }
    
    return CGRectZero;
}

#pragma mark - Private methods
+ (AVVideoComposition *)getVideoComposition:(AVURLAsset *)asset composition:(AVMutableComposition*)composition withImage:(UIImage *)image{
    BOOL isPortrait = [VideoPortrait isVideoPortrait:asset.URL];
    
    AVMutableCompositionTrack *compositionVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    AVAssetTrack *AudioTrack = nil;
    if([asset tracksWithMediaType:AVMediaTypeAudio].count)
        AudioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    AVMutableCompositionTrack *compositionAudioTrack;
    
    [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:videoTrack atTime:kCMTimeZero error:nil];
    if(AudioTrack)
    {
        compositionAudioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:AudioTrack atTime:kCMTimeZero error:nil];
    }
    AVMutableVideoCompositionLayerInstruction *layerInst = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionVideoTrack];
    
    CGAffineTransform transform = videoTrack.preferredTransform;
    [layerInst setTransform:transform atTime:kCMTimeZero];
    
    AVMutableVideoCompositionInstruction *inst = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    inst.timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
    inst.layerInstructions = [NSArray arrayWithObject:layerInst];
    
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.instructions = [NSArray arrayWithObject:inst];
    
    CGSize videoSize = videoTrack.naturalSize;
    if(isPortrait) {
        //NSLog(@"video is portrait");
        videoSize = CGSizeMake(videoSize.height, videoSize.width);
    }
    
    //Image of watermark
    CALayer *layerWaterMark = [CALayer layer];
    CGSize tmpSize = videoSize, screenSize = CGSizeMake(375, 667);
    if(tmpSize.width / tmpSize.height >= screenSize.width / screenSize.height)  //v video
    {
        tmpSize.height = tmpSize.height / tmpSize.width * screenSize.width;
        tmpSize.width = screenSize.width;
    }
    else //h video
    {
        tmpSize.width = tmpSize.width / tmpSize.height * screenSize.height;
        tmpSize.height = screenSize.height;
    }
    CGRect tmpRect = CGRectMake((1 - 190 / tmpSize.width) * videoSize.width, (10 / tmpSize.height) * videoSize.height, 180 / tmpSize.width * videoSize.width, 20 / tmpSize.height * videoSize.height);
    image = [UIImage imageWithCGImage:image.CGImage scale:image.size.width / tmpRect.size.width orientation:image.imageOrientation];
    layerWaterMark.contents = (id)image.CGImage;
    layerWaterMark.frame = tmpRect;
    layerWaterMark.opacity = 1.0;
    
    
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
    videoLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
    [parentLayer addSublayer:videoLayer];
    [parentLayer addSublayer:layerWaterMark];  //add image layer
    
    videoComposition.renderSize = videoSize;
    videoComposition.frameDuration = CMTimeMake(1,30);
    videoComposition.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    
    return videoComposition;
}

+ (void)deleteTmpFile:(NSString *)tmpPath
{
    
    NSURL *url = [NSURL fileURLWithPath:tmpPath];
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL exist = [fm fileExistsAtPath:url.path];
    NSError *err;
    if (exist) {
        [fm removeItemAtURL:url error:&err];
        NSLog(@"file deleted");
        if (err) {
            NSLog(@"file remove error, %@", err.localizedDescription );
        }
    } else {
        NSLog(@"no file by that name");
    }
}

@end