//
//  IndivoFrameworkTests.m
//  IndivoFrameworkTests
//
//  Created by Pascal Pfiffner on 1/20/12.
//  Copyright (c) 2012 Children's Hospital Boston. All rights reserved.
//

#import "IndivoFrameworkTests.h"
#import "IndivoServer.h"

@implementation IndivoFrameworkTests

@synthesize server;


- (void)setUp
{
    [super setUp];
    self.server = [IndivoServer serverWithDelegate:nil];
}

- (void)tearDown
{
	self.server = nil;
    [super tearDown];
}

- (void)testExample
{
    // try to call the login page
	[server selectRecord:^(BOOL userDidCancel, NSString *__autoreleasing errorMessage) {
		NSLog(@"Message: %@", errorMessage);
	}];
}

@end
