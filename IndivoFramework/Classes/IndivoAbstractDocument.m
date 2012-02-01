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
#import "NSArray+NilProtection.h"


@interface IndivoAbstractDocument ()

- (NSString *)xmlForObject:(id)anObject nodeName:(NSString *)nodeName;

@end


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
/**
 *	Sets our class properties from the given node and its child nodes.
 *	This method collects all class ivars from this class up until the superclass is "IndivoDocument". Most of our classes are direct IndivoDocument
 *	subclasses, but if not we need to walk the class hierarchy upwards until one below IndivoDocument in order to collect the inherited ivars.
 */
- (void)setFromNode:(INXMLNode *)node
{
	[super setFromNode:node];
	
	// document id
	if (node && [node attr:@"id"]) {
		self.udid = [node attr:@"id"];
	}
	
	// collect all ivars that are subclasses of NSArray or INObject and instantiate them from XML nodes with the same name
	Class currentClass = [self class];
	NSMutableArray *hierarchy = [NSMutableArray arrayWithCapacity:1];
	while (currentClass && 0 != strcmp("IndivoDocument", class_getName(currentClass)) && currentClass != [IndivoAbstractDocument class]) {
		unsigned int num, i;
		Ivar *ivars = class_copyIvarList(currentClass, &num);
		for (i = 0; i < num; i++) {
			id ivarObj = object_getIvar(self, ivars[i]);
			const char *ivar_name = ivar_getName(ivars[i]);
			NSString *ivarName = [NSString stringWithCString:ivar_name encoding:NSUTF8StringEncoding];
			Class ivarClass = [ivarObj class];
			
			// if the object is not initialized, we need to get the Class somewhat hacky by parsing the class name from the ivar type encoding
			if (!ivarClass) {
				NSString *ivarType = [NSString stringWithUTF8String:ivar_getTypeEncoding(ivars[i])];
				if ([ivarType length] > 3) {
					NSString *className = [ivarType substringWithRange:NSMakeRange(2, [ivarType length]-3)];
					ivarClass = NSClassFromString(className);
				}
				if (!ivarClass) {
					DLog(@"WARNING: Class for \"%@\" not loaded: \"%@\"", ivarName, ivarType);
				}
			}
			
			// we got an array instance, try to fill it
			if ([ivarClass isSubclassOfClass:[NSArray class]]) {
				Class itemClass = [currentClass classforProperty:ivarName];
				
				NSArray *children = [node childrenNamed:ivarName];
				NSMutableArray *objects = [NSMutableArray arrayWithCapacity:[children count]];
				for (INXMLNode *child in children) {
					INObject *newObject = [itemClass objectFromNode:child];
					[objects addObjectIfNotNil:newObject];
				}
				
				/// @todo Prevent overwriting existing nodes if the node was not provided
				object_setIvar(self, ivars[i], [objects copy]);
			}
			
			// we got an instance variable of INObject kind, instantiate
			else if ([ivarClass isSubclassOfClass:[INObject class]]) {
				id newVal = [ivarClass objectFromNode:[node childNamed:ivarName]];
				
				/// @todo Prevent overwriting existing nodes if the node was not provided
				object_setIvar(self, ivars[i], newVal);
			}
		}
		free(ivars);
		
		currentClass = [currentClass superclass];
	}
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
	return [NSString stringWithFormat:@"<%@>\n\t%@\n</%@>", [self tagXML], [self innerXML], self.nodeName];
#else
	return [NSString stringWithFormat:@"<%@>%@</%@>", [self tagXML], [self innerXML], self.nodeName];
#endif
}


- (NSString *)tagXML
{
	return [NSString stringWithFormat:@"%@ xmlns=\"%@\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"", [super tagXML], self.nameSpace];
}


/**
 *	This is the main XML generating method.
 *	This method walks all direct properties of the method and if they respond to the "xml" selector, adds the returned XML to this instance's
 *	XML representation. The main "xml" method creates our own node (e.g. <Document xmlns="something">) and adds the result of this method as
 *	the node's inner XML.
 *	@return An XML string or nil
 */
- (NSString *)innerXML
{
	unsigned int num, i;
	
	// collect XML for all ivars
	NSMutableArray *xmlValues = [NSMutableArray array];
	Ivar *ivars = class_copyIvarList([self class], &num);
	for (i = 0; i < num; ++i) {
		NSString *ivarName = [NSString stringWithCString:ivar_getName(ivars[i]) encoding:NSUTF8StringEncoding];
		[xmlValues addObjectIfNotNil:[self xmlForPropertyNamed:ivarName]];
	}
	free(ivars);
	
#ifdef INDIVO_XML_PRETTY_FORMAT
	return [xmlValues componentsJoinedByString:@"\n\t"];
#else
	return [xmlValues componentsJoinedByString:@""];
#endif
}


/**
 *	If the property in an array, calls "xmlForObject:nodeName:" on all elements in the array, otherwise calls that same function on the object.
 *	@return An XML string or nil
 */
- (NSString *)xmlForPropertyNamed:(NSString *)aName
{
	id anObject = [self valueForKey:aName];
	
	// array - loop objects
	if ([anObject isKindOfClass:[NSArray class]]) {
		NSMutableArray *xmlValues = [NSMutableArray array];
		for (id object in anObject) {
			[xmlValues addObjectIfNotNil:[self xmlForObject:object nodeName:aName]];
		}
#ifdef INDIVO_XML_PRETTY_FORMAT
		return [xmlValues componentsJoinedByString:@"\n"];
#else
		return [xmlValues componentsJoinedByString:@""];
#endif
	}
	
	// any other object
	/// @todo if the object is nil but it must be present (canBeNull: returns NO), we should add an empty node maybe?
	return [self xmlForObject:anObject nodeName:aName];
}


/**
 *	Takes any object and tries to return the result of its "xml" selector, if it responds to that. If the object is of INObject ancestry, sets
 *	its nodeName to the passed nodeName if it's not yet set.
 *	@return An XML string or nil
 */
- (NSString *)xmlForObject:(id)anObject nodeName:(NSString *)nodeName
{
	if ([anObject respondsToSelector:@selector(xml)]) {
		
		// if the node does not have its own nodeName (ignoring the class nodeName), set the ivar name as nodeName
		if ([anObject isKindOfClass:[INObject class]]) {
			INObject *node = (INObject *)anObject;
			if (!node->_nodeName) {
				node.nodeName = nodeName;
			}
			
			// warn if we may not validate but do not block XML creation
			if ([node isNull] && ![[self class] canBeNull:node.nodeName]) {
				DLog(@"WARNING: %@ is not set, may generate invalid XML. Will add \"%@\"", node.nodeName, [node xml]);
			}
		}
		
		// get object's XML
		NSString *subXML = [anObject performSelector:@selector(xml)];
#ifdef INDIVO_XML_PRETTY_FORMAT
		subXML = [subXML stringByReplacingOccurrencesOfString:@"\n" withString:@"\n\t"];
#endif
		return subXML;
	}
	return nil;
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
 *	Returns the class of a property from the property map dictionary
 */
+ (Class)classforProperty:(NSString *)propertyName
{
	NSDictionary *map = [self propertyClassMapper];
	NSString *className = [map objectForKey:propertyName];
	if (className) {
		return NSClassFromString(className);
	}
	return nil;
}

/**
 *	The automatically generated IndivoDocument subclasses return a dictionary with property->class mappings. This is important for NSArray properties
 *	to determine the class of the array items.
 */
+ (NSDictionary *)propertyClassMapper
{
	return nil;
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
