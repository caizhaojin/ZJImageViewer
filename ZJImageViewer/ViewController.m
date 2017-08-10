//
//  ViewController.m
//  ZJImageViewer
//
//  Created by Choi on 2017/8/11.
//  Copyright © 2017年 CZJ. All rights reserved.
//

#import "ViewController.h"
#import "ZJImageViewer.h"

@interface ViewController ()

@property (strong, nonatomic) NSMutableArray *mutImages;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _mutImages = [NSMutableArray array];
    NSArray *imageNames = @[@"image01.jpg"];
    for (NSInteger i = 0; i < imageNames.count; i++) {
        UIImageView *img = [[UIImageView alloc] initWithFrame:CGRectMake( 20 + i * 50  + 80 * i, (self.view.bounds.size.height - 80)*0.5 , 80, 80)];
        img.image = [UIImage imageNamed:imageNames[i]];
        img.tag = i;
        img.contentMode = UIViewContentModeScaleAspectFill;
        img.clipsToBounds = YES;
        [self.view addSubview:img];
        [_mutImages addObject:img];
        
        img.userInteractionEnabled = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapImgAction:)];
        [img addGestureRecognizer:tap];
    }
}

- (void)tapImgAction:(UITapGestureRecognizer *)tap
{
    ZJImageViewer *imageViewer = [[ZJImageViewer alloc] initWithImageViews:_mutImages];
    [imageViewer showFromSelectImageView:_mutImages[tap.view.tag]];
}

@end
