//
//  IndivoFrameworkTests.m
//  IndivoFrameworkTests
//
//  Created by Pascal Pfiffner on 1/20/12.
//  Copyright (c) 2012 Children's Hospital Boston. All rights reserved.
//

#import "IndivoFrameworkTests.h"
#import "IndivoMockServer.h"
#import "IndivoDocuments.h"
#import "INXMLParser.h"
#import "NSString+XML.h"
#import <mach/mach_time.h>


/**
 *	Macro that throws an exception, use it like you use NSLog
 */
#define THROW(fmt, ...) \
	NSString *throwMessage = [NSString stringWithFormat:(@"%s (line %d) " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__]; \
	@throw [NSException exceptionWithName:@"Unexpected Response" reason:throwMessage userInfo:nil]


@implementation IndivoFrameworkTests

@synthesize server;


- (void)setUp
{
    [super setUp];
    self.server = [IndivoMockServer serverWithDelegate:nil];
}

- (void)tearDown
{
	self.server = nil;
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



#pragma mark - Response Tests
- (void)testMockResponses
{
	NSError *error = nil;
	IndivoRecord *testRecord = [server activeRecord];
	
	// app specific documents
	[server fetchAppSpecificDocumentsWithCallback:^(BOOL success, NSDictionary *__autoreleasing userInfo) {
		if (!success) {
			THROW(@"Failed to get app specific documents: %@", userInfo);
		}
	}];
	
	// get record info, contact and demographics
	[testRecord fetchRecordInfoWithCallback:^(BOOL userDidCancel, NSString *__autoreleasing errorMessage) {
		if (userDidCancel || errorMessage) {
			THROW(@"We didn't get the record info, but this error: %@", errorMessage);
		}
	}];
	
	[testRecord fetchDemographicsDocumentWithCallback:^(BOOL userDidCancel, NSString *__autoreleasing errorMessage) {
		STAssertEqualObjects(@"1939-11-15", [testRecord.demographicsDoc.dateOfBirth isoString], @"Demographics birthday");
		STAssertEqualObjects(@"Bruce", testRecord.demographicsDoc.Name.givenName.string, @"Given name");
	}];
	
	// record documents
	[testRecord fetchDocumentsWithCallback:^(BOOL success, NSDictionary *__autoreleasing userInfo) {
		if (!success) {
			THROW(@"Failed to fetch record documents: %@", userInfo);
		}
	}];
	
	IndivoLabResult *newLab = (IndivoLabResult *)[testRecord addDocumentOfClass:[IndivoLabResult class] error:&error];
	if (!newLab) {
		THROW(@"Failed to add lab result document: %@", [error localizedDescription]);
	}
	
	// record-app documents
	[testRecord fetchAppSpecificDocumentsWithCallback:^(BOOL success, NSDictionary *__autoreleasing userInfo) {
		if (!success) {
			THROW(@"Failed to fetch app specific documents: %@", userInfo);
		}
	}];
	
	// reports
	/// @todo the mock server currently doesn't parse URL GET parameters, so the report methods will all return the same fixture
	[testRecord fetchReportsOfClass:[newLab class] callback:^(BOOL success, NSDictionary *__autoreleasing userInfo) {
		if (!success) {
			THROW(@"Failed to fetch lab reports: %@", userInfo);
		}
	}];
	
	INQueryParameter *query = [INQueryParameter new];
	query.descending = YES;
	query.dateRangeStart = [NSDate date];
	[testRecord fetchReportsOfClass:[newLab class] withQuery:query callback:^(BOOL success, NSDictionary *__autoreleasing userInfo) {
		if (!success) {
			THROW(@"Failed to fetch lab reports with query %@: %@", query, userInfo);
		}
	}];
	
	// document operations
	[newLab pull:^(BOOL userDidCancel, NSString *__autoreleasing errorMessage) {
		if (!errorMessage) {
			THROW(@"Pull succeeded despite this being a new document");
		}
	}];
	
	[newLab push:^(BOOL userDidCancel, NSString *__autoreleasing errorMessage) {
		if (userDidCancel || errorMessage) {
			THROW(@"Pushing the document failed: %@", errorMessage);
		}
	}];
	
	[newLab pull:^(BOOL userDidCancel, NSString *__autoreleasing errorMessage) {
		if (userDidCancel || errorMessage) {
			THROW(@"Pull failed despite just pushing the document: %@", errorMessage);
		}
	}];
	
	[newLab replace:^(BOOL userDidCancel, NSString *__autoreleasing errorMessage) {
		if (userDidCancel || errorMessage) {
			THROW(@"Replace failed: %@", errorMessage);
		}
	}];
	
	NSString *newLabel = @"a new label";
	[newLab setLabel:newLabel callback:^(BOOL userDidCancel, NSString *__autoreleasing errorMessage) {
		if (![newLabel isEqualToString:newLab.label]) {
			THROW(@"Changing the label failed, is \"%@\", should be \"%@\", error: %@", newLab.label, newLabel, errorMessage);
		}
	}];
	
	[newLab archive:YES forReason:@"just for fun" callback:^(BOOL userDidCancel, NSString *__autoreleasing errorMessage) {
		if (userDidCancel || errorMessage) {
			THROW(@"Archiving failed: %@", errorMessage);
		}
	}];
	
	[newLab void:YES forReason:@"because of Dan" callback:^(BOOL userDidCancel, NSString *__autoreleasing errorMessage) {
		if (userDidCancel || errorMessage) {
			THROW(@"Voiding failed: %@", errorMessage);
		}
	}];
}



#pragma mark - Document XML Tests
- (void)testMedication
{
	NSError *error = nil;
	
    // test parsing
	NSString *med = [server readFixture:@"medication"];
	INXMLNode *medNode = [INXMLParser parseXML:med error:&error];
	IndivoMedication *medication = [[IndivoMedication alloc] initFromNode:medNode forRecord:nil];
	
	STAssertNotNil(medication, @"Medication");
	STAssertEqualObjects(@"2007-03-14T00:00:00Z", [medication.startDate isoString], @"start date");
	STAssertEqualObjects([NSDecimalNumber decimalNumberWithString:@"2"], medication.frequency.value, @"frequency");
	
	IndivoFill *fill = [medication.fulfillments lastObject];
	STAssertTrue([fill isKindOfClass:[IndivoFill class]], @"Fill class");
	STAssertEqualObjects(@"2007-04-14T04:00:00Z", [fill.date isoString], @"Filling date");
	STAssertEqualObjects(@"WonderCity", fill.pharmacy.adr.city.string, @"Filling pharmacy city");
	
	// test value changes
	fill.date.date = [NSDate dateWithTimeIntervalSince1970:1328024441];
	STAssertEqualObjects(@"2012-01-31T10:40:41Z", [fill.date isoString], @"New filling date");
}

- (void)testAllergy
{
#if 0
	NSError *error = nil;
	
    // test parsing
	NSString *med = [server readFixture:@"allergy"];
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
#endif
}

- (void)testLabPanel
{
#if 0
	NSError *error = nil;
	
    // test parsing
	NSString *labXML = [server readFixture:@"lab"];
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
#endif
}

- (void)testEquipment
{
#if 0
	NSError *error = nil;
	
    // test parsing
	NSString *equip = [server readFixture:@"equipment"];
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
#endif
}

- (void)testDemographics
{
#if 0
	NSError *error = nil;
	
    // test parsing
	NSString *fixture = [server readFixture:@"demographics"];
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
#endif
}

- (void)testImmunization
{
#if 0
	NSError *error = nil;
	
    // test parsing
	NSString *fixture = [server readFixture:@"immunization"];
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
#endif
}

- (void)testProblem
{
#if 0
	NSError *error = nil;
	
    // test parsing
	NSString *fixture = [server readFixture:@"problem"];
	INXMLNode *node = [INXMLParser parseXML:fixture error:&error];
	IndivoProblem *doc = [[IndivoProblem alloc] initFromNode:node];
	
	STAssertNotNil(doc, @"Problem Document");
	STAssertEqualObjects(@"2009-05-16T12:00:00Z", [doc.dateOnset isoString], @"onset date");
	STAssertEqualObjects(@"Myocardial Infarction", doc.name.text, @"name string");
	STAssertEqualObjects(@"MI", doc.name.abbrev, @"name abbrev");
	STAssertEqualObjects(@"Dr. Mandl", doc.diagnosedBy.string, @"diagnosed by");
	
	// test value changes
	doc.dateOnset.date = [NSDate dateWithTimeIntervalSince1970:1328024441];
	STAssertEqualObjects(@"2012-01-31T10:40:41Z", [doc.dateOnset isoString], @"New onset date");
	
	// validate
	NSString *xsdPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"problem" ofType:@"xsd"];
	STAssertTrue([INXMLParser validateXML:[doc documentXML] againstXSD:xsdPath error:&error], @"XML Validation failed with error: %@\n%@", [error localizedDescription], [doc documentXML]);
#endif
}

- (void)testVitalSign
{
#if 0
	NSError *error = nil;
	
    // test parsing
	NSString *fixture = [server readFixture:@"vitals"];
	INXMLNode *node = [INXMLParser parseXML:fixture error:&error];
	IndivoVitalSign *doc = [[IndivoVitalSign alloc] initFromNode:node];
	
	STAssertNotNil(doc, @"VitalSign Document");
	STAssertEqualObjects(@"2009-05-16T15:23:21Z", [doc.dateMeasured isoString], @"measured date");
	STAssertEqualObjects(@"Blood Pressure Systolic", doc.name.text, @"name string");
	STAssertEqualObjects(@"BPsys", doc.name.abbrev, @"name abbrev");
	STAssertEqualObjects(@"sitting down", doc.position.string, @"position");
	
	// test value changes
	doc.dateMeasured.date = [NSDate dateWithTimeIntervalSince1970:1328024441];
	STAssertEqualObjects(@"2012-01-31T10:40:41Z", [doc.dateMeasured isoString], @"New measured date");
	
	// validate
	NSString *xsdPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"vitals" ofType:@"xsd"];
	STAssertTrue([INXMLParser validateXML:[doc documentXML] againstXSD:xsdPath error:&error], @"XML Validation failed with error: %@\n%@", [error localizedDescription], [doc documentXML]);
#endif
}

