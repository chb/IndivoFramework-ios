//
//  INXSDParser.m
//  IndivoFramework
//
//  Created by Pascal Pfiffner on 6/5/12.
//  Copyright (c) 2012 Harvard Medical School. All rights reserved.
//

#import "INXSDParser.h"
#import "INXMLParser.h"


@interface INXSDParser ()

@property (nonatomic, strong) NSMutableArray *typeStack;				///< Every time we encounter a type definition, its name is pushed here so we always know where we are.

- (NSDictionary *)processType:(INXMLNode *)type;
- (NSDictionary *)processElement:(INXMLNode *)element;
- (NSDictionary *)processAttribute:(INXMLNode *)attribute;

@end


@implementation INXSDParser

@synthesize typeStack;


/**
 *	Runs the given file
 */
- (BOOL)runFileAtPath:(NSString *)path error:(NSError **)error
{
	if (!path) {
		return NO;
	}
	[self.delegate schemaParser:self isProcessingFileAtPath:path];
	
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
				[self.delegate schemaParser:self isProcessingFileAtPath:includePath];
				if (![self runFileAtPath:includePath error:error]) {
					return NO;
				}
			}
		}
		[self.delegate schemaParser:self isProcessingFileAtPath:path];
	}
	
	// process root nodes
	for (INXMLNode *node in [schema children]) {
		if ([@"element" isEqualToString:node.name]) {
			[self processElement:node];
		}
		else if ([@"simpleType" isEqualToString:node.name] || [@"complexType" isEqualToString:node.name]) {
			[self processType:node];
		}
	}
	
	return YES;
}


/**
 *	Parses a <simpleType> or <complexType> node and makes sure the class file represented by the type is created.
 *	"attribute" nodes and "sequence > element" nodes are treated equally, both will create a property for the type based on their name and type.
 *	@return A dictionary containing a "className" element with the class name and possibly a "superclass" containing the superclass name.
 */
- (NSDictionary *)processType:(INXMLNode *)type
{
	NSMutableArray *properties = nil;
	NSString *typeName = [type attr:@"name"];
	NSString *superclass = nil;
	if ([typeName length] < 1) {
		[self.delegate schemaParser:self sendsMessage:@"Cannot process type without a name" ofType:INSchemaParserMessageTypeError];
		return nil;
	}
	
	// the class name
	NSString *effectiveType = typeName;
	NSString *className = [self.delegate schemaParser:self classNameForType:typeName effectiveType:&effectiveType];
	[typeStack addObject:effectiveType];
	
	// get definitions (attributes and sequence/element) from the correct node
	NSArray *attributes = nil;
	NSArray *elements = nil;
	
	// "extension" - determine the superclass
	INXMLNode *extension = [type childNamed:@"extension"];
	if (extension) {
		NSString *base = [extension attr:@"base"];
		superclass = [self.delegate schemaParser:self existingClassNameForType:base];
		attributes = [extension childrenNamed:@"attribute"];
		elements = [[extension childNamed:@"sequence"] childrenNamed:@"element"];
		
		/// @todo Check for restrictions
	}
	
	// "restriction" - find possible values
	else {
		INXMLNode *restriction = [type childNamed:@"restriction"];
		if (restriction) {
			NSString *base = [restriction attr:@"base"];
			superclass = [self.delegate schemaParser:self existingClassNameForType:base];
			
			NSString *message = [NSString stringWithFormat:@"[x]  Types with enumerations are not yet automated, adjust the class \"%@\" by hand", className];
			[self.delegate schemaParser:self sendsMessage:message ofType:INSchemaParserMessageTypeNotification];
		}
		
		// "sequence" - a new definition
		else {
			attributes = [type childrenNamed:@"attribute"];
			elements = [[type childNamed:@"sequence"] childrenNamed:@"element"];
		}
	}
	
	// parse attributes
	if ([attributes count] > 0) {
		properties = [NSMutableArray arrayWithCapacity:[attributes count]];
		
		for (INXMLNode *attr in attributes) {
			NSDictionary *attrDict = [self processAttribute:attr];
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
			NSDictionary *elemDict = [self processElement:element];
			if (elemDict) {
				[properties addObject:elemDict];
			}
		}
	}
	
	// tell the delegate
	[self.delegate schemaParser:self didParseClass:className forName:typeName superclass:superclass forType:effectiveType properties:properties];
	
	[typeStack removeLastObject];
	return [NSDictionary dictionaryWithObjectsAndKeys:effectiveType, @"type", className, @"className", superclass, @"superclass", nil];
}


/**
 *	Parses an <element> node.
 *	"minOccurs" is parsed but ignored in the class generation, except for a comment on the property.
 *	@return A dictionary with these attributes for this element: name, type, class, minOccurs and comment.
 */
- (NSDictionary *)processElement:(INXMLNode *)element
{
	NSString *name = [element attr:@"name"];
	NSString *type = [element attr:@"type"];
	NSNumber *min = [element numAttr:@"minOccurs"];
	NSString *max = [element attr:@"maxOccurs"];
	NSString *useClass = nil;
	NSString *useType = type;
	NSString *superclass = nil;
	NSString *itemClass = nil;
	NSString *comment = nil;
	
	// do we define the type (i.e. do we have a "simpleType" or "complexType" child node)?
	INXMLNode *typeNode = [element childNamed:@"simpleType"];
	if (!typeNode) {
		typeNode = [element childNamed:@"complexType"];
	}
	if (typeNode) {
		if (![typeNode attr:@"name"]) {
			NSString *newTypeName = [NSString stringWithFormat:@"%@%@", [[name substringToIndex:1] uppercaseString], [name substringFromIndex:1]];
			if ([typeStack count] > 0) {
				newTypeName = [NSString stringWithFormat:@"%@%@", [typeStack lastObject], newTypeName];
			}
			[typeNode setAttr:newTypeName forKey:@"name"];
		}
		NSDictionary *typeDict = [self processType:typeNode];
		type = [typeDict objectForKey:@"type"];
		useClass = [typeDict objectForKey:@"className"];
		superclass = [typeDict objectForKey:@"superclass"];
	}
	
	// class of the element
	if ([type length] > 0 && [useClass length] < 1) {
		useClass = [self.delegate schemaParser:self classNameForType:type effectiveType:&useType];
		
		// if we get no class, the class should be ignored
		if ([useClass length] < 1) {
			return nil;
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
	
	// do we have a class?
	if ([useClass length] < 1) {
		NSString *message = [NSString stringWithFormat:@"Element \"%@\" (%@) did not match a class", name, type];
		[self.delegate schemaParser:self sendsMessage:message ofType:INSchemaParserMessageTypeError];
	}
	
	// compose and return
	NSMutableDictionary *elemDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									 name, @"name",
									 useType, @"type",
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
 *	@return A dictionary with these attributes for this element: name, type, class, minOccurs, itemClass and comment.
 */
- (NSDictionary *)processAttribute:(INXMLNode *)attribute
{
	NSString *attrName = [attribute attr:@"name"];
	NSString *attrType = [attribute attr:@"type"];
	NSNumber *minOccurs = [@"required" isEqualToString:[attribute attr:@"use"]] ? [NSNumber numberWithInt:1] : [NSNumber numberWithInt:0];
	NSString *comment = ([minOccurs integerValue] > 0) ? @"Must be present as an XML attribute when writing XML" : nil;
	NSString *attrClass = [self.delegate schemaParser:self classNameForType:attrType effectiveType:&attrType];
	
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


@end
