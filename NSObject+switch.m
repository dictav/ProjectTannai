//
//  NSObject+switch.m
//  ProjectTannai
//
//  Created by Abe Shintaro on 2012/10/23.
//  Copyright (c) 2012年 Abe Shintaro. All rights reserved.
//

#import "NSObject+switch.h"

@implementation NSObject (IntegrationSwitch)

- (void)switch:(NSDictionary*)blocks default:(void (^)())defaultBlock
{
    void (^blk)(void) = blocks[self];
    if (blk) {
        blk();
    } else {
        defaultBlock();
    }
}

@end
