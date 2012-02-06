/*
 INXMLParser.h
 IndivoFramework
 
 Created by Pascal Pfiffner on 9/23/11.
 Copyright (c) 2011 Children's Hospital Boston
 
 This library is free software; you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public
 License as published by the Free Software Foundation; either
 version 2.1 of the License, or (at your option) any later version.
 
 This library is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public
 License along with this library; if not, write to the Free Software
 Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 */


#import "INXMLParser.h"
#import "INXMLReport.h"
#import "Indivo.h"
#include <libxml/xmlschemastypes.h>


@interface INXMLParser()

@property (nonatomic, strong) INXMLNode *rootNode;
@property (nonatomic, strong) INXMLNode *currentNode;
@property (nonatomic, strong) NSMutableString *stringBuffer;

@property (nonatomic, copy) NSString *errorOnLine;					///< We capture XML parsing errors here to provide line/column feedback for malformed XML

+ (Class)nodeClassForNodeName:(NSString *)aNodeName;
- (INXMLNode *)parseXML:(NSString *)xmlString error:(NSError * __autoreleasing *)error;

void xmlSchemaValidityError(void **ctx, const char *format, ...);

@end


@implementation INXMLParser

@synthesize rootNode, currentNode, stringBuffer;
@synthesize errorOnLine;


/**
 *	We can use INXMLNode subclasses for certain nodes with additional functionality, return the correct class from this method
 *	@todo THIS SHOULD GO TO A DELEGATE METHOD
 */
+ (Class)nodeClassForNodeName:(NSString *)aNodeName
{
	if ([@"Report" isEqualToString:aNodeName]) {
		return [INXMLReport class];
	}
	return [INXMLNode class];
}



#pragma mark - XML Parsing
/**
 *	Returns a dictionary generated from parsing the given XML string.
 *	This method only returns once parsing has completed. So think of performing the parsing on a separate thread if it could take
 *	a long time.
 *	@param xmlString An NSString containing the XML to parse
 *	@param error An NSError pointer which is guaranteed to not be nil if this method returns NO and a pointer was provided
 *	@return An NSDictionary representing the XML structure, or nil if parsing failed
 */
+ (INXMLNode *)parseXML:(NSString *)xmlString error:(NSError * __autoreleasing *)error
{
	INXMLParser *p = [[self alloc] init];
	return [p parseXML:xmlString error:error];
}


/**
 *	Starts parsing the given XML string.
 *	This method only returns once parsing has completed. So think of performing the parsing on a separate thread if it could take
 *	a long time.
 *	@param xmlString An NSString containing the XML to parse
 *	@param error An NSError pointer which is guaranteed to not be nil if this method returns NO and a pointer was provided
 *	@return An NSDictionary representing the XML structure, or nil if parsing failed
 */
- (INXMLNode *)parseXML:(NSString *)xmlString error:(NSError * __autoreleasing *)error
{
	if ([xmlString length] < 1) {
		XERR(error, @"No XML string provided", 0)
		return nil;
	}
	
	// init parser
	NSXMLParser *parser = [[NSXMLParser alloc] initWithData:[xmlString dataUsingEncoding:NSUTF8StringEncoding]];
	parser.delegate = self;
	[parser setShouldProcessNamespaces:YES];
	self.errorOnLine = nil;
	self.stringBuffer = [NSMutableString string];
	self.rootNode = [INXMLNode nodeWithName:@"root" attributes:nil];
	self.currentNode = rootNode;
	
	// start parsing and handle any error
	BOOL ret = [parser parse];
	if (!ret || !rootNode) {
		NSString *errStr = errorOnLine ? errorOnLine : ([parser parserError] ? [[parser parserError] localizedDescription] : @"Parser Error");
		NSInteger errCode = [parser parserError] ? [[parser parserError] code] : 0;
		XERR(error, errStr, errCode)
		
		self.rootNode = nil;
	}
	else if (error) {
		*error = nil;
	}
	
	// cleanup and return
	self.stringBuffer = nil;
	
	return rootNode;
}



#pragma mark - XML Parser Delegate
/**
 *	Called when the parser encounters a start tag for a given element.
 */
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict
{
	INXMLNode *node = [[[self class] nodeClassForNodeName:elementName] nodeWithName:elementName attributes:attributeDict];
	if (currentNode) {
		[currentNode addChild:node];
	}
	else {
		DLog(@"Oops, error while parsing, closed child beyond root node!");
	}
	self.currentNode = node;
}

