//
//  NSObject+switch.h
//  ProjectTannai
//
//  Created by Abe Shintaro on 2012/10/23.
//  Copyright (c) 2012年 Abe Shintaro. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (IntegrationSwitch)
- (void)switch:(NSDictionary*)blocks default:(void(^)())defaultBlock;
@end
