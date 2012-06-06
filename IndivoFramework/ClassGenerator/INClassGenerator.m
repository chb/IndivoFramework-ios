//
//  INClassGenerator.m
//  IndivoFramework
//
//  Created by Pascal Pfiffner on 1/20/12.
//  Copyright (c) 2012 Harvard Medical School. All rights reserved.
//

#import "INClassGenerator.h"
#import <dispatch/dispatch.h>

#import "INXSDParser.h"
#import "INSDMLParser.h"


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
@property (nonatomic, strong) NSMutableDictionary *mapping;				///< Type to class name mapping
@property (nonatomic, copy) NSString *currentInputPath;					///< Used mainly for logging

- (short)createClass:(NSString *)className
			withName:(NSString *)bareName
		  superclass:(NSString *)superclass
			 forType:(NSString *)forType
		  properties:(NSArray *)properties
			   error:(NSError **)error;

- (void)sendLog:(NSString *)aString;

@end


@implementation INClassGenerator

@synthesize mayOverwriteExisting;
@synthesize numSchemasParsed, numClassesGenerated, numClassesNotOverwritten;
@synthesize writeToDir, mapping, currentInputPath;


/**
 *	Run all the XSD schemas we find. Schema files must have the .xsd extension.
 *	@param inputPath A path to a directory containing XSD files or a path to one XSD file. A directory will be recursively searched.
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
	self.mapping = [[NSDictionary dictionaryWithContentsOfFile:mapPath] mutableCopy];
	if (!mapping) {
		CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(aCallback, NO, @"Did not find Mapping.plist, cannot continue")
		return;
	}
	
	// find XSD
	__block NSError *error = nil;
	NSArray *xsd = findFilesEndingWithRecursively(inputPath, @"xsd", &error);
	if (!xsd) {
		CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(aCallback, NO, [error localizedDescription]);
	}
	
	// find SDML
	NSArray *sdml = findFilesEndingWithRecursively(inputPath, @"sdml", &error);
	if (!sdml) {
		CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(aCallback, NO, [error localizedDescription]);
	}
	
	// anything to process at all?
	if ([xsd count] < 1 && [sdml count] < 1) {
		CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(aCallback, NO, @"There were no XSD nor SDML files in the input path")
		return;
	}
	
	// dispatch
	dispatch_queue_t aQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_async(aQueue, ^{
		NSUInteger i = 0;
		self.numClassesGenerated = 0;
		self.numClassesNotOverwritten = 0;
		
		// loop all XSDs
		INXSDParser *xsdParser = [INXSDParser newWithDelegate:self];
		for (NSString *path in xsd) {
			if (![fm fileExistsAtPath:path]) {
				NSString *logStr = [NSString stringWithFormat:@"Schema file does not exist at %@", path];
				[self sendLog:logStr];
			}
			
			// ** run the file
			else if (![xsdParser runFileAtPath:path error:&error]) {
				[self sendLog:[error localizedDescription]];
			}
			else {
				i++;
			}
		}
		
		// loop all SDMLs
		INSDMLParser *sdmlParser = [INSDMLParser newWithDelegate:self];
		for (NSString *path in sdml) {
			if (![fm fileExistsAtPath:path]) {
				NSString *logStr = [NSString stringWithFormat:@"SDML file does not exist at %@", path];
				[self sendLog:logStr];
			}
			
			// ** run the file
			else if (![sdmlParser runFileAtPath:path error:&error]) {
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



#pragma mark - Schema Parser Delegate
/**
 *	Returns the class associated with the given type ONLY IF the class is already known
 */
- (NSString *)schemaParser:(INSchemaParser *)parser existingClassNameForType:(NSString *)aType
{
	NSString *useClass = nil;
	
	// is the type ignored?
	if ([aType length] > 0 && ![self ignoresType:aType]) {
		useClass = [mapping objectForKey:aType];
		if ([useClass length] < 1) {										// not found, try prepending "xs:"
			useClass = [mapping objectForKey:[@"xs:" stringByAppendingString:aType]];
			if ([useClass length] < 1) {									// not found, try prepending "indivo:"
				useClass = [mapping objectForKey:[@"indivo:" stringByAppendingString:aType]];
			}
		}
	}
	
	return useClass;
}

/**
 *	Searches for the currently known class name of given type, creates a new one if the class is not yet known.
 */
