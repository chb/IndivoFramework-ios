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
#import "NSString+XML.h"
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


- (void)testStringExtensions
{
	NSString *numString = @"14.81";
	NSString *nonNumString1 = @"15a";
	NSString *nonNumString2 = @"Hello World";
	NSString *nonNumString3 = @"Is 6 foot high";
	
	STAssertEqualObjects(@"14.81", [numString numericString], @"numeric string 1");
	STAssertEqualObjects(@"15", [nonNumString1 numericString], @"numeric string 2");
	STAssertEqualObjects(@"", [nonNumString2 numericString], @"numeric string 3");
	STAssertEqualObjects(@"6", [nonNumString3 numericString], @"numeric string 4");
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
	STAssertEqualObjects(@"2009-07-16T12:00:00Z", [lab.dateMeasured isoString], @"measure date");
	STAssertEqualObjects(@"hematology", lab.labType.string, @"lab type");
	
	// test value changes
	lab.dateMeasured.date = [NSDate dateWithTimeIntervalSince1970:1328024441];
	STAssertEqualObjects(@"2012-01-31T10:40:41Z", [lab.dateMeasured isoString], @"changed date");
	
	// validate
	NSString *labXSDPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"lab" ofType:@"xsd"];
	STAssertTrue([INXMLParser validateXML:[lab documentXML] againstXSD:labXSDPath error:&error], @"XML Validation failed with error: %@\n%@", [error localizedDescription], [lab documentXML]);
	
	lab.dateMeasured = nil;
	STAssertFalse([INXMLParser validateXML:[lab documentXML] againstXSD:labXSDPath error:&error], @"XML Validation succeeded when it shouldn't\n%@", [lab documentXML]);
}

- (void)testEquipment
{
	NSError *error = nil;
	
    // test parsing
	NSString *equip = [self readFixture:@"equipment"];
	INXMLNode *node = [INXMLParser parseXML:equip error:&error];
	IndivoEquipment *doc = [[IndivoEquipment alloc] initFromNode:node];
	
	STAssertNotNil(doc, @"Equipment Document");
	STAssertEqualObjects(@"2009-02-05", [doc.dateStarted isoString], @"date started");
	STAssertEqualObjects(@"Acme Medical Devices", doc.vendor.string, @"vendor");
	
	// test value changes
	doc.dateStopped.date = [NSDate dateWithTimeIntervalSince1970:1328024441];
	STAssertEqualObjects(@"2012-01-31", [doc.dateStopped isoString], @"New date stopped");
	doc.specification = [INString newWithString:@"no specification available"];
	STAssertEqualObjects(@"no specification available", doc.specification.string, @"New specification");
	
	// validate
	NSString *xsdPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"equipment" ofType:@"xsd"];
	STAssertTrue([INXMLParser validateXML:[doc documentXML] againstXSD:xsdPath error:&error], @"XML Validation failed with error: %@\n%@", [error localizedDescription], [doc documentXML]);
	
	doc.name = nil;
	STAssertFalse([INXMLParser validateXML:[doc documentXML] againstXSD:xsdPath error:&error], @"XML Validation succeeded when it shouldn't\n%@", [doc documentXML]);
	
	doc.name = [INString new];
	doc.name.string = @"Pacemaker 2000";
	STAssertTrue([INXMLParser validateXML:[doc documentXML] againstXSD:xsdPath error:&error], @"XML Validation failed with error: %@\n%@", [error localizedDescription], [doc documentXML]);
}

- (void)testContact
{
	NSError *error = nil;
	
    // test parsing
	NSString *fixture = [self readFixture:@"contact"];
	INXMLNode *node = [INXMLParser parseXML:fixture error:&error];
	IndivoContact *doc = [[IndivoContact alloc] initFromNode:node];
	IndivoContactEmail *email = [doc.email objectAtIndex:0];
	
	STAssertNotNil(doc, @"Contact Document");
	STAssertEqualObjects(@"Sebastian Rockwell Cotour", [doc.name.fullName string], @"full name");
	STAssertEqualObjects(@"personal", email.type.string, @"email type");
	
	// validate
	NSString *xsdPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"contact" ofType:@"xsd"];
	STAssertTrue([INXMLParser validateXML:[doc documentXML] againstXSD:xsdPath error:&error], @"XML Validation failed with error: %@\n%@", [error localizedDescription], [doc documentXML]);
	
	doc.email = nil;
	STAssertFalse([INXMLParser validateXML:[doc documentXML] againstXSD:xsdPath error:&error], @"XML Validation succeeded when it shouldn't\n%@", [doc documentXML]);
	
	doc.email = [NSArray arrayWithObject:email];
	STAssertTrue([INXMLParser validateXML:[doc documentXML] againstXSD:xsdPath error:&error], @"XML Validation failed with error: %@\n%@", [error localizedDescription], [doc documentXML]);
}