/**
 *	Sent when the parser encounters an end tag for a specific element
 */
- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
	currentNode.text = [stringBuffer stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	[stringBuffer setString:@""];
	
	self.currentNode = currentNode.parent;
}

/**
 *	Sent by a parser object to provide us with a string representing all or part of the characters of the current element
 */
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
	[stringBuffer appendString:string];
}

/**
 *	When this method is invoked, parsing is stopped
 */
- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
	self.errorOnLine = [NSString stringWithFormat:@"Parser error occurred on line %d, column %d", [parser lineNumber], [parser columnNumber]];
}

/**
 *	Finished the document, we remove our artificial root node unless there were several top-level elements in the XML
 */
- (void)parserDidEndDocument:(NSXMLParser *)parser
{
	if (1 == [[rootNode children] count]) {
		self.rootNode = [[rootNode children] objectAtIndex:0];
	}
}


/* The following methods are currently not used
- (void)parserDidStartDocument:(NSXMLParser *)parser
{
}

- (void)parser:(NSXMLParser *)parser foundComment:(NSString *)comment
{
}

- (void)parser:(NSXMLParser *)parser foundCDATA:(NSData *)CDATABlock
{
}

- (void)parser:(NSXMLParser *)parser foundIgnorableWhitespace:(NSString *)whitespaceString
{
}
//	*/



#pragma mark - XML Validation
/**
 *	Validates an XML string against an XSD at the given path.
 *	Boldy transcribed from: http://knol2share.blogspot.com/2009/05/validate-xml-against-xsd-in-c.html
 */
+ (BOOL)validateXML:(NSString *)xmlString againstXSD:(NSString *)xsdPath error:(__autoreleasing NSError **)error
{
	BOOL success = NO;
	xmlLineNumbersDefault(1);
	
	const char *xsd_path = [xsdPath cStringUsingEncoding:NSUTF8StringEncoding];
	
	// parse the schema
	xmlSchemaParserCtxtPtr ctx = xmlSchemaNewParserCtxt(xsd_path);
	xmlSchemaSetParserErrors(ctx, (xmlSchemaValidityErrorFunc) fprintf, (xmlSchemaValidityWarningFunc) fprintf, stderr);
	xmlSchemaPtr schema = xmlSchemaParse(ctx);
	xmlSchemaFreeParserCtxt(ctx);
	
	if (NULL == schema) {
		NSString *errStr = [NSString stringWithFormat:@"Failed to parse the schema at %@", xsdPath];
		XERR(error, errStr, 0);
	}
	
	// get our XML into an xmlDocPtr
	else {
		const char *xml = [xmlString cStringUsingEncoding:NSUTF8StringEncoding];
		int len = (int)strlen(xml);
		xmlDocPtr doc = xmlParseMemory(xml, len);
		
		if (NULL == doc) {
			NSString *errStr = [NSString stringWithFormat:@"Failed to parse input XML:\n%@", xmlString];
			XERR(error, errStr, 0);
		}
		
		// XML parsed successfully, validate!
		else {
			xmlSchemaValidCtxtPtr validCtx = xmlSchemaNewValidCtxt(schema);
			char *errorCap = NULL;
			xmlSchemaSetValidErrors(validCtx, (xmlSchemaValidityErrorFunc)xmlSchemaValidityError, (xmlSchemaValidityWarningFunc)xmlSchemaValidityError, &errorCap);
			int ret = xmlSchemaValidateDoc(validCtx, doc);
			if (0 == ret) {
				success = YES;
			}
			else {
				NSString *errStr = [NSString stringWithCString:(errorCap ? errorCap : "Unknown Error") encoding:NSUTF8StringEncoding];
				XERR(error, errStr, 0);
			}
			
			xmlSchemaFreeValidCtxt(validCtx);
			xmlFreeDoc(doc);
		}
		
		xmlSchemaFree(schema);
	}
	xmlSchemaCleanupTypes();
	xmlCleanupParser();
	xmlMemoryDump();
	
	return success;
}


void xmlSchemaValidityError(void **ctx, const char *format, ...)
{
	va_list ap;
	va_start(ap, format);
	char *str = (char *)va_arg(ap, int);
	
	// try to put str into ctx
	if (ctx) {
		*ctx = str;
	}
	else {
		NSLog(@"VALIDATION ERROR: %s", str);
	}
	va_end(ap);
}


@end
