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
@property (nonatomic, copy) NSString *currentInputPath;

- (NSString *)processType:(INXMLNode *)type withName:(NSString *)aName mapping:(NSMutableDictionary *)mapping;
- (NSDictionary *)processElement:(INXMLNode *)element withMapping:(NSMutableDictionary *)mapping;
- (NSDictionary *)processAttribute:(INXMLNode *)attribute withMapping:(NSMutableDictionary *)mapping;

- (BOOL)createClass:(NSString *)className withName:(NSString *)bareName forType:(NSString *)indivoType properties:(NSArray *)properties error:(NSError **)error;

- (void)sendLog:(NSString *)aString;

@end


@implementation INClassGenerator

@synthesize numSchemasParsed, numClassesGenerated;
@synthesize writeToDir, currentInputPath;


/**
 *	Run all the XSD schemas we find. Schema files must have the .xsd extension.
 *	@param inputPath A path to a directory containing XSD files or a path to one XSD file
 *	@param outDirectory The directory to write the class files to
 *	@param aCallback Completion block
 */
- (void)runFrom:(NSString *)inputPath into:(NSString *)outDirectory callback:(INCancelErrorBlock)aCallback
{
	numSchemasParsed = 0;
	self.writeToDir = nil;
	
	// check directories
	NSFileManager *fm = [NSFileManager defaultManager];
	BOOL inputIsDir = NO;
	BOOL flag = NO;
	if (![fm fileExistsAtPath:inputPath isDirectory:&inputIsDir]) {
		CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(aCallback, @"Error: Input directory or file does not exist")
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
	NSArray *all = nil;
	if (inputIsDir) {
		all = [fm contentsOfDirectoryAtPath:inputPath error:&error];
		if (!all) {
			NSString *errStr = [error localizedDescription];
			CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(aCallback, errStr)
			return;
		}
	}
	else {
		NSString *file = [inputPath lastPathComponent];
		if (file) {
			all = [NSArray arrayWithObject:file];
			inputPath = [inputPath stringByDeletingLastPathComponent];
		}
	}
	
	NSPredicate *filter = [NSPredicate predicateWithFormat:@"self ENDSWITH '.xsd'"];
	NSArray *xsd = [all filteredArrayUsingPredicate:filter];
	if ([xsd count] < 1) {
		CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(aCallback, @"There were no XSD files in the input path")
		return;
	}
	
	// dispatch
	dispatch_queue_t aQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_async(aQueue, ^{
		NSUInteger i = 0;
		self.numClassesGenerated = 0;
		
		// loop all XSDs
		for (NSString *fileName in xsd) {
			NSString *path = [inputPath stringByAppendingPathComponent:fileName];
			if (![fm fileExistsAtPath:path]) {
				NSString *logStr = [NSString stringWithFormat:@"Schema file does not exist at %@", path];
				[self sendLog:logStr];
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
		self.numSchemasParsed = i;
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
	if (!path) {
		return NO;
	}
	self.currentInputPath = path;
	
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
		NSString *baseDir = [path stringByDeletingLastPathComponent];
		NSFileManager *fm = [NSFileManager defaultManager];
		
		for (INXMLNode *include in includes) {
			NSString *includePath = [baseDir stringByAppendingPathComponent:[include attr:@"schemaLocation"]];
			
			// run include first
			if ([fm fileExistsAtPath:includePath]) {
				self.currentInputPath = includePath;
				if (![self runFile:includePath withMapping:mapping error:error]) {
					return NO;
				}
			}
		}
		self.currentInputPath = path;
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
 *	Parses a <complexType> node and makes sure the class file represented by the type is created.
 *	"attribute" nodes and "sequence > element" nodes are treated equally, both will create a property for the type based on
 *	their name and type.
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
	NSString *capName = [NSString stringWithFormat:@"%@%@", [[name substringToIndex:1] uppercaseString], [name substringFromIndex:1]];
	NSString *className = [NSString stringWithFormat:@"%@%@", INClassGeneratorClassPrefix, capName];
	NSString *indivoTypeName = [NSString stringWithFormat:@"indivo:%@", name];
	if (![mapping objectForKey:indivoTypeName]) {
		[mapping setObject:className forKey:indivoTypeName];
		write = YES;
	}
	else if (![className isEqualToString:[mapping objectForKey:indivoTypeName]]) {
		[self sendLog:[NSString stringWithFormat:@"Apparently, %@ is already known as %@!", className, [mapping objectForKey:indivoTypeName]]];
	}
	
	// read "attributes" nodes
	NSArray *attributes = [type childrenNamed:@"attribute"];
	if ([attributes count] > 0) {
		properties = [NSMutableArray arrayWithCapacity:[attributes count]];
		
		for (INXMLNode *attr in attributes) {
			NSDictionary *attrDict = [self processAttribute:attr withMapping:mapping];
			if (attrDict) {
				[properties addObject:attrDict];
			}
		}
	}
	
	// determine type properties in "sequence > element" nodes
	NSArray *children = [[type childNamed:@"sequence"] childrenNamed:@"element"];
	if ([children count] > 0) {
		if (!properties) {
			properties = [NSMutableArray arrayWithCapacity:[children count]];
		}
		
		for (INXMLNode *element in children) {
			NSDictionary *elemDict = [self processElement:element withMapping:mapping];
			if (elemDict) {
				[properties addObject:elemDict];
			}
		}
	}
	
	// write to file
	if (write) {
		NSError *error = nil;
		if (![self createClass:className withName:name forType:indivoTypeName properties:properties error:&error]) {
			[self sendLog:[NSString stringWithFormat:@"Failed to create class \"%@\": %@", name, [error localizedDescription]]];
		}
	}
	
	return className;
}


/**
 *	Parses an <element> node.
 *	@return A dictionary with these attributes for this element: name, type, class and minOccurs.
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
	
	// do we define the type (i.e. do we have a "complexType" child node)?
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


/**
 *	Processes "attribute" nodes and returns a dictionary with its properties.
 *	@return A dictionary with these attributes for this element: name, type, class and minOccurs.
 */
- (NSDictionary *)processAttribute:(INXMLNode *)attribute withMapping:(NSMutableDictionary *)mapping
{
	NSString *attrName = [attribute attr:@"name"];
	NSString *attrType = [attribute attr:@"type"];
	if (!attrType) {
		attrType = @"";
	}
	
	NSString *minOccurs = [@"required" isEqualToString:[attribute attr:@"use"]] ? @"1" : @"0";
	
	NSString *attrClass = [mapping objectForKey:attrType];
	if ([attrClass length] < 1) {									// not found, try appending "xs:" which is missing sometimes
		NSString *xsType = [@"xs:" stringByAppendingString:attrType];
		attrClass = [mapping objectForKey:xsType];
		if ([attrClass length] < 1) {								// still no luck, give up
			attrClass = [NSString stringWithFormat:@"%@%@", INClassGeneratorClassPrefix, attrType];
			[self sendLog:[NSString stringWithFormat:@"I do not know which class to use for \"%@\", assuming \"%@\"", attrType, attrClass]];
		}
		else {
			attrType = xsType;
		}
	}
	
	// compose and return
	NSDictionary *attrDict = [NSDictionary dictionaryWithObjectsAndKeys:
							  attrName, @"name",
							  attrType, @"type",
							  minOccurs, @"minOccurs",
							  attrClass, @"class", nil];
	return attrDict;
}


/**
 *	Creates a class from the given property array. It uses the class file templates and writes to the "writeToDir" path.
 */
- (BOOL)createClass:(NSString *)className withName:(NSString *)bareName forType:(NSString *)indivoType properties:(NSArray *)properties error:(NSError **)error
{
	// prepare date properties
	NSDateFormatter *df = [NSDateFormatter new];
	df.dateStyle = NSDateFormatterShortStyle;
	df.timeStyle = NSDateFormatterNoStyle;
	NSCalendar *cal = [NSCalendar currentCalendar];
	NSDateComponents *comp = [cal components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:[NSDate date]];
	
	// prepare class properties
	NSMutableString *propString = [NSMutableString string];
	NSMutableArray *synthNames = [NSMutableArray arrayWithCapacity:[properties count]];
	NSMutableArray *forwardClasses = [NSMutableArray array];
	NSMutableArray *nonNilNames = [NSMutableArray array];
	if ([properties count] > 0) {
		for (NSDictionary *propDict in properties) {
			NSString *name = [propDict objectForKey:@"name"];
			NSInteger minOccurs = [[propDict objectForKey:@"minOccurs"] integerValue];
			
			// we do not need "id" properties for subclasses, they all have the "udid" property
			if ([name isEqualToString:@"id"]) {
				continue;
			}
			NSString *className = [propDict objectForKey:@"class"];
			
			// create class property strings
			if (name && className) {
				[propString appendFormat:@"@property (nonatomic, strong) %@ *%@;", className, name];
				if (minOccurs > 0) {
					[propString appendFormat:@"\t\t\t\t\t///< Must not be nil (minOccurs = %lu)", minOccurs];
				}
				[propString appendString:@"\n"];
				[synthNames addObject:name];
			}
			else {
				[self sendLog:[NSString stringWithFormat:@"Error: Missing name or class for property: %@", propDict]];
			}
			
			// collect forward class declarations
			if ([@"Indivo" isEqualToString:[className substringToIndex:6]]) {
				[forwardClasses addObject:[NSString stringWithFormat:@"@class %@;", className]];
			}
			
			// collect properties that must be set
			if (minOccurs > 0) {
				[nonNilNames addObject:[NSString stringWithFormat:@"@\"%@\"", name]];
			}
		}
	}
	NSString *synthString = ([synthNames count] > 0) ? [NSString stringWithFormat:@"@synthesize %@;", [synthNames componentsJoinedByString:@", "]] : @"";
	NSString *nonNilString = ([nonNilNames count] > 0) ? [nonNilNames componentsJoinedByString:@", "] : @"";
	
	NSDictionary *substitutions = [NSDictionary dictionaryWithObjectsAndKeys:
								   @"Indivo Class Generator", @"AUTHOR",
								   [NSString stringWithFormat:@"%d/%d/%d", comp.month, comp.day, comp.year], @"DATE",
								   [NSString stringWithFormat:@"%d", comp.year], @"YEAR",
								   className, @"CLASS_NAME",
								   bareName, @"CLASS_NODENAME",
								   indivoType, @"CLASS_TYPENAME",
								   propString, @"CLASS_PROPERTIES",
								   synthString, @"CLASS_SYNTHESIZE",
								   (indivoType ? indivoType : @"unknown"), @"INDIVO_TYPE",
								   @"", @"CLASS_IMPORTS",
								   [forwardClasses componentsJoinedByString:@"\n"], @"CLASS_FORWARDS",
								   nonNilString, @"CLASS_NON_NIL_NAMES",
								   nil];
	
	// create header
	NSString *header = [[self class] applyToHeaderTemplate:substitutions];
	if (header) {
		NSString *headerPath = [writeToDir stringByAppendingFormat:@"/%@.h", className];
		NSURL *headerURL = [NSURL fileURLWithPath:headerPath];
		
		if (![header writeToURL:headerURL atomically:YES encoding:NSUTF8StringEncoding error:error]) {
			[self sendLog:[NSString stringWithFormat:@"ERROR writing to %@: %@", headerPath, [*error localizedDescription]]];
			return NO;
		}
	}
	
	// create body (i.e. implementation)
	NSString *body = [[self class] applyToBodyTemplate:substitutions];
	if (body) {
		NSString *bodyPath = [writeToDir stringByAppendingFormat:@"/%@.m", className];
		NSURL *bodyURL = [NSURL fileURLWithPath:bodyPath];
		
		if (![body writeToURL:bodyURL atomically:YES encoding:NSUTF8StringEncoding error:error]) {
			[self sendLog:[NSString stringWithFormat:@"ERROR writing to %@: %@", bodyPath, [*error localizedDescription]]];
			return NO;
		}
	}
	
	numClassesGenerated++;
	return YES;
}



#pragma mark - Utilities
- (void)sendLog:(NSString *)aString
{
	runOnMainQueue(^{
		NSString *errString = currentInputPath ? [currentInputPath stringByAppendingFormat:@":  %@", aString] : aString;
		NSDictionary *userInfo = [NSDictionary dictionaryWithObject:errString forKey:INClassGeneratorLogStringKey];
		[[NSNotificationCenter defaultCenter] postNotificationName:INClassGeneratorDidProduceLogNotification object:nil userInfo:userInfo];
	});
}


static NSString *classGeneratorHeaderTemplate = nil;
static NSString *classGeneratorBodyTemplate = nil;


+ (NSString *)applySubstitutions:(NSDictionary *)substitutions toTemplate:(NSString *)aTemplate
{
	if ([substitutions count] < 1) {
		return aTemplate;
	}
	if (!aTemplate) {
		return aTemplate;
	}
	
	// match via RegEx
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(\\{\\{\\s*([^\\}\\s]+)\\s*\\}\\})"
																		   options:NSRegularExpressionCaseInsensitive
																			 error:nil];
	NSArray *matches = [regex matchesInString:aTemplate options:0 range:NSMakeRange(0, [aTemplate length])];
	if ([matches count] > 0) {
		NSMutableString *applied = [aTemplate mutableCopy];
		
		// apply matches
		for (NSTextCheckingResult *match in [matches reverseObjectEnumerator]) {
			NSRange fullRange = [match rangeAtIndex:1];
			NSRange keyRange = [match rangeAtIndex:2];
			NSString *key = [aTemplate substringWithRange:keyRange];
			NSString *replacement = [substitutions objectForKey:key];
			if (replacement) {
				[applied replaceCharactersInRange:fullRange withString:replacement];
			}
			else {
				DLog(@"No replacement for %@ found", key);
			}
		}
		return applied;
	}
	return aTemplate;
}


+ (NSString *)applyToHeaderTemplate:(NSDictionary *)substitutions
{
	if (!classGeneratorHeaderTemplate) {
		NSString *headerPath = [[NSBundle bundleForClass:self] pathForResource:@"GeneratorTemplate" ofType:@"h"];
		if (!headerPath) {
			DLog(@"The header template was not found!");
			return nil;
		}
		
		NSError *error = nil;
		classGeneratorHeaderTemplate = [NSString stringWithContentsOfFile:headerPath encoding:NSUTF8StringEncoding error:&error];
		if (!classGeneratorHeaderTemplate) {
			DLog(@"Error reading the header template: %@", [error localizedDescription]);
			return nil;
		}
	}
	
	return [self applySubstitutions:substitutions toTemplate:classGeneratorHeaderTemplate];
}


+ (NSString *)applyToBodyTemplate:(NSDictionary *)substitutions
{
	// load template if needed
	if (!classGeneratorBodyTemplate) {
		NSString *bodyPath = [[NSBundle bundleForClass:self] pathForResource:@"GeneratorTemplate" ofType:@"m"];
		if (!bodyPath) {
			DLog(@"The body template was not found!");
			return nil;
		}
		
		NSError *error = nil;
		classGeneratorBodyTemplate = [NSString stringWithContentsOfFile:bodyPath encoding:NSUTF8StringEncoding error:&error];
		if (!classGeneratorBodyTemplate) {
			DLog(@"Error reading the body template: %@", [error localizedDescription]);
			return nil;
		}
	}
	
	return [self applySubstitutions:substitutions toTemplate:classGeneratorBodyTemplate];
}


@end
