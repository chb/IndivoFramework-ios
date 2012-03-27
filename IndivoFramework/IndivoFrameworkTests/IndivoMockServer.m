//
//  IndivoMockServer.m
//  IndivoFramework
//
//  Created by Pascal Pfiffner on 3/27/12.
//  Copyright (c) 2012 Harvard Medical School. All rights reserved.
//

#import "IndivoMockServer.h"
#import "IndivoRecord.h"
#import "INXMLParser.h"


@implementation IndivoMockServer

@synthesize mockRecord, mockMappings;


- (id)init
{
	if ((self = [super init])) {
		NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"mock-callbacks" ofType:@"plist"];
		if (!path) {
			NSException *e = [NSException exceptionWithName:@"File not found" reason:@"mock-callbacks.plist was not found" userInfo:nil];
			@throw e;
		}
		
		self.mockMappings = [NSDictionary dictionaryWithContentsOfFile:path];
	}
	return self;
}

/**
 *	We return an IndivoRecord object with a constructed ID that will match paths in mock-callbacks.plist
 */
- (IndivoRecord *)activeRecord
{
	if (!mockRecord) {
		self.mockRecord = [[IndivoRecord alloc] initWithId:@"abc" onServer:self];
	}
	return mockRecord;
}


/**
 *	We override perform call, which originally manages the call queue and supplies the OAuth object to server calls. The OAuth object is then responsible for
 *	performing the OAuth dance, if necessary, and then performing the actual call. We bypass this by just returning XML for all paths that are understood (as
 *	declared in mock-callbacks.plist)
 */
- (void)performCall:(INServerCall *)aCall
{
	// which fixture did we want?
	NSDictionary *methodPaths = [mockMappings objectForKey:aCall.HTTPMethod];
	if (!methodPaths) {
		NSString *errorString = [NSString stringWithFormat:@"The HTTP method \"%@\" is not defined in mock-callbacks, cannot test call", aCall.HTTPMethod];
		NSException *e = [NSException exceptionWithName:@"Fixture not defined" reason:errorString userInfo:nil];
		@throw e;
	}
	
	NSString *fixturePath = [methodPaths objectForKey:aCall.method];
	if (!fixturePath) {
		NSString *errorString = [NSString stringWithFormat:@"The REST method \"%@\" with HTTP method \"%@\" is not defined in mock-callbacks, cannot test call", aCall.method, aCall.HTTPMethod];
		NSException *e = [NSException exceptionWithName:@"Fixture not defined" reason:errorString userInfo:nil];
		@throw e;
	}
	
	/// @todo Also take arguments into consideration
	
	// ok, we know about this path, read the fixture...
	NSString *mockResponse = [self readFixture:fixturePath];
	NSMutableDictionary *response = [NSMutableDictionary dictionaryWithObject:mockResponse forKey:INResponseStringKey];
	
	// ...parse it...
	NSError *error = nil;
	INXMLNode *mockDoc = [INXMLParser parseXML:mockResponse error:&error];
	if (mockDoc) {
		[response setObject:mockDoc forKey:INResponseXMLKey];
	}
	
	// ...and hand it to the call
	[aCall finishWith:response];
}



#pragma mark - Utilities
- (NSString *)readFixture:(NSString *)fileName
{
	NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:fileName ofType:@"xml"];
	if (!path) {
		NSException *e = [NSException exceptionWithName:@"File not found" reason:[NSString stringWithFormat:@"The fixture \"%@.xml\" was not found", fileName] userInfo:nil];
		@throw e;
	}
	
	return [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
}


@end
