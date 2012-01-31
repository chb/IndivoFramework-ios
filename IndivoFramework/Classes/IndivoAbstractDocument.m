/*
 IndivoAbstractDocument.h
 IndivoFramework
 
 Created by Pascal Pfiffner on 10/16/11.
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

#import "IndivoAbstractDocument.h"
#import <objc/runtime.h>
#import "IndivoRecord.h"


@implementation IndivoAbstractDocument

@synthesize record, type, nameSpace;
@synthesize created, suppressed;


/**
 *	To get a new instance that must be pushed to the server
 */
+ (id)newWithRecord:(IndivoRecord *)aRecord
{
	return [[self alloc] initFromNode:nil forRecord:aRecord];
}

/**
 *	The designated initializer, initializes an instance from an XML node.
 *	@attention This initializer assumes that the document comes from the server and sets "onServer" to YES IF (and
 *	only if) the provided node is not nil.
 */
- (id)initFromNode:(INXMLNode *)node forRecord:(IndivoRecord *)aRecord
{
	if ((self = [super initFromNode:node withServer:aRecord.server])) {
		self.record = aRecord;
	}
	return self;
}



#pragma mark - From and To XML
- (void)setFromNode:(INXMLNode *)node
{
	[super setFromNode:node];
	
	// document id
	if (node) {
		self.udid = [node attr:@"id"];
	}
	
	// collect all ivars that are subclasses of INObject and instantiate them from XML nodes with the same name
	unsigned int num, i;
	Ivar *ivars = class_copyIvarList([self class], &num);
	for (i = 0; i < num; i++) {
		id ivarObj = object_getIvar(self, ivars[i]);
		Class ivarClass = [ivarObj class];
		
		// if the object is not initialized, we need to get the Class somewhat hacky by parsing the class name from the ivar type encoding
		if (!ivarClass) {
			NSString *ivarType = [NSString stringWithUTF8String:ivar_getTypeEncoding(ivars[i])];
			if ([ivarType length] > 3) {
				NSString *className = [ivarType substringWithRange:NSMakeRange(2, [ivarType length]-3)];
				ivarClass = NSClassFromString(className);
			}
		}
		
		// we got an instance variable of INObject kind, instantiate
		if ([ivarClass isSubclassOfClass:[INObject class]]) {
			const char *ivar_name = ivar_getName(ivars[i]);
			NSString *ivarName = [NSString stringWithCString:ivar_name encoding:NSUTF8StringEncoding];
			id newVal = [ivarClass objectFromNode:node forChildNamed:ivarName];
			
			/// @todo Prevent overwriting existing nodes if the node was not provided
			object_setIvar(self, ivars[i], newVal);
		}
	}
	free(ivars);
}

/**
 *	Our subclasses sport an automatic isNull method that returns YES if all ivars of INObject subclass are nil
 */
- (BOOL)isNull
{
	unsigned int num, i;
	
	// return NO as soon as one ivar responding to "xml" is not nil
	Ivar *ivars = class_copyIvarList([self class], &num);
	for (i = 0; i < num; ++i) {
		id ivar = object_getIvar(self, ivars[i]);
		if ([ivar respondsToSelector:@selector(xml)]) {
			free(ivars);
			return NO;
		}
	}
	free(ivars);
	return YES;
}

/**
 *	Returns an XML representation of the receiver, automatically collected from all instance variables responding to the "xml" selector.
 *	@attention This method does only collect all direct instance variables, NO instance variables from superclasses are included.
 *	@return An XML representation of the receiver
 */
- (NSString *)xml
{
#ifdef INDIVO_XML_PRETTY_FORMAT
	return [NSString stringWithFormat:@"<%@ xmlns=\"%@\">\n\t%@\n</%@>", self.nodeName, self.nameSpace, [self innerXML], self.nodeName];
#else
	return [NSString stringWithFormat:@"<%@ xmlns=\"%@\">%@</%@>", self.nodeName, self.nameSpace, [self innerXML], self.nodeName];
#endif
}


/**
 *	This is the main XML generating method.
 *	This method walks all direct properties of the method and if they respond to the "xml" selector, adds the returned XML to this instance's
 *	XML representation. The main "xml" method creates our own node (e.g. <Document xmlns="something">) and adds the result of this method as
 *	the node's inner XML.
 */