- (void)testClinicalNote
{
#if 0
	NSError *error = nil;
	
    // test parsing
	NSString *fixture = [server readFixture:@"simplenote"];
	INXMLNode *node = [INXMLParser parseXML:fixture error:&error];
	IndivoSimpleClinicalNote *doc = [[IndivoSimpleClinicalNote alloc] initFromNode:node];
	IndivoSignature *signature1 = [doc.signature objectAtIndex:0];
	IndivoSignature *signature2 = [doc.signature objectAtIndex:1];
	
	STAssertNotNil(doc, @"Clinical Note Document");
	STAssertEqualObjects(@"2010-02-03T13:12:00Z", [doc.finalizedAt isoString], @"finalized date");
	STAssertEqualObjects(@"Kenneth Mandl", [signature1.provider.name string], @"signature 1 name");
	STAssertEqualObjects(@"2010-02-03T13:12:00Z", [signature1.at isoString], @"signature 1 date");
	STAssertEqualObjects(@"Isaac Kohane", [signature2.provider.name string], @"signature 2 name");
	
	// validate
	NSString *xsdPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"simplenote" ofType:@"xsd"];
	STAssertTrue([INXMLParser validateXML:[doc documentXML] againstXSD:xsdPath error:&error], @"XML Validation failed with error: %@\n%@", [error localizedDescription], [doc documentXML]);
	
	doc.dateOfVisit = nil;
	STAssertFalse([INXMLParser validateXML:[doc documentXML] againstXSD:xsdPath error:&error], @"XML Validation succeeded when it shouldn't\n%@", [doc documentXML]);
	
	doc.dateOfVisit = [INDateTime now];
	STAssertTrue([INXMLParser validateXML:[doc documentXML] againstXSD:xsdPath error:&error], @"XML Validation failed with error: %@\n%@", [error localizedDescription], [doc documentXML]);
