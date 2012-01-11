//
//  IndivoFrameworkTests.h
//  IndivoFrameworkTests
//
//  Created by Pascal Pfiffner on 9/2/11.
//  Copyright (c) 2011 Harvard Medical School. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import <UIKit/UIKit.h>

@class IndivoServer;


@interface IndivoFrameworkTests : SenTestCase

@property (nonatomic, strong) IndivoServer *server;

@end
