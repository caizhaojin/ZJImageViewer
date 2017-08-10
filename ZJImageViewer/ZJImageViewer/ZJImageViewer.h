//
//  ZJImageViewer.h
//  ZJImageViewer
//
//  Created by Choi on 2017/8/11.
//  Copyright © 2017年 CZJ. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ZJImageViewer;
@protocol ZJImageViewerDelegate <NSObject>

@optional
- (void)zjImageViewer:(ZJImageViewer *)imageViewer willDismissWithSelectedView:(UIImageView *)selectedView;

@end

@interface ZJImageViewer : UIView

@property (weak, nonatomic) id <ZJImageViewerDelegate>delegate;
/** 默认为 1.0 */
@property (nonatomic) CGFloat backgroundScale;

/** 初始化图片数组 */
- (instancetype)initWithImageViews:(NSArray *)imageviews;
/** 展示当前选择的图片 */
- (void)showFromSelectImageView:(UIImageView *)selectImageView;

@end

