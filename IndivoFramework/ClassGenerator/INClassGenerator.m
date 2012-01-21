//
//  INClassGenerator.m
//  IndivoFramework
//
//  Created by Pascal Pfiffner on 1/20/12.
//  Copyright (c) 2012 Harvard Medical School. All rights reserved.
//

#import "INClassGenerator.h"
#import "INXMLParser.h"

NSString *const INClassGeneratorDidProduceLogNotification = @"INClassGeneratorDidProduceLog";
NSString *const INClassGeneratorLogStringKey = @"INClassGeneratorLogString";
NSString *const INClassGeneratorClassPrefix = @"Indivo";

#define TLog(fmt, ...) \
	NSString *str = [NSString stringWithFormat:fmt, ##__VA_ARGS__];\
	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:str forKey:INClassGeneratorLogStringKey];\
	[[NSNotificationCenter defaultCenter] postNotificationName:INClassGeneratorDidProduceLogNotification object:nil userInfo:userInfo];\


@implementation INClassGenerator


/**
 *	Run all the XSD schemas we find
 */
- (BOOL)run
{
	// read mappings
	NSString *mapPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"Mapping" ofType:@"plist"];
	NSMutableDictionary *map = [[NSDictionary dictionaryWithContentsOfFile:mapPath] mutableCopy];
	
	// find XSD
	/// @todo Find all XSD schemas
	NSArray *xsd = [NSArray arrayWithObject:@"/Library/Indivo/indivo_server/schemas/doc_schemas/medication.xsd"];
	for (NSString *path in xsd) {
		if (![self runFile:path withMappings:map]) {
			return NO;
		}
	}
	
	return YES;
}


- (BOOL)runFile:(NSString *)path withMappings:(NSMutableDictionary *)mapping
{
	NSFileManager *fm = [NSFileManager defaultManager];
	if (![fm fileExistsAtPath:path]) {
		return NO;
	}
	
	TLog(@"->  %@", path);
	
	// get XML
	NSError *error = nil;
	NSString *xml = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
	if (!xml) {
		TLog(@"xx>  Could not read XML from \"%@\": %@", path, [error localizedDescription]);
		return NO;
	}
	
	// parse XML
	INXMLNode *schema = [INXMLParser parseXML:xml error:&error];
	if (!schema) {
		TLog(@"xx>  Failed to parse XML: %@", [error localizedDescription]);
		return NO;
	}
	
	// find types
	NSArray *types = [schema childrenNamed:@"complexType"];
	if ([types count] < 1) {
		TLog(@"xx>  Did not find any \"complexType\" nodes");
		return NO;
	}
	
	// process types
	for (INXMLNode *type in types) {
		NSString *name = [type attr:@"name"];
		NSMutableArray *children = [[type childNamed:@"sequence"] children];
		TLog(@"-->  Type \"%@\", %lu children", name, [children count]);
		
		// new class name
		NSString *className = [NSString stringWithFormat:@"%@%@", INClassGeneratorClassPrefix, [name capitalizedString]];
		NSString *indivoTypeName = [NSString stringWithFormat:@"indivo:%@", [name capitalizedString]];
		if ([mapping objectForKey:indivoTypeName]) {
			TLog(@"xx>  Apparently, %@ is already known!", className);
		}
		else {
			[mapping setObject:className forKey:indivoTypeName];
		}
		
		// determine properties
		for (INXMLNode *child in children) {
			NSString *cName = [child attr:@"name"];
			NSString *cType = [child attr:@"type"];
			NSUInteger min = 0;//[[child attr:@"minOccurs"] unsignedIntegerValue];
			//NSUInteger max = [[child attr:@"maxOccurs"] unsignedIntegerValue];
			
			TLog(@"--->  Child \"%@\" of type \"%@\"", cName, cType);
			
			// known type
			if ([mapping objectForKey:cType]) {
				
			}
			else {
				
			}
			
			// attribute mandatory?
			if (min > 0) {
				
			}
		}
	}
	
	
	return YES;
}


@end