- (NSString *)schemaParser:(INSchemaParser *)parser classNameForType:(NSString *)aType effectiveType:(NSString **)effectiveType
{
	NSString *useClass = nil;
	NSString *useType = aType;
	
	// is the type ignored?
	if ([self ignoresType:aType]) {
		NSString *message = [NSString stringWithFormat:@"Type \"%@\" is on the ignore list", aType];
		[self sendLog:message];
	}
	
	// nope, get the class name
	else if ([aType length] > 0) {
		useClass = [mapping objectForKey:aType];
		if ([useClass length] < 1) {										// not found, try prepending "xs:"
			useType = [@"xs:" stringByAppendingString:aType];
			useClass = [mapping objectForKey:useType];
			if ([useClass length] < 1) {									// not found, try prepending "indivo:"
				useType = [@"indivo:" stringByAppendingString:aType];
				useClass = [mapping objectForKey:useType];
				if ([useClass length] < 1) {								// still no luck, give up and use our prefix plus the ucfirst type name
					NSArray *colonChopper = [aType componentsSeparatedByString:@":"];
					NSString *classBase = [colonChopper lastObject];
					
					// new class!
					if ([classBase length] > 1) {
						NSString *ucFirstName = [NSString stringWithFormat:@"%@%@", [[classBase substringToIndex:1] uppercaseString], [classBase substringFromIndex:1]];
						useClass = [NSString stringWithFormat:@"%@%@", INClassGeneratorClassPrefix, ucFirstName];
						useType = ([colonChopper count] < 2) ? [@"indivo:" stringByAppendingString:aType] : aType;
						
						//NSString *message = [NSString stringWithFormat:@"Assuming \"%@\" for \"%@\"", useClass, useType];
					}
				}
			}
		}
	}
	
	// return the effectively used type
	if (effectiveType) {
		*effectiveType = useType;
	}
	
	return useClass;
}


- (void)schemaParser:(INSchemaParser *)parser
	   didParseClass:(NSString *)className
			 forName:(NSString *)name
		  superclass:(NSString *)superclass
			 forType:(NSString *)type
		  properties:(NSArray *)properties
{
	NSLog(@"Did parse \"%@\" for \"%@\" with type \"%@\"", className, name, type);
	
	// we create the class if it's not yet known
	if ([className length] > 0 && [type length] > 0 && ![mapping objectForKey:type]) {
		NSError *error = nil;
		NSString *message = nil;
		short status = [self createClass:className withName:name superclass:superclass forType:type properties:properties error:&error];
		if (status > 1) {
			message = [NSString stringWithFormat:@"Created class \"%@\" for \"%@\"", className, name];
		}
		else if (1 == status) {
			message = [NSString stringWithFormat:@"Class \"%@\" for \"%@\" already exists", className, name];
		}
		else {
			message = [NSString stringWithFormat:@"Failed to create class \"%@\": %@", name, [error localizedDescription]];
		}
		[self sendLog:message];
	}
}


- (void)schemaParser:(INSchemaParser *)parser isProcessingFileAtPath:(NSString *)filePath
{
	self.currentInputPath = filePath;
}

- (void)schemaParser:(INSchemaParser *)parser sendsMessage:(NSString *)message ofType:(INSchemaParserMessageType)type
{
	[self sendLog:message];
}



#pragma mark - Class Creation
/**
 *	Creates a class from the given property array. It uses the class file templates and writes to the "writeToDir" path.
 */
