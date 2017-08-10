//
//  ZJImageViewer.m
//  ZJImageViewer
//
//  Created by Choi on 2017/8/11.
//  Copyright © 2017年 CZJ. All rights reserved.
//

#import "ZJImageViewer.h"

#pragma mark - ---- 图像视图状态 -----
#pragma mark - ---- ZJImageViewState -----
@interface ZJImageViewState : UIView

@property (weak, nonatomic) UIView *superview;
@property (nonatomic) CGRect frame;
@property (nonatomic) BOOL userInteratctionEnabled;

+ (ZJImageViewState *)stateForImageView:(UIView *)view;
- (void)setStateWithImageView:(UIView *)view;

@end

@implementation ZJImageViewState

+ (ZJImageViewState *)stateForImageView:(UIView *)view {
    static NSMutableDictionary *dict = nil;
    if(dict == nil) {
        dict = [NSMutableDictionary dictionary];
    }
    
    ZJImageViewState *state = dict[@(view.hash)];
    if(state == nil) {
        state = [[self alloc] init];
        dict[@(view.hash)] = state;
    }
    return state;
}

- (void)setStateWithImageView:(UIView *)view
{
    CGAffineTransform trans = view.transform;
    self.superview = view.superview;
    self.frame     = view.frame;
    self.transform = trans;
    self.userInteratctionEnabled = view.userInteractionEnabled;
}
@end

#pragma mark - ---- 图像缩放视图 -----
#pragma mark - ---- ZJZoomingView -----
@interface ZJZoomingView : UIView <UIScrollViewDelegate>

@property (weak, nonatomic) UIImageView *imageView;
@property (weak, nonatomic) UIScrollView *scrollView;
@property (nonatomic) BOOL isViewing;

@end

@implementation ZJZoomingView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupZoomingView];
    }
    return self;
}

- (void)setupZoomingView
{
    self.clipsToBounds = YES;
    self.contentMode = UIViewContentModeScaleAspectFill;
    
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.delegate = self;
    [self addSubview:scrollView];
    _scrollView = scrollView;
}
- (void)setImageView:(UIImageView *)imageView
{
    if(imageView != _imageView) {
        [_imageView removeFromSuperview];
        
        _imageView = imageView;
        _imageView.frame = _imageView.bounds;
        
        [_scrollView addSubview:_imageView];
        
        _scrollView.zoomScale = 1;
        _scrollView.contentOffset = CGPointZero;
        
        [self resetZoomScale];
        _scrollView.zoomScale = _scrollView.minimumZoomScale;
        [self scrollViewDidZoom:_scrollView];
    }
}
- (BOOL)isViewing
{
    if (_scrollView.contentSize.height >= _scrollView.bounds.size.height) {
        return YES;
    } else {
        return NO;
    }
}
#pragma mark - UIScrollviewDelegate
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return _imageView;
}
- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    
    CGFloat Ws = _scrollView.frame.size.width - _scrollView.contentInset.left - _scrollView.contentInset.right;
    CGFloat Hs = _scrollView.frame.size.height - _scrollView.contentInset.top - _scrollView.contentInset.bottom;
    CGFloat W = _imageView.frame.size.width;
    CGFloat H = _imageView.frame.size.height;
    
    CGRect rct = _imageView.frame;
    rct.origin.x = MAX((Ws-W)/2, 0);
    rct.origin.y = MAX((Hs-H)/2, 0);
    _imageView.frame = rct;
}

- (void)resetZoomScale
{
    CGFloat Rw = _scrollView.frame.size.width / _imageView.frame.size.width;
    CGFloat Rh = _scrollView.frame.size.height / _imageView.frame.size.height;
    
    CGFloat scale = 1;
    Rw = MAX(Rw, _imageView.image.size.width / (scale * _scrollView.frame.size.width));
    Rh = MAX(Rh, _imageView.image.size.height / (scale * _scrollView.frame.size.height));
    
    _scrollView.contentSize = _imageView.frame.size;
    _scrollView.minimumZoomScale = 1;
    _scrollView.maximumZoomScale = MAX(MAX(Rw, Rh), 1);
}

@end