- (NSString *)innerXML
{
	unsigned int num, i;
	
	// collect all ivars responding to "xml"
	NSMutableArray *xmlValues = [NSMutableArray array];
	Ivar *ivars = class_copyIvarList([self class], &num);
	for (i = 0; i < num; ++i) {
		id ivar = object_getIvar(self, ivars[i]);
		if ([ivar respondsToSelector:@selector(xml)]) {
			NSString *nodeName = nil;
			
			// if the node does not have a nodeName, apply the ivar name as nodeName
			if ([ivar isKindOfClass:[INObject class]]) {
				INObject *node = (INObject *)ivar;
				if (!node.nodeName) {
					node.nodeName = [NSString stringWithCString:ivar_getName(ivars[i]) encoding:NSUTF8StringEncoding];
				}
				nodeName = node.nodeName;
			}
			
			// warn if we may not validate but do not block XML creation
			if (nodeName && (!ivar || ([ivar respondsToSelector:@selector(isNull)] && [ivar isNull])) && ![[self class] canBeNull:nodeName]) {
				DLog(@"WARNING: %@ is nil or isNull, but it should be set to generate valid XML. Will add \"%@\"", nodeName, [ivar xml]);
			}
			
			// generate node XML
#ifdef INDIVO_XML_PRETTY_FORMAT
			NSString *subXML = [[ivar xml] stringByReplacingOccurrencesOfString:@"\n" withString:@"\n\t"];
			[xmlValues addObject:subXML];
#else
			[xmlValues addObject:[ivar xml]];
#endif
		}
	}
	free(ivars);
	
#ifdef INDIVO_XML_PRETTY_FORMAT
	return [xmlValues componentsJoinedByString:@"\n\t"];
#else
	return [xmlValues componentsJoinedByString:@""];
#endif
}



#pragma mark - Namespace and Type
+ (NSString *)nodeName
{
	return @"Document";
}

/**
 *	The instance method simply forwards the class method if no instance nameSpace has been set
 */
- (NSString *)nameSpace
{
	if (!nameSpace) {
		return [[self class] nameSpace];
	}
	return nameSpace;
}

/**
 *	Original Indivo documents don't need to overwrite this method, the namespace stays
 */
+ (NSString *)nameSpace
{
	return @"http://indivo.org/vocab/xml/documents#";
}


/**
 *	If the instance does not have a type, the class type is forwarded
 */
- (NSString *)type
{
	if (!type) {
		return [[self class] type];
	}
	return type;
}

/**
 *	The type of documents of this class
 */
+ (NSString *)type
{
	return @"";
}


/**
 *	If a property returns YES from its "isNull" selector and this method returns NO for that property, the XML is highly unlikely to validate
 *	with the server.
 */
+ (BOOL)canBeNull:(NSString *)propertyName
{
	return ![[self nonNilPropertyNames] containsObject:propertyName];
}

/**
 *	Should return the names for properties that cannot be nil (because the XML would not validate).
 */
+ (NSArray *)nonNilPropertyNames
{
	return nil;
}



#pragma mark - KVC
/**
 *	When setting a record, we certainly also want to have the same server
 */
- (void)setRecord:(IndivoRecord *)aRecord
{
	if (aRecord != record) {
		record = aRecord;
		self.server = record.server;
	}
}


@end


/**
 *	Returns the status as INDocumentStatus correlating to the string representation
 */
INDocumentStatus documentStatusFor(NSString *stringStatus)
{
	if ([@"active" isEqualToString:stringStatus]) {
		return INDocumentStatusActive;
	}
	else if ([@"archived" isEqualToString:stringStatus]) {
		return INDocumentStatusArchived;
	}
	else if ([@"void" isEqualToString:stringStatus]) {
		return INDocumentStatusVoid;
	}
	
	DLog(@"Unknown document status: \"%@\"", stringStatus);
	return INDocumentStatusUnknown;
}

/**
 *	The other way round, returns the string corresponding to a given status
 */
NSString* stringStatusFor(INDocumentStatus documentStatus)
{
	if (INDocumentStatusActive == documentStatus) {
		return @"active";
	}
	else if (INDocumentStatusArchived == documentStatus) {
		return @"archived";
	}
	else if (INDocumentStatusVoid == documentStatus) {
		return @"void";
	}
	
	DLog(@"Unknown document status");
	return @"";
}
