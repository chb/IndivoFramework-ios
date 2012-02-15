//
//  IndivoFrameworkTests.h
//  IndivoFrameworkTests
//
//  Created by Pascal Pfiffner on 1/20/12.
//  Copyright (c) 2012 Children's Hospital Boston. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

@class IndivoServer;


@interface IndivoFrameworkTests : SenTestCase

@property (nonatomic, strong) IndivoServer *server;

- (NSString *)readFixture:(NSString *)fileName;

@end
