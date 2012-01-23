//
//  INClassGenerator.m
//  IndivoFramework
//
//  Created by Pascal Pfiffner on 1/20/12.
//  Copyright (c) 2012 Harvard Medical School. All rights reserved.
//

#import "INClassGenerator.h"
#import <dispatch/dispatch.h>
#import "INXMLParser.h"


NSString *const INClassGeneratorDidProduceLogNotification = @"INClassGeneratorDidProduceLog";
NSString *const INClassGeneratorLogStringKey = @"INClassGeneratorLogString";
NSString *const INClassGeneratorClassPrefix = @"Indivo";
NSString *const INClassGeneratorTypePrefix = @"indivo";


void runOnMainQueue(dispatch_block_t block)
{
	if ([NSThread isMainThread]) {
		block();
	}
	else {
		dispatch_async(dispatch_get_main_queue(), block);
	}
}


@interface INClassGenerator ()

@property (nonatomic, copy) NSString *writeToDir;

- (NSString *)processType:(INXMLNode *)type withName:(NSString *)aName mapping:(NSMutableDictionary *)mapping;
- (NSDictionary *)processElement:(INXMLNode *)element withMapping:(NSMutableDictionary *)mapping;

- (void)sendLog:(NSString *)aString;

@end


@implementation INClassGenerator

@synthesize numSchemasGenerated, writeToDir;


/**
 *	Run all the XSD schemas we find
 */
- (void)runFrom:(NSString *)inDirectory into:(NSString *)outDirectory callback:(INCancelErrorBlock)aCallback
{
	numSchemasGenerated = 0;
	self.writeToDir = nil;
	
	// check directories
	NSFileManager *fm = [NSFileManager defaultManager];
	BOOL flag = NO;
	if (![fm fileExistsAtPath:inDirectory isDirectory:&flag] || !flag) {
		CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(aCallback, @"Error: Input directory does not exist")
		return;
	}
	if (![fm fileExistsAtPath:outDirectory isDirectory:&flag] || !flag) {
		CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(aCallback, @"Error: Output directory does not exist")
		return;
	}
	self.writeToDir = outDirectory;
	
	// read mappings
	NSString *mapPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"Mapping" ofType:@"plist"];
	NSMutableDictionary *map = [[NSDictionary dictionaryWithContentsOfFile:mapPath] mutableCopy];
	if (!map) {
		CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(aCallback, @"Did not find Mapping.plist, cannot continue")
		return;
	}
	
	// find XSD
	__block NSError *error = nil;
	NSArray *all = [fm contentsOfDirectoryAtPath:inDirectory error:&error];
	if (!all) {
		NSString *errStr = [error localizedDescription];
		CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(aCallback, errStr)
		return;
	}
	
	NSPredicate *filter = [NSPredicate predicateWithFormat:@"self ENDSWITH '.xsd'"];
	NSArray *xsd = [all filteredArrayUsingPredicate:filter];
	if ([xsd count] < 1) {
		CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(aCallback, @"There were no XSD files in the input directory")
		return;
	}
	
	// dispatch
	dispatch_queue_t aQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_async(aQueue, ^{
		NSUInteger i = 0;
		for (NSString *fileName in xsd) {
			NSString *path = [inDirectory stringByAppendingPathComponent:fileName];
			if (![fm fileExistsAtPath:path]) {
				NSString *errMsg = [NSString stringWithFormat:@"Schema file \"%@\" does not exist", path];
				[self sendLog:errMsg];
			}
			
			// ** run the file
			else if (![self runFile:path withMapping:map error:&error]) {
				[self sendLog:[error localizedDescription]];
			}
			else {
				i++;
			}
		}
		
		// done
		self.numSchemasGenerated = i;
		if (aCallback) {
			runOnMainQueue(^{
				aCallback(NO, nil);
			});
		}
	});
}


/**
 *	Runs the given file
 */
- (BOOL)runFile:(NSString *)path withMapping:(NSMutableDictionary *)mapping error:(NSError **)error
{
	DLog(@"->  %@", path);
	
	// get XML
	NSString *xml = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:error];
	if (!xml) {
		return NO;
	}
	
	// parse XML
	INXMLNode *schema = [INXMLParser parseXML:xml error:error];
	if (!schema) {
		return NO;
	}
	
	// process includes first
	NSArray *includes = [schema childrenNamed:@"include"];
	if ([includes count] > 0) {
		DLog(@"--->  Should process includes first: %@", includes);
	}
	
	// type definitions at the top level?
	NSArray *types = [schema childrenNamed:@"complexType"];
	if ([types count] > 0) {
		for (INXMLNode *type in types) {
			[self processType:type withName:nil mapping:mapping];
		}
	}
	
	// do we define elements?
	NSArray *elements = [schema childrenNamed:@"element"];
	if ([elements count] > 0) {
		for (INXMLNode *element in elements) {
			[self processElement:element withMapping:mapping];
		}
	}
	
	return YES;
}


