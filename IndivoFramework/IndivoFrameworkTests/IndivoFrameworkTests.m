//
//  IndivoFrameworkTests.m
//  IndivoFrameworkTests
//
//  Created by Pascal Pfiffner on 1/20/12.
//  Copyright (c) 2012 Children's Hospital Boston. All rights reserved.
//

#import "IndivoFrameworkTests.h"
#import "IndivoServer.h"
#import "IndivoDocuments.h"
#import "INXMLParser.h"


@implementation IndivoFrameworkTests

@synthesize server;


- (void)setUp
{
    [super setUp];
    //self.server = [IndivoServer serverWithDelegate:nil];
}

- (void)tearDown
{
	//self.server = nil;
    [super tearDown];
}

- (void)testMedication
{
	NSError *error = nil;
	
    // test parsing
	NSString *med = [self readFixture:@"medication"];
	INXMLNode *medNode = [INXMLParser parseXML:med error:&error];
	IndivoMedication *medication = [[IndivoMedication alloc] initFromNode:medNode];
	
	STAssertNotNil(medication, @"Medication");
	STAssertEqualObjects(@"2009-02-05", [medication.dateStarted isoString], @"start date");
	STAssertEqualObjects(@"daily", medication.frequency.value, @"frequency");
	
	IndivoPrescription *pres = medication.prescription;
	STAssertTrue([pres isKindOfClass:[IndivoPrescription class]], @"Prescription class");
	STAssertEqualObjects(@"2009-02-01", [pres.on isoString], @"Prescription start");
	STAssertEqualObjects(@"once a month for 3 months", pres.refillInfo.string, @"Prescription refill info");
	
	// test value changes
	pres.stopOn.date = [NSDate dateWithTimeIntervalSince1970:1328024441];
	STAssertEqualObjects(@"2012-01-31", [pres.stopOn isoString], @"Stop date");
	
	// validate
	NSString *medXSDPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"medication" ofType:@"xsd"];
	STAssertTrue([INXMLParser validateXML:[medication xml] againstXSD:medXSDPath error:&error], @"XML Validation failed with error: %@\n%@", [error localizedDescription], [medication xml]);
	
	medication.frequency = nil;
	STAssertFalse([INXMLParser validateXML:[medication xml] againstXSD:medXSDPath error:&error], @"XML Validation succeeded when it shouldn't\n%@", [medication xml]);
}

- (void)testLabPanel
{
	NSError *error = nil;
	
    // test parsing
	NSString *labXML = [self readFixture:@"lab"];
	INXMLNode *labNode = [INXMLParser parseXML:labXML error:&error];
	IndivoLab *lab = [[IndivoLab alloc] initFromNode:labNode];
	
	STAssertNotNil(lab, @"Lab");
	STAssertEqualObjects(@"2009-07-16T12:00:00", [lab.dateMeasured isoString], @"measure date");
	STAssertEqualObjects(@"hematology", lab.labType.string, @"lab type");
	
	// test value changes
	lab.dateMeasured.date = [NSDate dateWithTimeIntervalSince1970:1328024441];
	STAssertEqualObjects(@"2012-01-31T10:40:41", [lab.dateMeasured isoString], @"changed date");
	NSLog(@"%@", [lab xml]);
	
	// validate
	NSString *labXSDPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"lab" ofType:@"xsd"];
	STAssertTrue([INXMLParser validateXML:[lab xml] againstXSD:labXSDPath error:&error], @"XML Validation failed with error: %@\n%@", [error localizedDescription], [lab xml]);
	
	lab.dateMeasured = nil;
	STAssertFalse([INXMLParser validateXML:[lab xml] againstXSD:labXSDPath error:&error], @"XML Validation succeeded when it shouldn't\n%@", [lab xml]);
}


#pragma mark - Utilities
- (NSString *)readFixture:(NSString *)fileName
{
	NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:fileName ofType:@"xml"];
	if (!path) {
		NSException *e = [NSException exceptionWithName:@"File not found" reason:[NSString stringWithFormat:@"The file \"%@\" was not found", fileName] userInfo:nil];
		@throw e;
	}
	
	return [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
}


@end
