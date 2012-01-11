//
//  IndivoFrameworkTests.m
//  IndivoFrameworkTests
//
//  Created by Pascal Pfiffner on 9/2/11.
//  Copyright (c) 2011 Harvard Medical School. All rights reserved.
//

#import "IndivoFrameworkTests.h"
#import "IndivoServer.h"

@implementation IndivoFrameworkTests

@synthesize server;


- (void)setUp
{
    [super setUp];
	NSURL *servURL = [NSURL URLWithString:@"http://localhost:8000"];
	NSURL *uiURL = [NSURL URLWithString:@"http://localhost:8001"];
    self.server = [IndivoServer serverWithURL:servURL uiURL:uiURL];
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