#endif
}

- (void)testProcedure
{
#if 0
	NSError *error = nil;
	
    // test parsing
	NSString *fixture = [server readFixture:@"procedure"];
	INXMLNode *node = [INXMLParser parseXML:fixture error:&error];
	IndivoProcedure *doc = [[IndivoProcedure alloc] initFromNode:node];
	
	STAssertNotNil(doc, @"Clinical Procedure Document");
	STAssertEqualObjects(@"2009-05-16T12:00:00Z", [doc.datePerformed isoString], @"performed date");
	STAssertEqualObjects(@"Kenneth Mandl", [doc.provider.name string], @"provider name");
	
	// validate
	NSString *xsdPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"procedure" ofType:@"xsd"];
	STAssertTrue([INXMLParser validateXML:[doc documentXML] againstXSD:xsdPath error:&error], @"XML Validation failed with error: %@\n%@", [error localizedDescription], [doc documentXML]);
	
	doc.name = nil;
	STAssertFalse([INXMLParser validateXML:[doc documentXML] againstXSD:xsdPath error:&error], @"XML Validation succeeded when it shouldn't\n%@", [doc documentXML]);
	
	doc.name = [INCodedValue new];
	doc.name.text = @"Appendectomy";
	STAssertTrue([INXMLParser validateXML:[doc documentXML] againstXSD:xsdPath error:&error], @"XML Validation failed with error: %@\n%@", [error localizedDescription], [doc documentXML]);
