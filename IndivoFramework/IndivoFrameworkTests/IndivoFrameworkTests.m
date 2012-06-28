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
		STAssertEqualObjects(@"Bruce", testRecord.demographicsDoc.Name.givenName, @"Given name");
		INTelephone *preferredPhone = nil;
		for (INTelephone *phone in testRecord.demographicsDoc.Telephone) {
			if (phone.preferred.flag) {
				preferredPhone = phone;
				break;
			}
		}
		STAssertNotNil(preferredPhone, @"Finding preferred phone");
		STAssertEqualObjects(@"555-5555", preferredPhone.number, @"Preferred phone number");
		STAssertEqualObjects(@"h", preferredPhone.type.string, @"Preferred phone type");
	}];
	
	// record documents
	[testRecord fetchDocumentsWithCallback:^(BOOL success, NSDictionary *__autoreleasing userInfo) {
		if (!success) {
			THROW(@"Failed to fetch record documents: %@", userInfo);
		}
	}];
	
	IndivoLabResult *newLab = (IndivoLabResult *)[testRecord addDocumentOfClass:[IndivoLabResult class] error:&error];
	if (!newLab) {
		THROW(@"Failed to get new lab result document: %@", [error localizedDescription]);
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
- (void)testDemographics
{
	NSError *error = nil;
	
    // test parsing
	NSString *fixture = [server readFixture:@"demographics"];
	INXMLNode *node = [INXMLParser parseXML:fixture error:&error];
	IndivoDemographics *doc = [[IndivoDemographics alloc] initFromNode:node];
	
	STAssertNotNil(doc, @"Demographics Document");
	STAssertEqualObjects(@"1939-11-15", [doc.dateOfBirth isoString], @"b-day");
	STAssertEqualObjects(@"caucasian", doc.race.string, @"race");
	STAssertEqualObjects(@"555-5555", ((INTelephone *)[doc.Telephone objectAtIndex:0]).number, @"telephone number");
	
	// test value changes
	doc.dateOfBirth.date = [NSDate dateWithTimeIntervalSince1970:1328024441];
	STAssertEqualObjects(@"2012-01-31", [doc.dateOfBirth isoString], @"New birth date");
	INTelephone *new_tel = [INTelephone new];
	new_tel.number = @"617 555-5555";
	doc.Telephone = [NSArray arrayWithObject:new_tel];
	STAssertEqualObjects(@"617 555-5555", ((INTelephone *)[doc.Telephone objectAtIndex:0]).number, @"new phone number");
	
	// test XML generation
	STAssertTrue(NSNotFound != [[doc documentXML] rangeOfString:@"<ethnicity>Scottish</ethnicity>"].location, @"XML generation");
}

- (void)testMedication
{
	NSError *error = nil;
	
    // test parsing
	NSString *fixture = [server readFixture:@"medication"];
	INXMLNode *node = [INXMLParser parseXML:fixture error:&error];
	IndivoMedication *doc = [[IndivoMedication alloc] initFromNode:node forRecord:nil];
	
	STAssertNotNil(doc, @"Medication");
	STAssertEqualObjects(@"2007-03-14T00:00:00Z", [doc.startDate isoString], @"start date");
	STAssertEqualObjects([NSDecimalNumber decimalNumberWithString:@"2"], doc.frequency.value, @"frequency");
	
	IndivoFill *fill = [doc.fulfillments lastObject];
	STAssertTrue([fill isKindOfClass:[IndivoFill class]], @"Fill class");
	STAssertEqualObjects(@"2007-04-14T04:00:00Z", [fill.date isoString], @"Filling date");
	STAssertEqualObjects(@"WonderCity", fill.pharmacy.adr.city, @"Filling pharmacy city");
	
	// test value changes
	fill.date.date = [NSDate dateWithTimeIntervalSince1970:1328024441];
	STAssertEqualObjects(@"2012-01-31T10:40:41Z", [fill.date isoString], @"New filling date");
}

- (void)testAllergy
{
	NSError *error = nil;
	
    // test parsing
	NSString *fixture = [server readFixture:@"allergy"];
	INXMLNode *node = [INXMLParser parseXML:fixture error:&error];
	IndivoAllergy *doc = [[IndivoAllergy alloc] initFromNode:[node childNamed:@"Model"] forRecord:nil];
	
	STAssertNotNil(doc, @"Allergy");
	STAssertEqualObjects(@"Drug allergy", doc.category.title, @"category title");
	STAssertEqualObjects(@"39579001", doc.allergic_reaction.identifier, @"reaction id");
	
	// test XML generation
	STAssertTrue(NSNotFound != [[doc documentXML] rangeOfString:@"<Field name=\"drug_class_allergen_system\">http://purl.bioontology.org/ontology/NDFRT/</Field>"].location, @"XML generation");
}

- (void)testLabPanel
{
	NSError *error = nil;
	
    // test parsing
	NSString *fixture = [server readFixture:@"lab"];
	INXMLNode *node = [INXMLParser parseXML:fixture error:&error];
	IndivoLabResult *doc = [[IndivoLabResult alloc] initFromNode:node forRecord:nil];
	
	STAssertNotNil(doc, @"Lab");
	STAssertEqualObjects(@"2010-12-27T17:00:00Z", [doc.collected_at isoString], @"collection date");
	STAssertEqualObjects(@"Serum Sodium", doc.test_name.title, @"lab type");
	
	INQuantitativeResult *res = doc.quantitative_result;
	NSDecimalNumber *upper = [NSDecimalNumber decimalNumberWithString:@"155"];
	STAssertEqualObjects(upper, res.non_critical_range.max.value, @"upper non critical bound");
	
	// test value changes
	doc.collected_at.date = [NSDate dateWithTimeIntervalSince1970:1328024441];
	STAssertEqualObjects(@"2012-01-31T10:40:41Z", [doc.collected_at isoString], @"changed date");
	INUnitValue *new_upper = [INUnitValue new];
	new_upper.value = upper;
	doc.quantitative_result.normal_range.max = new_upper;
	STAssertEqualObjects(upper, doc.quantitative_result.normal_range.max.value, @"upper non critical bound");
	
	// test XML generation
	STAssertTrue(NSNotFound != [[doc documentXML] rangeOfString:@"<Field name=\"quantitative_result_non_critical_range_min_unit\">mEq/L</Field>"].location, @"XML generation");
}

- (void)testEquipment
{
	NSError *error = nil;
	
    // test parsing
	NSString *fixture = [server readFixture:@"equipment"];
	INXMLNode *node = [INXMLParser parseXML:fixture error:&error];
	IndivoEquipment *doc = [[IndivoEquipment alloc] initFromNode:node forRecord:nil];
	
	STAssertNotNil(doc, @"Equipment Document");
	STAssertEqualObjects(@"2009-02-05T00:00:00Z", [doc.date_started isoString], @"date started");
	STAssertEqualObjects(@"Pacemaker", doc.name.string, @"vendor");
	
	// test value changes
	doc.date_stopped.date = [NSDate dateWithTimeIntervalSince1970:1328024441];
	STAssertEqualObjects(@"2012-01-31T10:40:41Z", [doc.date_stopped isoString], @"New date stopped");
	doc.description = [INString newWithString:@"no description available"];
	STAssertEqualObjects(@"no description available", doc.description.string, @"New description");
	
	// test XML generation
	STAssertTrue(NSNotFound != [[doc documentXML] rangeOfString:@"<Field name=\"vendor\">Acme Medical Devices</Field>"].location, @"XML generation");
}

- (void)testImmunization
{
	NSError *error = nil;
	
    // test parsing
	NSString *fixture = [server readFixture:@"immunization"];
	INXMLNode *node = [INXMLParser parseXML:fixture error:&error];
	IndivoImmunization *doc = [[IndivoImmunization alloc] initFromNode:node forRecord:nil];
	
	STAssertNotNil(doc, @"Immunization Document");
	STAssertEqualObjects(@"2009-05-16T12:00:00Z", [doc.date isoString], @"date");
	STAssertEqualObjects(@"Not Administered", doc.administration_status.title, @"administration status");
	STAssertEqualObjects(@"TYPHOID", doc.product_class.title, @"product class");
	
	// test value changes
	doc.date.date = [NSDate dateWithTimeIntervalSince1970:1328024441];
	STAssertEqualObjects(@"2012-01-31T10:40:41Z", [doc.date isoString], @"New date");
	doc.refusal_reason.title = @"Whatever";
	STAssertEqualObjects(@"Whatever", doc.refusal_reason.title, @"New refusal title");
	
	// test XML generation
	STAssertTrue(NSNotFound != [[doc documentXML] rangeOfString:@"<Field name=\"refusal_reason_system\">http://smartplatforms.org/terms/codes/ImmunizationRefusalReason#</Field>"].location, @"XML generation");
}

- (void)testProblem
{
	NSError *error = nil;
	
    // test parsing
	NSString *fixture = [server readFixture:@"problem"];
	INXMLNode *node = [INXMLParser parseXML:fixture error:&error];
	IndivoProblem *doc = [[IndivoProblem alloc] initFromNode:node forRecord:nil];
	
	STAssertNotNil(doc, @"Problem Document");
	STAssertEqualObjects(@"2009-05-16T12:00:00Z", [doc.startDate isoString], @"onset date");
	STAssertEqualObjects(@"Backache (Finding)", doc.name.title, @"name string");
	
	// test value changes
	doc.endDate.date = [NSDate dateWithTimeIntervalSince1970:1328024441];
	STAssertEqualObjects(@"2012-01-31T10:40:41Z", [doc.endDate isoString], @"New end date");
	
	// test XML generation
	STAssertTrue(NSNotFound != [[doc documentXML] rangeOfString:@"<Field name=\"name_system\">http://purl.bioontology.org/ontology/SNOMEDCT/</Field>"].location, @"XML generation");
}

- (void)testVitalSign
{
	NSError *error = nil;
	
    // test parsing
	NSString *fixture = [server readFixture:@"vitals"];
	INXMLNode *node = [INXMLParser parseXML:fixture error:&error];
	IndivoVitalSigns *doc = [[IndivoVitalSigns alloc] initFromNode:node forRecord:nil];
	
	STAssertNotNil(doc, @"VitalSign Document");
	STAssertEqualObjects(@"2009-05-16T12:00:00Z", [doc.date isoString], @"date");
	STAssertEqualObjects(@"{beats}/min", doc.heart_rate.unit, @"heart rate unit");
	STAssertEqualObjects(@"2009-05-16T16:00:00Z", [doc.encounter.endDate isoString], @"encounter end date");
	STAssertEqualObjects(@"Ambulatory encounter", doc.encounter.encounterType.title, @"encounter type");
	
	STAssertEqualObjects(@"Josuha", doc.encounter.provider.name.givenName, @"given name of the provider");
	STAssertEqualObjects(@"1-235-947-3452", doc.encounter.provider.tel_1.number, @"1st phone number of the provider");
	STAssertEqualObjects(@"w", doc.encounter.provider.tel_1.type.string, @"1st phone number type of the provider");
	
	// test value changes
	doc.date.date = [NSDate dateWithTimeIntervalSince1970:1328024441];
	STAssertEqualObjects(@"2012-01-31T10:40:41Z", [doc.date isoString], @"New measured date");
	
	// test XML generation
	STAssertTrue(NSNotFound != [[doc documentXML] rangeOfString:@"<Field name=\"height_name_identifier\">8302-2</Field>"].location, @"XML generation");
	STAssertTrue(NSNotFound != [[doc documentXML] rangeOfString:@"<Field name=\"provider_tel_1_number\">1-235-947-3452</Field>"].location, @"XML generation");
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
	NSError *error = nil;
	
    // test parsing
	NSString *fixture = [server readFixture:@"procedure"];
	INXMLNode *node = [INXMLParser parseXML:fixture error:&error];
	IndivoProcedure *doc = [[IndivoProcedure alloc] initFromNode:node forRecord:nil];
	
	STAssertNotNil(doc, @"Clinical Procedure Document");
	STAssertEqualObjects(@"Appendectomy", doc.name.string, @"procedure name");
	STAssertEqualObjects(@"2009-05-16T12:00:00Z", [doc.date_performed isoString], @"performed date");
	STAssertEqualObjects(@"Kenneth Mandl", doc.provider_name.string, @"provider name");
	
	// test XML generation
	STAssertTrue(NSNotFound != [[doc documentXML] rangeOfString:@"<Field name=\"name_type\">http://codes.indivo.org/procedures#</Field>"].location, @"XML generation");
	STAssertTrue(NSNotFound != [[doc documentXML] rangeOfString:@"<Field name=\"provider_institution\">Children&#x27;s Hospital Boston</Field>"].location, @"XML generation");
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
	NSLog(@"1000 XML generation calls: %.4f sec", elapsedTimeInNanoseconds / 1000000000);				// 6/26/2012, iMac i7 2.8GHz 4Gig RAM: ~0.16 sec
}


@end
