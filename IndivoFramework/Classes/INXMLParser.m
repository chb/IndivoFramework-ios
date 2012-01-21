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
#import "INXMLReports.h"


@interface INXMLParser()

@property (nonatomic, strong) INXMLNode *rootNode;
@property (nonatomic, strong) INXMLNode *currentNode;
@property (nonatomic, strong) NSMutableString *stringBuffer;

@property (nonatomic, copy) NSString *errorOnLine;					///< We capture XML parsing errors here to provide line/column feedback for malformed XML

+ (Class)nodeClassForNodeName:(NSString *)aNodeName;
- (INXMLNode *)parseXML:(NSString *)xmlString error:(NSError * __autoreleasing *)error;

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
	if ([@"Reports" isEqualToString:aNodeName]) {
		return [INXMLReports class];
	}
	if ([@"Report" isEqualToString:aNodeName]) {
		return [INXMLReport class];
	}
	return [INXMLNode class];
}



#pragma mark - Public Parsing Method
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



#pragma mark - XML Parsing
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
	else {
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


@end