#pragma mark - ---- 图片浏览器 -----
#pragma mark - ---- ZJImageViewer -----
@interface ZJImageViewer () <UIScrollViewDelegate, UIActionSheetDelegate>

@property (strong, nonatomic) NSArray *imageViews;
@property (weak, nonatomic) UIScrollView *scrollView;
@property (weak, nonatomic) UIPageControl *pageControl;
@property (weak, nonatomic) UIImageView *currentImageView;
@property (nonatomic) NSInteger currentImageIndex;

@end

@implementation ZJImageViewer

- (instancetype)initWithImageViews:(NSArray *)imageviews
{
    self = [super initWithFrame:[[UIScreen mainScreen] bounds]];
    if (self) {
        [self setupImageViewer];
        [self setupImageViews:imageviews];
    }
    return self;
}
- (void)setupImageViews:(NSArray *)imageviews
{
    NSMutableArray *mutImages = [NSMutableArray array];
    for(id obj in imageviews) {
        if([obj isKindOfClass:[UIImageView class]]) {
            [mutImages addObject:obj];
            
            UIImageView *view = obj;
            
            ZJImageViewState *state = [ZJImageViewState stateForImageView:view];
            [state setStateWithImageView:view];
            
            view.userInteractionEnabled = NO;
        }
    }
    _imageViews = [mutImages copy];
    
    
    _pageControl.numberOfPages = _imageViews.count;
    
}
- (void)setupImageViewer
{
    self.backgroundScale = 1.0;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGesture)];
    [self addGestureRecognizer:tap];
    
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapGesture:)];
    doubleTap.numberOfTapsRequired = 2;
    [tap requireGestureRecognizerToFail:doubleTap];
    [self addGestureRecognizer:doubleTap];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGesture:)];
    pan.maximumNumberOfTouches = 1;
    [self addGestureRecognizer:pan];
    
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGesture:)];
    [self addGestureRecognizer:longPressGesture];
    
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    scrollView.pagingEnabled = YES;
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.showsVerticalScrollIndicator   = NO;
    scrollView.delegate = self;
    scrollView.backgroundColor = [UIColor blackColor];
    scrollView.alpha = 0;
    [self addSubview:scrollView];
    _scrollView = scrollView;
    
    UIPageControl *pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(0, self.bounds.size.height - 40, self.bounds.size.width, 20)];
    pageControl.hidesForSinglePage = YES;
    pageControl.userInteractionEnabled = NO;
    [self addSubview:pageControl];
    _pageControl = pageControl;
}