#endif
}

- (void)testSchoolForm
{
#if 0
	NSError *error = nil;
	
    // test creation (no fixture for now)
	IndivoSchoolForm *doc = [IndivoSchoolForm new];
	doc.date = [INDateTime now];
	doc.notes = [INString newWithString:@"A note"];
	
	STAssertNotNil(doc, @"School Form Document");
	
	// validate
	NSString *xsdPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"schoolform" ofType:@"xsd"];
	STAssertTrue([INXMLParser validateXML:[doc documentXML] againstXSD:xsdPath error:&error], @"XML Validation failed with error: %@\n%@", [error localizedDescription], [doc documentXML]);
	
	doc.notes = nil;
	STAssertFalse([INXMLParser validateXML:[doc documentXML] againstXSD:xsdPath error:&error], @"XML Validation succeeded when it shouldn't\n%@", [doc documentXML]);
	
	doc.notes = [INString newWithString:@"My school note"];
	STAssertTrue([INXMLParser validateXML:[doc documentXML] againstXSD:xsdPath error:&error], @"XML Validation failed with error: %@\n%@", [error localizedDescription], [doc documentXML]);
#endif
}




/**
 *	Speed testing XML generation on the lab fixture XML.
 */
- (void)testXMLGeneration
{
	NSError *error = nil;
	NSString *fixture = [server readFixture:@"lab"];
	INXMLNode *node = [INXMLParser parseXML:fixture error:&error];
	IndivoLabResult *doc = [[IndivoLabResult alloc] initFromNode:node forRecord:nil];
	
	// parsed ok?
	STAssertNotNil(doc, @"Lab");
	STAssertEqualObjects(@"2010-12-27T17:00:00Z", [doc.collected_at isoString], @"Collection date");
	STAssertEqualObjects(@"2951-2", doc.test_name.identifier, @"LOINC code");
	
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


@end
