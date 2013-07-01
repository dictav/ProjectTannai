//
//  PTFlipsideViewController.h
//  ProjectTannai
//
//  Created by Abe Shintaro on 2012/10/16.
//  Copyright (c) 2012年 Abe Shintaro. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PTFlipsideViewController;

@protocol PTFlipsideViewControllerDelegate
- (void)flipsideViewControllerDidFinish:(PTFlipsideViewController *)controller;
@end

@interface PTFlipsideViewController : UIViewController

@property (weak, nonatomic) id <PTFlipsideViewControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIImageView *hogeVIew;

- (IBAction)done:(id)sender;

@end
