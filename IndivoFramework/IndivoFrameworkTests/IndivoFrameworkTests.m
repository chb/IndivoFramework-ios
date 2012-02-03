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
#import <mach/mach_time.h>


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
	STAssertTrue([INXMLParser validateXML:[medication documentXML] againstXSD:medXSDPath error:&error], @"XML Validation failed with error: %@\n%@", [error localizedDescription], [medication documentXML]);
	
	medication.frequency = nil;
	STAssertFalse([INXMLParser validateXML:[medication documentXML] againstXSD:medXSDPath error:&error], @"XML Validation succeeded when it shouldn't\n%@", [medication documentXML]);
}

- (void)testAllergy
{
	NSError *error = nil;
	
    // test parsing
	NSString *med = [self readFixture:@"allergy"];
	INXMLNode *node = [INXMLParser parseXML:med error:&error];
	IndivoAllergy *doc = [[IndivoAllergy alloc] initFromNode:node];
	
	STAssertNotNil(doc, @"Allergy");
	STAssertEqualObjects(@"2009-05-16", [doc.dateDiagnosed isoString], @"date diagnosed");
	STAssertEqualObjects(@"blue rash", doc.reaction.string, @"reaction");
	
	// test allergens
	IndivoAllergyAllergen *allergen = doc.allergen;
	STAssertEqualObjects(@"drugs", allergen.type.value, @"allergen: %@", [allergen xml]);
	
	// test value changes
	doc.dateDiagnosed.date = [NSDate dateWithTimeIntervalSince1970:1328024441];
	STAssertEqualObjects(@"2012-01-31", [doc.dateDiagnosed isoString], @"New date diagnosed");
	doc.specifics = [INString newWithString:@"happens on weekends and Tuesdays"];
	STAssertEqualObjects(@"happens on weekends and Tuesdays", doc.specifics.string, @"New specifics");
	
	// validate
	NSString *xsdPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"allergy" ofType:@"xsd"];
	STAssertTrue([INXMLParser validateXML:[doc documentXML] againstXSD:xsdPath error:&error], @"XML Validation failed with error: %@\n%@", [error localizedDescription], [doc documentXML]);
	
	doc.allergen = nil;
	STAssertFalse([INXMLParser validateXML:[doc documentXML] againstXSD:xsdPath error:&error], @"XML Validation succeeded when it shouldn't\n%@", [doc documentXML]);
	
	doc.allergen = [IndivoAllergyAllergen new];
	doc.allergen.type = [INCodedValue new];
	doc.allergen.name = [INCodedValue new];
	STAssertTrue([INXMLParser validateXML:[doc documentXML] againstXSD:xsdPath error:&error], @"XML Validation failed with error: %@\n%@", [error localizedDescription], [doc documentXML]);
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
	
	// timing
	mach_timebase_info_data_t timebase;
	mach_timebase_info(&timebase);
	double ticksToNanoseconds = (double)timebase.numer / timebase.denom;
	uint64_t startTime = mach_absolute_time();
	
	NSUInteger i = 0;
	for (; i < 1000; i++) {
		[lab documentXML];
	}
	
	uint64_t elapsedTime = mach_absolute_time() - startTime;
	double elapsedTimeInNanoseconds = elapsedTime * ticksToNanoseconds;
	NSLog(@"1'000 XML generation calls: %.4f sec", elapsedTimeInNanoseconds / 1000000000);				// 2/2/2012, iMac i7 2.8: ~0.6 sec
	
	// validate
	NSString *labXSDPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"lab" ofType:@"xsd"];
	STAssertTrue([INXMLParser validateXML:[lab documentXML] againstXSD:labXSDPath error:&error], @"XML Validation failed with error: %@\n%@", [error localizedDescription], [lab documentXML]);
	
	lab.dateMeasured = nil;
	STAssertFalse([INXMLParser validateXML:[lab documentXML] againstXSD:labXSDPath error:&error], @"XML Validation succeeded when it shouldn't\n%@", [lab documentXML]);
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