- (short)createClass:(NSString *)className
			withName:(NSString *)bareName
		  superclass:(NSString *)superclass
			 forType:(NSString *)forType
		  properties:(NSArray *)properties
			   error:(NSError **)error
{
	NSLog(@"Create \"%@\" with %@, child of %@", className, bareName, superclass);
	if ([className length] < 1) {
		if (NULL != error) {
			NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"No class name given" forKey:NSLocalizedDescriptionKey];
			*error = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:userInfo];
		}
		return 0;
	}
	
	// remember it
	[mapping setObject:className forKey:forType];
	
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
			return 1;
		}
	}
	
	// substitute superclass
	if ([superclass length] < 1) {
		superclass = INClassGeneratorBaseClass;
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
			NSString *thisAffinity = @"strong";
			
			// create class property strings
			if ([name length] > 0 && [className length] > 0) {
				
				// classnames may begin with "[weak]" or similar to override the strong default property
				if ([className length] > 1 && [@"[" isEqualToString:[className substringToIndex:1]]) {
					NSUInteger endPos = [className rangeOfString:@"]"].location;
					if ([className length] > endPos + 1) {
						thisAffinity = [[className substringFromIndex:1] substringToIndex:endPos - 1];
						className = [className substringFromIndex:endPos + 1];
					}
					else {
						[self sendLog:[NSString stringWithFormat:@"Error: Cannot interpret class for property: %@", propDict]];
					}
				}
				
				[propString appendFormat:@"@property (nonatomic, %@) %@ *%@;", thisAffinity, className, name];
				NSString *comment = [propDict objectForKey:@"comment"];
				if ([comment length] > 0) {
					[propString appendFormat:@"\t\t\t\t\t///< %@", comment];
				}
				[propString appendString:@"\n"];
				[synthNames addObject:name];
			}
			else {
				[self sendLog:[NSString stringWithFormat:@"Missing name or class for property: %@", propDict]];
			}
			
			// collect forward class declarations and -mappings
			NSString *itemClass = [propDict objectForKey:@"itemClass"];
			[propertyMap addObject:[NSString stringWithFormat:@"@\"%@\", @\"%@\"", itemClass ? itemClass : className, name]];
			
			if ([className length] > [INClassGeneratorClassPrefix length]
				&& [INClassGeneratorClassPrefix isEqualToString:[className substringToIndex:[INClassGeneratorClassPrefix length]]]) {
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
		}
	}
	NSMutableString *templatePath = [NSMutableString new];
	BOOL start = NO;
	for (NSString *path in [currentInputPath pathComponents]) {
		if (start) {
			[templatePath appendFormat:@"/%@", path];
		}
		else if ([@"indivo_server" isEqualToString:path]) {
			start = YES;
		}
	}
	NSString *synthString = ([synthNames count] > 0) ? [synthNames componentsJoinedByString:@", "] : nil;
	NSString *nonNilString = ([nonNilNames count] > 0) ? [nonNilNames componentsJoinedByString:@", "] : nil;
	NSString *attributeString = ([attributeNames count] > 0) ? [attributeNames componentsJoinedByString:@", "] : nil;
	
	NSMutableDictionary *substitutions = [NSMutableDictionary dictionaryWithObjectsAndKeys:
										  @"Indivo Class Generator", @"AUTHOR",
										  [NSString stringWithFormat:@"%d/%d/%d", comp.month, comp.day, comp.year], @"DATE",
										  [NSString stringWithFormat:@"%d", comp.year], @"YEAR",
										  ([templatePath length] > 0 ? templatePath : @"<unknown>"), @"TEMPLATE_PATH",
										  className, @"CLASS_NAME",
										  (superclass ? superclass : INClassGeneratorBaseClass), @"CLASS_SUPERCLASS",
										  bareName, @"CLASS_NODENAME",
										  forType, @"CLASS_TYPENAME",
										  propString, @"CLASS_PROPERTIES",
										  [forwardClasses componentsJoinedByString:@"\n"], @"CLASS_FORWARDS",
										  (forType ? forType : @"unknown"), @"INDIVO_TYPE",
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
				return 0;
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
				return 0;
			}
		}
	}
	
	numClassesGenerated++;
	return 2;
}



#pragma mark - Properties
- (BOOL)ignoresType:(NSString *)typeName
{
	if (!typeName) {
		return NO;
	}
	
	static NSDictionary *ignoreDict = nil;
	if (!ignoreDict) {
		NSString *dictPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"Ignore" ofType:@"plist"];
		ignoreDict = [[NSDictionary alloc] initWithContentsOfFile:dictPath];
	}
	
	if (![ignoreDict objectForKey:typeName]) {
		typeName = [@"indivo:" stringByAppendingString:typeName];
		return (nil != [ignoreDict objectForKey:typeName]);
	}
	return YES;
}



#pragma mark - Logging
- (void)sendLog:(NSString *)aString
{
	runOnMainQueue(^{
		NSString *errString = currentInputPath ? [aString stringByAppendingFormat:@"  (%@)", currentInputPath] : aString;
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


NSArray *findFilesEndingWithRecursively(NSString *path, NSString *endingWith, NSError **error)
{
	if ([path length] < 1) {
		return nil;
	}
	
	// check path
	NSFileManager *fm = [NSFileManager defaultManager];
	BOOL inputIsDir = NO;
	if (![fm fileExistsAtPath:path isDirectory:&inputIsDir]) {
		ERR(error, @"There is no file/directory here", 0)
		return nil;
	}
	
	// find all files in our path
	NSArray *all = nil;
	if (inputIsDir) {
		NSArray *subs = [fm contentsOfDirectoryAtPath:path error:error];
		if (!subs) {
			return nil;
		}
		
		NSMutableArray *content = [NSMutableArray array];
		for (NSString *sub in subs) {
			NSString *subpath = [path stringByAppendingPathComponent:sub];
			[content addObjectsFromArray:findFilesEndingWithRecursively(subpath, endingWith, error)];
		}
		all = content;
	}
	else {
		all = [NSArray arrayWithObject:path];
	}
	
	// filter by extension
	NSPredicate *filter = [NSPredicate predicateWithFormat:@"self ENDSWITH %@", endingWith];
	return [all filteredArrayUsingPredicate:filter];
}


