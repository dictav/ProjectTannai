//
//  PTFlipsideViewController.m
//  ProjectTannai
//
//  Created by Abe Shintaro on 2012/10/16.
//  Copyright (c) 2012年 Abe Shintaro. All rights reserved.
//

#import "PTFlipsideViewController.h"

@interface PTFlipsideViewController ()

@end

@implementation PTFlipsideViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions

- (IBAction)done:(id)sender
{
    [self.delegate flipsideViewControllerDidFinish:self];
}

- (void)viewDidUnload {
    [self setHogeVIew:nil];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSURL *dir = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *url = [dir URLByAppendingPathComponent:@"hoge.png"];

    NSLog(@"file url:%@", url);
    NSData *data = [NSData dataWithContentsOfURL:url];
    if (!data) {
        NSLog(@"couldn't create data");
    } else {
    _hogeVIew.image = [UIImage imageWithData:data];
    }
}
@end