#pragma mark - 展示
- (void)showFromSelectImageView:(UIImageView *)selectImageView
{
    if (_imageViews.count > 0) {
        if(![selectImageView isKindOfClass:[UIImageView class]] || ![_imageViews containsObject:selectImageView]){
            selectImageView = _imageViews[0];
        }
        [self showWithSelectImageView:selectImageView];
    }
}
- (void)showWithSelectImageView:(UIImageView *)selectImageView
{
    [_scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    NSInteger currentPage = [_imageViews indexOfObject:selectImageView];
    _pageControl.currentPage = currentPage;
    
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    [window addSubview:self];
    
    CGFloat fullW = window.frame.size.width;
    CGFloat fullH = window.frame.size.height;
    
    selectImageView.frame = [window convertRect:selectImageView.frame fromView:selectImageView.superview];
    [window addSubview:selectImageView];
    
    [UIApplication sharedApplication].statusBarHidden = YES;
    
    [UIView animateWithDuration:0.25 animations:^{
        _scrollView.alpha = 1;
        window.rootViewController.view.transform = CGAffineTransformMakeScale(self.backgroundScale, self.backgroundScale);
        
        selectImageView.transform = CGAffineTransformIdentity;
        
        CGSize size = (selectImageView.image) ? selectImageView.image.size : selectImageView.frame.size;
        
        //  552     320
        //  4170    ?
        CGFloat W = 0;
        CGFloat H = 0;
        if (size.width >= fullW) {
            W = fullW;
            H = W * size.height / size.width;
        } else {
            CGFloat ratio = MIN(fullW / size.width, fullH / size.height);
            W = ratio * size.width;
            H = ratio * size.height;
        }
        CGFloat X = (fullW-W)/2;
        CGFloat Y = (fullH-H)/2;
        if (H >= fullH) {
            // 长图或等高图
            Y = 0;
        }
        selectImageView.frame = CGRectMake(X, Y, W, H);
    } completion:^(BOOL finished) {
        _scrollView.contentSize = CGSizeMake(_imageViews.count * fullW, 0);
        _scrollView.contentOffset = CGPointMake(currentPage * fullW, 0);
        
        
        for (UIImageView *view in _imageViews) {
            view.transform = CGAffineTransformIdentity;
            
            CGSize size = (view.image) ? view.image.size : view.frame.size;
            CGFloat W = 0;
            CGFloat H = 0;
            if (size.width >= fullW) {
                W = fullW;
                H = W * size.height / size.width;
            } else {
                CGFloat ratio = MIN(fullW / size.width, fullH / size.height);
                W = ratio * size.width;
                H = ratio * size.height;
            }
            CGFloat X = (fullW-W)/2;
            CGFloat Y = (fullH-H)/2;
            if (H >= fullH) {
                Y = 0;
            }
            view.frame = CGRectMake(X, Y, W, H);
            ZJZoomingView *tmp = [[ZJZoomingView alloc] initWithFrame:CGRectMake([_imageViews indexOfObject:view] * fullW, 0, fullW, fullH)];
            tmp.imageView = view;
            
            [_scrollView addSubview:tmp];
        }
    }];

}
#pragma mark - 消失
- (void)prepareToDismiss
{
    UIImageView *currentView = self.currentImageView;
    
    if([self.delegate respondsToSelector:@selector(zjImageViewer:willDismissWithSelectedView:)]) {
        [self.delegate zjImageViewer:self willDismissWithSelectedView:currentView];
    }
    
    for (UIImageView *view in _imageViews) {
        if(view != currentView) {
            ZJImageViewState *state = [ZJImageViewState stateForImageView:view];
            view.transform = CGAffineTransformIdentity;
            view.frame = state.frame;
            view.transform = state.transform;
            [state.superview addSubview:view];
        }
    }
}
- (void)dismiss
{
    UIImageView *currentView = self.currentImageView;
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    
    CGRect rct = currentView.frame;
    currentView.transform = CGAffineTransformIdentity;
    currentView.frame = [window convertRect:rct fromView:currentView.superview];
    [window addSubview:currentView];
    
    [UIView animateWithDuration:0.25 animations:^{
        _scrollView.alpha = 0;
        window.rootViewController.view.transform =  CGAffineTransformIdentity;

        ZJImageViewState *state = [ZJImageViewState stateForImageView:currentView];
        currentView.frame = [window convertRect:state.frame fromView:state.superview];
        currentView.transform = state.transform;
        
    } completion:^(BOOL finished) {
        [UIApplication sharedApplication].statusBarHidden = NO;
        ZJImageViewState *state = [ZJImageViewState stateForImageView:currentView];
        currentView.transform = CGAffineTransformIdentity;
        currentView.frame = state.frame;
        currentView.transform = state.transform;
        [state.superview addSubview:currentView];
        
        for (UIView *view in _imageViews) {
            ZJImageViewState *temp = [ZJImageViewState stateForImageView:view];
            view.userInteractionEnabled = temp.userInteratctionEnabled;
        }
        [self removeFromSuperview];
    }];
    
}

#pragma mark - GestureRecognizer
#pragma mark TapGesture
- (void)tapGesture
{
    [self prepareToDismiss];
    [self dismiss];
}
#pragma mark DoubleTapGesture
- (void)doubleTapGesture:(UITapGestureRecognizer *)gesture
{
    ZJZoomingView *currentView = _scrollView.subviews[self.currentImageIndex];
    
    if (currentView.scrollView.zoomScale > 1) {
        [currentView.scrollView setZoomScale:1 animated:YES];
    } else {
        CGPoint touchPoint = [gesture locationInView:currentView];
        CGFloat newZoomScale = currentView.scrollView.maximumZoomScale;
        CGFloat xsize = self.bounds.size.width / newZoomScale;
        CGFloat ysize = self.bounds.size.height / newZoomScale;
        [currentView.scrollView zoomToRect:CGRectMake(touchPoint.x - xsize/2, touchPoint.y - ysize/2, xsize, ysize) animated:YES];
    }
}
#pragma mark PanGesture
- (void)panGesture:(UIPanGestureRecognizer *)gesture
{
    static UIImageView *currentView = nil;
    
    if(gesture.state == UIGestureRecognizerStateBegan) {
        currentView = self.currentImageView;
        
        UIView *targetView = currentView.superview;
        while(![targetView isKindOfClass:[ZJZoomingView class]]) {
            targetView = targetView.superview;
        }
        
        if (((ZJZoomingView *)targetView).isViewing) {
            currentView = nil;
        } else {
            UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
            currentView.frame = [window convertRect:currentView.frame fromView:currentView.superview];
            [window addSubview:currentView];
            
            [self prepareToDismiss];
        }
    }
    
    if(currentView) {
        
        if(gesture.state == UIGestureRecognizerStateEnded) {
            
            if(_scrollView.alpha > 0.5) {
                [self showWithSelectImageView:currentView];
            } else {
                [self dismiss];
            }
            currentView = nil;
        } else {
            CGPoint p = [gesture translationInView:self];
            
            CGAffineTransform transform = CGAffineTransformMakeTranslation(p.x, p.y);
            transform = CGAffineTransformScale(transform, 1 - fabs(p.y)/1000, 1 - fabs(p.y)/1000);
            currentView.transform = transform;
            
            CGFloat r = 1-fabs(p.y)/200;
            _scrollView.alpha = MAX(0, MIN(1, r));
        }
    }
}

#pragma mark LongPressGresture
- (void)longPressGesture:(UILongPressGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan) {
        NSLog(@"长按");
        UIActionSheet *actionsheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"保存图片", nil];
        actionsheet.tag = 888;
        [actionsheet showInView:self];
    }
    
}
#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == 888 && buttonIndex == 0) {
        [self saveImage];
    }
}
- (void)saveImage
{
    ZJZoomingView *currentView = _scrollView.subviews[self.currentImageIndex];
    
    UIView *waittingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    waittingView.center = self.center;
    waittingView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
    waittingView.layer.masksToBounds = YES;
    waittingView.layer.cornerRadius = 8;
    [currentView addSubview:waittingView];
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] init];
    indicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    indicator.frame = CGRectMake(10, 10, 80, 80);
    [waittingView addSubview:indicator];
    [indicator startAnimating];
    
    NSLog(@"保存图片 - info.plist 需要添加 Privacy - Photo Library Usage Description");
    // info.plist 需要添加 Privacy - Photo Library Usage Description
    UIImageWriteToSavedPhotosAlbum(currentView.imageView.image, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo;
{
    ZJZoomingView *currentView = nil;
    for (ZJZoomingView *zoomingView in _scrollView.subviews) {
        if ([zoomingView.imageView.image isEqual:image]) {
            currentView = zoomingView;
            [zoomingView.subviews.lastObject removeFromSuperview];
        }
    }
    
    UILabel *label = [[UILabel alloc] init];
    label.textColor = [UIColor whiteColor];
    label.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
    label.layer.cornerRadius = 8;
    label.layer.masksToBounds = YES;
    label.bounds = CGRectMake(0, 0, 100, 100);
    label.center = self.center;
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont boldSystemFontOfSize:17];
    [currentView addSubview:label];
    if (error) {
        label.text = @"保存失败";
    }   else {
        label.text = @"保存成功";
    }
    CGFloat delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^{
        [label removeFromSuperview];
    });
    
}
#pragma mark - UIScorllViewDelegate
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    _pageControl.currentPage = scrollView.contentOffset.x / scrollView.frame.size.width;
}

#pragma mark - GET
- (NSInteger)currentImageIndex
{
    return (_scrollView.contentOffset.x / _scrollView.frame.size.width + 0.5);
}
- (UIImageView *)currentImageView
{
    return [_imageViews objectAtIndex:self.currentImageIndex];
}

#pragma mark - Dealloc
- (void)dealloc
{
    NSLog(@"dealloc - ZJImageViewer");
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    NSLog(@"windows.subviews  %@",window.subviews);
}

@end
