//
//  KYEmbedMainControllerSegue.m
//  KYDrawerController
//
//  Created by Yifei Zhou on 1/8/16.
//  Copyright © 2016 Yifei Zhou. All rights reserved.
//

#import "KYEmbedMainControllerSegue.h"
#import "KYDrawerController.h"

@implementation KYEmbedMainControllerSegue

- (void)perform
{
    if ([self.sourceViewController isKindOfClass:[KYDrawerController class]]) {
        KYDrawerController *drawerController = self.sourceViewController;
        drawerController.mainViewController = self.destinationViewController;
    } else {
        NSAssert(NO, @"SourceViewController must be KYDrawerController!");
    }
}

@end