/**
 *	Parsen a <completType> node and makes sure the class file represented by the type is created
 *	@return The class name for this type.
 */
- (NSString *)processType:(INXMLNode *)type withName:(NSString *)aName mapping:(NSMutableDictionary *)mapping
{
	BOOL write = NO;
	NSMutableArray *properties = nil;
	NSString *name = aName ? aName : [type attr:@"name"];
	if ([name length] < 1) {
		[self sendLog:@"Cannot process type without a name"];
		return nil;
	}
	
	// the class name
	NSString *className = [NSString stringWithFormat:@"%@%@", INClassGeneratorClassPrefix, [name capitalizedString]];
	NSString *indivoTypeName = [NSString stringWithFormat:@"indivo:%@", [name capitalizedString]];
	if ([mapping objectForKey:indivoTypeName]) {
		DLog(@"Apparently, %@ is already known as %@!", className, [mapping objectForKey:indivoTypeName]);
	}
	else {
		[mapping setObject:className forKey:indivoTypeName];
		write = YES;
	}
	
	// determine attributes
	NSArray *attributes = [type childrenNamed:@"attribute"];
	if ([attributes count] > 0) {
		for (INXMLNode *attr in attributes) {
			DLog(@"---->  Attribute %@ in %@", [attr attr:@"name"], name);
		}
	}
	
	// determine type properties
	NSArray *children = [[type childNamed:@"sequence"] childrenNamed:@"element"];
	DLog(@"-->  Type \"%@\", %lu children", name, [children count]);
	if ([children count] > 0) {
		properties = [NSMutableArray arrayWithCapacity:[children count]];
		for (INXMLNode *element in children) {
			NSDictionary *elemDict = [self processElement:element withMapping:mapping];
			if (elemDict) {
				[properties addObject:elemDict];
			}
		}
	}
	
	// write to file
	if (write) {
		DLog(@"==>  Did process %@, SHOULD NOW GENERATE THE CLASS FILE WITH %@", name, properties);
		
	}
	DLog(@"==>  Finished type %@", name);
	return name;
}


/**
 *	Parses an <element> node.
 *	@return A dictionary with important attributes for this element.
 */
- (NSDictionary *)processElement:(INXMLNode *)element withMapping:(NSMutableDictionary *)mapping
{
	NSString *cName = [element attr:@"name"];
	NSString *cType = [element attr:@"type"];
	if (!cType) {
		cType = @"";
	}
	NSUInteger min = [[element attr:@"minOccurs"] integerValue];
	//NSUInteger max = [[element attr:@"maxOccurs"] integerValue];
	NSString *useClass = nil;
	
	DLog(@"--->  Element \"%@\"", cName);
	
	// do we define the type?
	INXMLNode *type = [element childNamed:@"complexType"];
	if (type) {
		useClass = [self processType:type withName:cName mapping:mapping];
	}
	
	// type of element
	if ([cType length] > 0 && !useClass) {
		useClass = [mapping objectForKey:cType];
		if ([useClass length] < 1) {									// not found, try appending "xs:" which is missing sometimes
			NSString *xsType = [@"xs:" stringByAppendingString:cType];
			useClass = [mapping objectForKey:xsType];
			if ([useClass length] < 1) {								// still no luck, give up
				useClass = [NSString stringWithFormat:@"%@%@", INClassGeneratorClassPrefix, cType];
				[self sendLog:[NSString stringWithFormat:@"I do not know which class to use for \"%@\", assuming \"%@\"", cType, useClass]];
			}
			else {
				cType = xsType;
			}
		}
	}
	
	return [NSDictionary dictionaryWithObjectsAndKeys:cName, @"name", cType, @"type", [NSNumber numberWithInteger:min], @"minOccurs", useClass, @"class", nil];
}



#pragma mark - Utilities
- (void)sendLog:(NSString *)aString
{
	runOnMainQueue(^{
		NSDictionary *userInfo = [NSDictionary dictionaryWithObject:aString forKey:INClassGeneratorLogStringKey];
		[[NSNotificationCenter defaultCenter] postNotificationName:INClassGeneratorDidProduceLogNotification object:nil userInfo:userInfo];
	});
}


@end
