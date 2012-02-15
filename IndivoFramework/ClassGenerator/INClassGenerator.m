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
NSString *const INClassGeneratorBaseClass = @"IndivoDocument";


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

@property (nonatomic, copy) NSString *writeToDir;						///< Path to the directory to put the class files into.
@property (nonatomic, copy) NSString *currentInputPath;					///< Set by "runFile:".
@property (nonatomic, strong) NSMutableArray *typeStack;				///< Every time we encounter a type definition, its name is pushed here so we always know where we are.

- (NSDictionary *)processType:(INXMLNode *)type withMapping:(NSMutableDictionary *)mapping;
- (NSDictionary *)processElement:(INXMLNode *)element withMapping:(NSMutableDictionary *)mapping;
- (NSDictionary *)processAttribute:(INXMLNode *)attribute withMapping:(NSMutableDictionary *)mapping;

- (BOOL)createClass:(NSString *)className
		   withName:(NSString *)bareName
		 superclass:(NSString *)superclass
			forType:(NSString *)indivoType
		 properties:(NSArray *)properties
			  error:(NSError **)error;

- (void)sendLog:(NSString *)aString;

@end


@implementation INClassGenerator

@synthesize mayOverwriteExisting;
@synthesize numSchemasParsed, numClassesGenerated, numClassesSkipped, numClassesNotOverwritten;
@synthesize writeToDir, currentInputPath, typeStack;


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
		CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(aCallback, NO, @"Error: Input directory or file does not exist")
		return;
	}
	if (![fm fileExistsAtPath:outDirectory isDirectory:&flag] || !flag) {
		CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(aCallback, NO, @"Error: Output directory does not exist")
		return;
	}
	self.writeToDir = outDirectory;
	
	// read mappings
	NSString *mapPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"Mapping" ofType:@"plist"];
	NSMutableDictionary *map = [[NSDictionary dictionaryWithContentsOfFile:mapPath] mutableCopy];
	if (!map) {
		CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(aCallback, NO, @"Did not find Mapping.plist, cannot continue")
		return;
	}
	
	// find XSD
	__block NSError *error = nil;
	NSArray *all = nil;
	if (inputIsDir) {
		all = [fm contentsOfDirectoryAtPath:inputPath error:&error];
		if (!all) {
			NSString *errStr = [error localizedDescription];
			CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(aCallback, NO, errStr)
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
		CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(aCallback, NO, @"There were no XSD files in the input path")
		return;
	}
	
	// dispatch
	dispatch_queue_t aQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_async(aQueue, ^{
		NSUInteger i = 0;
		self.numClassesGenerated = 0;
		self.numClassesSkipped = 0;
		self.numClassesNotOverwritten = 0;
		
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
	
	if (!typeStack) {
		self.typeStack = [NSMutableArray array];
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
			/// @todo Do we need to handle this more carefully here?
			[self processType:type withMapping:mapping];
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
 *	@return A dictionary containing a "className" element with the class name and possibly a "superclass" containing the superclass name.
 */
- (NSDictionary *)processType:(INXMLNode *)type withMapping:(NSMutableDictionary *)mapping
{
	BOOL write = NO;
	NSMutableArray *properties = nil;
	NSString *name = [type attr:@"name"];
	NSString *superclass = nil;
	if ([name length] < 1) {
		[self sendLog:@"Cannot process type without a name"];
		return nil;
	}
	
	// the class name
	NSString *ucFirstName = [NSString stringWithFormat:@"%@%@", [[name substringToIndex:1] uppercaseString], [name substringFromIndex:1]];
	NSString *className = [NSString stringWithFormat:@"%@%@", INClassGeneratorClassPrefix, ucFirstName];
	NSString *indivoTypeName = [NSString stringWithFormat:@"indivo:%@", name];
	if (![mapping objectForKey:indivoTypeName]) {
		if ([self ignoresType:indivoTypeName]) {
			numClassesSkipped++;
			className = [NSString stringWithFormat:@"<# Class %@ is on the ignore list #>", className];
		}
		else {
			write = YES;
		}
		
		[mapping setObject:className forKey:indivoTypeName];
	}
	else if (![className isEqualToString:[mapping objectForKey:indivoTypeName]]) {
		//[self sendLog:[NSString stringWithFormat:@"Apparently, %@ is already known as %@!", className, [mapping objectForKey:indivoTypeName]]];
	}
	
	[typeStack addObject:name];
	
	// get definitions (attributes and sequence/element) from the correct node
	NSArray *attributes = nil;
	NSArray *elements = nil;
	INXMLNode *content = [type childNamed:@"complexContent"];
	if (!content) {
		content = [type childNamed:@"simpleContent"];
	}
	
	// determine the superclass
	INXMLNode *extension = [content childNamed:@"extension"];
	if (extension) {
		NSString *base = [extension attr:@"base"];
		superclass = [mapping objectForKey:base];
		if (!superclass) {
			DLog(@"There is no mapping for \"%@\", assuming class \"%@\"", base, base);
			superclass = base;
		}
		attributes = [extension childrenNamed:@"attribute"];
		elements = [[extension childNamed:@"sequence"] childrenNamed:@"element"];
		
		/// @todo Check for restrictions
	}
	else {
		attributes = [type childrenNamed:@"attribute"];
		elements = [[type childNamed:@"sequence"] childrenNamed:@"element"];
	}
	
	// parse attributes
	if ([attributes count] > 0) {
		properties = [NSMutableArray arrayWithCapacity:[attributes count]];
		
		for (INXMLNode *attr in attributes) {
			NSDictionary *attrDict = [self processAttribute:attr withMapping:mapping];
			if (attrDict) {
				[properties addObject:attrDict];
			}
		}
	}
	
	// parse elements
	if ([elements count] > 0) {
		if (!properties) {
			properties = [NSMutableArray arrayWithCapacity:[elements count]];
		}
		
		for (INXMLNode *element in elements) {
			NSDictionary *elemDict = [self processElement:element withMapping:mapping];
			if (elemDict) {
				[properties addObject:elemDict];
			}
		}
	}
	
	// write to file
	if (write) {
		NSError *error = nil;
		if (![self createClass:className withName:name superclass:superclass forType:indivoTypeName properties:properties error:&error]) {
			[self sendLog:[NSString stringWithFormat:@"Failed to create class \"%@\": %@", name, [error localizedDescription]]];
		}
		else {
			[self sendLog:[NSString stringWithFormat:@"Created class \"%@\" for \"%@\"", className, name]];
		}
	}
	
	[typeStack removeLastObject];
	return [NSDictionary dictionaryWithObjectsAndKeys:indivoTypeName, @"type", className, @"className", superclass, @"superclass", nil];
}


/**
 *	Parses an <element> node.
 *	@return A dictionary with these attributes for this element: name, type, class, minOccurs and comment.
 */
- (NSDictionary *)processElement:(INXMLNode *)element withMapping:(NSMutableDictionary *)mapping
{
	NSString *name = [element attr:@"name"];
	NSString *type = [element attr:@"type"];
	NSNumber *min = [element numAttr:@"minOccurs"];
	NSString *max = [element attr:@"maxOccurs"];
	NSString *useClass = nil;
	NSString *superclass = nil;
	NSString *itemClass = nil;
	NSString *comment = nil;
	
	// do we define the type (i.e. do we have a "complexType" child node)?
	INXMLNode *typeNode = [element childNamed:@"complexType"];
	if (typeNode) {
		if (![typeNode attr:@"name"]) {
			NSString *newTypeName = [NSString stringWithFormat:@"%@%@", [[name substringToIndex:1] uppercaseString], [name substringFromIndex:1]];
			if ([typeStack count] > 0) {
				newTypeName = [NSString stringWithFormat:@"%@%@", [typeStack lastObject], newTypeName];
			}
			[typeNode setAttr:newTypeName forKey:@"name"];
		}
		NSDictionary *typeDict = [self processType:typeNode withMapping:mapping];
		type = [typeDict objectForKey:@"type"];
		useClass = [typeDict objectForKey:@"className"];
		superclass = [typeDict objectForKey:@"superclass"];
	}
	
	// type of element
	if ([type length] > 0 && !useClass) {
		useClass = [mapping objectForKey:type];
		if ([useClass length] < 1) {									// not found, try appending "xs:" which is missing sometimes
			NSString *xsType = [@"xs:" stringByAppendingString:type];
			useClass = [mapping objectForKey:xsType];
			if ([useClass length] < 1) {								// still no luck, give up
				useClass = [NSString stringWithFormat:@"%@%@", INClassGeneratorClassPrefix, type];
				[self sendLog:[NSString stringWithFormat:@"I do not know which class to use for \"%@\", assuming \"%@\"", type, useClass]];
			}
			else {
				type = xsType;
			}
		}
	}
	
	// do we accept multiple instances? -> we need an array property
	if (max && ([@"unbounded" isEqualToString:max] || ![@"1" isEqualToString:max])) {
		comment = [NSString stringWithFormat:@"An array containing %@ objects", useClass];
		itemClass = useClass;
		useClass = @"NSArray";
	}
	
	// are we required?
	if ([min integerValue] > 0) {
		if (comment) {
			comment = [comment stringByAppendingFormat:@". (minOccurs = %@)", min];
		}
		else {
			comment = [NSString stringWithFormat:@"minOccurs = %@", min];
		}
	}
	
	// compose and return
	NSMutableDictionary *elemDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									 name, @"name",
									 type, @"type",
									 min, @"minOccurs",
									 useClass, @"class", nil];
	if (itemClass) {
		[elemDict setObject:itemClass forKey:@"itemClass"];
	}
	if (superclass) {
		[elemDict setObject:superclass forKey:@"superclass"];
	}
	if (comment) {
		[elemDict setObject:comment forKey:@"comment"];
	}
	
	return elemDict;
}


/**
 *	Processes "attribute" nodes and returns a dictionary with its properties.
 *	@return A dictionary with these attributes for this element: name, type, class, minOccurs and comment.
 */
- (NSDictionary *)processAttribute:(INXMLNode *)attribute withMapping:(NSMutableDictionary *)mapping
{
	NSString *attrName = [attribute attr:@"name"];
	NSString *attrType = [attribute attr:@"type"];
	if (!attrType) {
		attrType = @"";
	}
	
	NSNumber *minOccurs = [@"required" isEqualToString:[attribute attr:@"use"]] ? [NSNumber numberWithInt:1] : [NSNumber numberWithInt:0];
	NSString *comment = ([minOccurs integerValue] > 0) ? @"Must be present as an attribute" : nil;
	
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
							  [NSNumber numberWithBool:YES], @"isAttribute",
							  attrName, @"name",
							  attrType, @"type",
							  minOccurs, @"minOccurs",
							  attrClass, @"class",
							  attrClass, @"itemClass",
							  comment, @"comment",
							  nil];
	return attrDict;
}


/**
 *	Creates a class from the given property array. It uses the class file templates and writes to the "writeToDir" path.
 */
- (BOOL)createClass:(NSString *)className
		   withName:(NSString *)bareName
		 superclass:(NSString *)superclass
			forType:(NSString *)indivoType
		 properties:(NSArray *)properties
			  error:(NSError **)error
{
	// already there?
	NSString *headerPath = [writeToDir stringByAppendingFormat:@"/%@.h", className];
	NSString *bodyPath = [writeToDir stringByAppendingFormat:@"/%@.m", className];
	if (!mayOverwriteExisting) {
		NSFileManager *fm = [NSFileManager defaultManager];
		if ([fm fileExistsAtPath:headerPath]) {
			headerPath = nil;
		}
		if ([fm fileExistsAtPath:bodyPath]) {
			bodyPath = nil;
		}
		if (!headerPath && !bodyPath) {
			numClassesNotOverwritten++;
			return YES;
		}
	}
	
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
	NSMutableArray *propertyMap = [NSMutableArray array];
	NSMutableArray *nonNilNames = [NSMutableArray array];
	NSMutableArray *attributeNames = [NSMutableArray array];
	if ([properties count] > 0) {
		for (NSDictionary *propDict in properties) {
			NSString *name = [propDict objectForKey:@"name"];
			NSString *min = [propDict objectForKey:@"minOccurs"];
			NSInteger minOccurs = min ? [min integerValue] : 1;
			
			// we do not need "id" properties for subclasses, they all have the "udid" property
#if SKIP_ID_ATTRIBUTES
			if ([name isEqualToString:@"id"]) {
				continue;
			}
#endif
			NSString *className = [propDict objectForKey:@"class"];
			
			// create class property strings
			if (name && className) {
				[propString appendFormat:@"@property (nonatomic, strong) %@ *%@;", className, name];
				NSString *comment = [propDict objectForKey:@"comment"];
				if ([comment length] > 0) {
					[propString appendFormat:@"\t\t\t\t\t///< %@", comment];
				}
				[propString appendString:@"\n"];
				[synthNames addObject:name];
			}
			else {
				[self sendLog:[NSString stringWithFormat:@"Error: Missing name or class for property: %@", propDict]];
			}
			
			// collect forward class declarations
			if ([INClassGeneratorClassPrefix isEqualToString:[className substringToIndex:[INClassGeneratorClassPrefix length]]]) {
				[forwardClasses addObject:[NSString stringWithFormat:@"@class %@;", className]];
			}
			
			// collect properties that must be set
			if (minOccurs > 0) {
				[nonNilNames addObject:[NSString stringWithFormat:@"@\"%@\"", name]];
			}
			
			// collect attributes
			if ([[propDict objectForKey:@"isAttribute"] boolValue]) {
				[attributeNames addObject:[NSString stringWithFormat:@"@\"%@\"", name]];
			}
			
			// collect class mappings
			NSString *itemClass = [propDict objectForKey:@"itemClass"];
			[propertyMap addObject:[NSString stringWithFormat:@"@\"%@\", @\"%@\"", itemClass ? itemClass : className, name]];
		}
	}
	NSString *synthString = ([synthNames count] > 0) ? [synthNames componentsJoinedByString:@", "] : nil;
	NSString *nonNilString = ([nonNilNames count] > 0) ? [nonNilNames componentsJoinedByString:@", "] : nil;
	NSString *attributeString = ([attributeNames count] > 0) ? [attributeNames componentsJoinedByString:@", "] : nil;
	
	NSMutableDictionary *substitutions = [NSMutableDictionary dictionaryWithObjectsAndKeys:
										  @"Indivo Class Generator", @"AUTHOR",
										  [NSString stringWithFormat:@"%d/%d/%d", comp.month, comp.day, comp.year], @"DATE",
										  [NSString stringWithFormat:@"%d", comp.year], @"YEAR",
										  (currentInputPath ? [currentInputPath lastPathComponent] : @"<unknown>"), @"TEMPLATE_PATH",
										  className, @"CLASS_NAME",
										  (superclass ? superclass : INClassGeneratorBaseClass), @"CLASS_SUPERCLASS",
										  bareName, @"CLASS_NODENAME",
										  indivoType, @"CLASS_TYPENAME",
										  propString, @"CLASS_PROPERTIES",
										  [forwardClasses componentsJoinedByString:@"\n"], @"CLASS_FORWARDS",
										  (indivoType ? indivoType : @"unknown"), @"INDIVO_TYPE",
										  @"", @"CLASS_IMPORTS",
										  nil];
	if (synthString) {
		[substitutions setObject:synthString forKey:@"CLASS_SYNTHESIZE"];
	}
	if ([propertyMap count] > 0) {
		[substitutions setObject:[propertyMap componentsJoinedByString:@",\n\t\t\t"] forKey:@"CLASS_PROPERTY_MAP"];
	}
	if (nonNilString) {
		[substitutions setObject:nonNilString forKey:@"CLASS_NON_NIL_NAMES"];
	}
	if (attributeString) {
		[substitutions setObject:attributeString forKey:@"CLASS_ATTRIBUTE_NAMES"];
	}
	
	// create header
	if (headerPath) {
		NSString *header = [[self class] applyToHeaderTemplate:substitutions];
		if (header) {
			NSURL *headerURL = [NSURL fileURLWithPath:headerPath];
			
			if (![header writeToURL:headerURL atomically:YES encoding:NSUTF8StringEncoding error:error]) {
				[self sendLog:[NSString stringWithFormat:@"ERROR writing to %@: %@", headerPath, [*error localizedDescription]]];
				return NO;
			}
		}
	}
	
	// create body (i.e. implementation)
	if (bodyPath) {
		NSString *body = [[self class] applyToBodyTemplate:substitutions];
		if (body) {
			NSURL *bodyURL = [NSURL fileURLWithPath:bodyPath];
			
			if (![body writeToURL:bodyURL atomically:YES encoding:NSUTF8StringEncoding error:error]) {
				[self sendLog:[NSString stringWithFormat:@"ERROR writing to %@: %@", bodyPath, [*error localizedDescription]]];
				return NO;
			}
		}
	}
	
	numClassesGenerated++;
	return YES;
}



#pragma mark - Properties
- (BOOL)ignoresType:(NSString *)typeName
{
	static NSDictionary *ignoreDict = nil;
	if (!ignoreDict) {
		NSString *dictPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"Ignore" ofType:@"plist"];
		ignoreDict = [[NSDictionary alloc] initWithContentsOfFile:dictPath];
	}
	
	return (nil != [ignoreDict objectForKey:typeName]);
}



#pragma mark - Logging
- (void)sendLog:(NSString *)aString
{
	runOnMainQueue(^{
		NSString *errString = currentInputPath ? [currentInputPath stringByAppendingFormat:@":  %@", aString] : aString;
		NSDictionary *userInfo = [NSDictionary dictionaryWithObject:errString forKey:INClassGeneratorLogStringKey];
		[[NSNotificationCenter defaultCenter] postNotificationName:INClassGeneratorDidProduceLogNotification object:nil userInfo:userInfo];
	});
}



#pragma mark - Template


static NSString *classGeneratorHeaderTemplate = nil;
static NSString *classGeneratorBodyTemplate = nil;


/**
 *	This method applies substitutions found in a dictionary to a template. It currently is very cheaply implemented using RegExes and only recognizes
 *	{% if VAR_NAME %} and {{ VAR_NAME }} and does *not* allow nesting.
 */
+ (NSString *)applySubstitutions:(NSDictionary *)substitutions toTemplate:(NSString *)aTemplate
{
	if ([substitutions count] < 1) {
		return aTemplate;
	}
	if (!aTemplate) {
		return aTemplate;
	}
	
	NSMutableString *applied = [aTemplate mutableCopy];
	
	// replace if-blocks via RegEx - that means NO NESTING
	NSRegularExpression *ifRegEx = [NSRegularExpression regularExpressionWithPattern:@"((\\{%\\s*if\\s+([^\\}\\s]+)\\s*%\\})(.*?)(\\{%\\s*endif\\s*%\\}))"
																			 options:NSRegularExpressionCaseInsensitive | NSRegularExpressionDotMatchesLineSeparators
																			   error:nil];
	NSArray *ifMatches = [ifRegEx matchesInString:applied options:0 range:NSMakeRange(0, [applied length])];
	if ([ifMatches count] > 0) {
		for (NSTextCheckingResult *match in [ifMatches reverseObjectEnumerator]) {
			NSRange fullRange = [match rangeAtIndex:1];
			NSRange openRange = [match rangeAtIndex:2];
			NSRange keyRange = [match rangeAtIndex:3];
			NSRange closeRange = [match rangeAtIndex:5];
			
			NSString *key = [applied substringWithRange:keyRange];
			NSString *replacement = [substitutions objectForKey:key];
			if (replacement) {
				[applied replaceCharactersInRange:closeRange withString:@""];
				[applied replaceCharactersInRange:openRange withString:@""];
			}
			else {
				[applied replaceCharactersInRange:fullRange withString:@""];
			}
		}
	}
	
	// replace placeholders via RegEx
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(\\{\\{\\s*([^\\}\\s]+)\\s*\\}\\})"
																		   options:NSRegularExpressionCaseInsensitive
																			 error:nil];
	NSArray *matches = [regex matchesInString:applied options:0 range:NSMakeRange(0, [applied length])];
	if ([matches count] > 0) {
		for (NSTextCheckingResult *match in [matches reverseObjectEnumerator]) {
			NSRange fullRange = [match rangeAtIndex:1];
			NSRange keyRange = [match rangeAtIndex:2];
			NSString *key = [applied substringWithRange:keyRange];
			NSString *replacement = [substitutions objectForKey:key];
			if (replacement) {
				[applied replaceCharactersInRange:fullRange withString:replacement];
			}
			else {
				DLog(@"No replacement for %@ found", key);
			}
		}
	}
	return applied;
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