- (void)testDemographics
{
	NSError *error = nil;
	
    // test parsing
	NSString *fixture = [self readFixture:@"demographics"];
	INXMLNode *node = [INXMLParser parseXML:fixture error:&error];
	IndivoDemographics *doc = [[IndivoDemographics alloc] initFromNode:node];
	
	STAssertNotNil(doc, @"Equipment Document");
	STAssertEqualObjects(@"2095-10-11", [doc.dateOfDeath isoString], @"death date");
	STAssertEqualObjects(@"Tailor", doc.occupation.string, @"occupation");
	
	// test value changes
	doc.dateOfBirth.date = [NSDate dateWithTimeIntervalSince1970:1328024441];
	STAssertEqualObjects(@"2012-01-31", [doc.dateOfBirth isoString], @"New birth date");
	doc.organDonor = [INBool newYes];
	STAssertTrue(doc.organDonor.flag, @"New organ donor");
	
	// validate
	NSString *xsdPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"demographics" ofType:@"xsd"];
	STAssertTrue([INXMLParser validateXML:[doc documentXML] againstXSD:xsdPath error:&error], @"XML Validation failed with error: %@\n%@", [error localizedDescription], [doc documentXML]);
}

- (void)testImmunization
{
	NSError *error = nil;
	
    // test parsing
	NSString *fixture = [self readFixture:@"immunization"];
	INXMLNode *node = [INXMLParser parseXML:fixture error:&error];
	IndivoImmunization *doc = [[IndivoImmunization alloc] initFromNode:node];
	
	STAssertNotNil(doc, @"Immunization Document");
	STAssertEqualObjects(@"2009-05-16T12:00:00Z", [doc.dateAdministered isoString], @"administration date");
	STAssertEqualObjects(@"Children's Hospital Boston", doc.administeredBy.string, @"administered by");
	STAssertEqualObjects(@"hep-B", doc.vaccine.type.value, @"vaccine type");
	STAssertEqualObjects(@"2009-06-01", [doc.vaccine.expiration isoString], @"expiration date");
	STAssertEqualObjects(@"Shoulder", doc.anatomicSurface.text, @"injection site");
	
	// test value changes
	doc.dateAdministered.date = [NSDate dateWithTimeIntervalSince1970:1328024441];
	STAssertEqualObjects(@"2012-01-31T10:40:41Z", [doc.dateAdministered isoString], @"New administration date");
	doc.vaccine.manufacturer = [INString newWithString:@"Novartis Pharma"];
	STAssertEqualObjects(@"Novartis Pharma", doc.vaccine.manufacturer.string, @"New manufacturer");
	
	// validate
	NSString *xsdPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"immunization" ofType:@"xsd"];
	STAssertTrue([INXMLParser validateXML:[doc documentXML] againstXSD:xsdPath error:&error], @"XML Validation failed with error: %@\n%@", [error localizedDescription], [doc documentXML]);
}


/**
 *	Speed testing XML generation on the lab fixture XML.
 */
- (void)testXMLGeneration
{
	NSError *error = nil;
	NSString *fixture = [self readFixture:@"lab"];
	INXMLNode *node = [INXMLParser parseXML:fixture error:&error];
	IndivoLab *doc = [[IndivoLab alloc] initFromNode:node];
	
	// parsed ok?
	STAssertNotNil(doc, @"Lab");
	STAssertEqualObjects(@"2009-07-16T12:00:00Z", [doc.dateMeasured isoString], @"measure date");
	STAssertEqualObjects(@"hematology", doc.labType.string, @"lab type");
	
	// timing
	mach_timebase_info_data_t timebase;
	mach_timebase_info(&timebase);
	double ticksToNanoseconds = (double)timebase.numer / timebase.denom;
	uint64_t startTime = mach_absolute_time();
	
	NSUInteger i = 0;
	for (; i < 1000; i++) {
		[doc documentXML];
	}
	
	uint64_t elapsedTime = mach_absolute_time() - startTime;
	double elapsedTimeInNanoseconds = elapsedTime * ticksToNanoseconds;
	NSLog(@"1'000 XML generation calls: %.4f sec", elapsedTimeInNanoseconds / 1000000000);				// 2/2/2012, iMac i7 2.8GHz 4Gig RAM: ~0.6 sec
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
