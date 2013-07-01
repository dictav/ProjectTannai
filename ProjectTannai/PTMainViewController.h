//
//  PTMainViewController.h
//  ProjectTannai
//
//  Created by Abe Shintaro on 2012/10/16.
//  Copyright (c) 2012年 Abe Shintaro. All rights reserved.
//

#import "PTFlipsideViewController.h"

@interface PTMainViewController : UIViewController <PTFlipsideViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *hogeView;
- (IBAction)captureStillImage;
@end
