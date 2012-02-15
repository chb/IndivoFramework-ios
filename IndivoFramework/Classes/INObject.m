/*
 INObject.m
 IndivoFramework
 
 Created by Pascal Pfiffner on 9/26/11.
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

#import "INObject.h"
#import <objc/runtime.h>
#import "NSArray+NilProtection.h"


NSString *const INClassGeneratorClassPrefix = @"Indivo";
NSString *const INClassGeneratorTypePrefix = @"indivo";


@implementation INObject

@synthesize nodeName = _nodeName, nodeType, mustDeclareType;


/**
 *	Returns a fresh node with nodeName set.
 */
+ (id)newWithNodeName:(NSString *)aNodeName
{
	INObject *n = [[self alloc] initFromNode:nil];
	n.nodeName = aNodeName;
	
	return n;
}


/**
 *	The designated initializer
 */
- (id)initFromNode:(INXMLNode *)node
{
	if ((self = [super init])) {
		[self setFromNode:node];
	}
	return self;
}


/**
 *	This method returns an object created representing the the node.
 *	@attention This method may return a subclass of itself if the node specifies an "xsi:type" attribute representing a subclass.
 *	@param aNode A node to be used to initialize the object
 */
+ (id)objectFromNode:(INXMLNode *)aNode
{
	if (!aNode) {
		return nil;
	}
	
	// if the XML node does specify a type, check whether we have the desired class and we are, in fact, a subclass of the suggested class
	NSString *xsiType = [aNode attr:@"xsi:type"];
	if ([xsiType length] > 0) {
		NSString *newClassName = [NSString stringWithFormat:@"%@%@", INClassGeneratorClassPrefix, xsiType];
		Class newClass = NSClassFromString(newClassName);
		if (!newClass) {
			DLog(@"Should override class of %@ to %@, as specified by xsi:type, but that class does not exist", NSStringFromClass(self), newClassName);
		}
		else if (newClass != self && [newClass isSubclassOfClass:self]) {
			INObject *obj = [newClass objectFromNode:aNode];
			obj.mustDeclareType = YES;
			return obj;
		}
	}
	
	return [[self alloc] initFromNode:aNode];
}

/**
 *	This method returns an object created from the string contents of a node attribute.
 *	You should use this method instead of using "newFromString:" directly.
 */
+ (id)objectFromAttribute:(NSString *)anAttribute inNode:(INXMLNode *)aNode
{
	if (!aNode || [anAttribute length] < 1) {
		return nil;
	}
	
	INObject *o = [self new];
	[o setWithAttr:anAttribute fromNode:aNode];
	return o;
}

/**
 *	The INObject implementation sets the node name and node type (if a "type" attribute is found in the XML node) from an INXMLNode parsed
 *	from an Indivo XML.
 *	This methed replaces all properties with values found in the node, leaves those not present untouched. This method is called from the
 *	designated initializer, subclasses should override it to set custom properties and call  [super setFromNode:node]
 */
- (void)setFromNode:(INXMLNode *)aNode
{
	if (aNode) {
		self.nodeName = aNode.name;
		
		NSString *newType = [aNode attr:@"type"];
		if (newType) {
		//	self.nodeType = newType;
		}
		
		// if we have defined attributes, loop our ivars to find the ones we must assign from node attributes
		NSArray *myAttrs = [[self class] attributeNames];
		if ([myAttrs count] > 0) {
			unsigned int num, i;
			Ivar *ivars = class_copyIvarList([self class], &num);
			for (i = 0; i < num; i++) {
				id ivarObj = object_getIvar(self, ivars[i]);
				const char *ivar_name = ivar_getName(ivars[i]);
				NSString *ivarName = [NSString stringWithCString:ivar_name encoding:NSUTF8StringEncoding];
				
				// found the ivar we need
				if ([myAttrs containsObject:ivarName]) {
					NSString *attr = [aNode attr:ivarName];
					if ([attr length] > 0) {
						Class ivarClass = [ivarObj class];
						
						// if the object is not initialized, we need to get the Class somewhat hacky by parsing the class name from the ivar type encoding
						if (!ivarClass) {
							const char *ivar_type = ivar_getTypeEncoding(ivars[i]);
							NSString *ivarType = [NSString stringWithUTF8String:ivar_type];
							if ([ivarType length] > 3) {
								NSString *className = [ivarType substringWithRange:NSMakeRange(2, [ivarType length]-3)];
								ivarClass = NSClassFromString(className);
							}
							if (!ivarClass && 0 != strcmp("#", ivar_type)) {
								DLog(@"WARNING: Class for property \"%@\" on %@ not loaded: \"%s\"", ivarName, NSStringFromClass([self class]), ivar_type);
							}
						}
						
						// depending on the class, set our property
						if ([ivarClass isSubclassOfClass:[INObject class]]) {							// INObject
							[self setValue:[ivarClass objectFromAttribute:ivarName inNode:aNode] forKey:ivarName];
						}
						else if ([ivarClass isSubclassOfClass:[NSString class]]) {						// NSString
							[self setValue:attr forKey:ivarName];
						}
						else if ([ivarClass isSubclassOfClass:[NSNumber class]]) {						// NSNumber
							[self setValue:[NSDecimalNumber decimalNumberWithString:attr] forKey:ivarName];
						}
						else {
							DLog(@"I don't know how to generate an object of class %@ as an attribute for %@", NSStringFromClass(ivarClass), ivarName);
						}
					}
				}
			}
		}
	}
}

/**
 *	Tries to interpret the attribute string as representing our value. The INObject implementation does nothing.
 */
- (void)setWithAttr:(NSString *)attrName fromNode:(INXMLNode *)aNode
{
}



#pragma mark - State Checking
/**
 *	An object can decide that it is null, i.e. does not carry data. This is useful for creating empty XML nodes instead of omitting the
 *	node at all by setting the property to nil.
 */
- (BOOL)isNull
{
	return NO;
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

/**
 *	The properties whose names are returned here are expected to be XML node attributes rather than complete nodes.
 *	XML generation relies on this information, it will not go through the ivar list but only pick properties listed here.
 */
+ (NSArray *)attributeNames
{
	return nil;
}



#pragma mark - Returning XML
/**
 *	Return an XML representation of the object.
 */
- (NSString *)xml
{
	return [NSString stringWithFormat:@"<%@ />", [self tagString]];
}

/**
 *	Returns the tag name and, if mustDeclareType is YES, the xsi:type-attribute, ready to be used as tag name.
 */
- (NSString *)tagString
{
	NSString *tagStr = self.nodeName;
	
	// declare our type?
	if (mustDeclareType) {
		NSString *myType = self.nodeType;
		if (0 == [myType rangeOfString:INClassGeneratorTypePrefix].location) {					/// @todo Here we remove the namespace prefix based on how we generated the class. Cheap.
			myType = [myType substringFromIndex:[INClassGeneratorTypePrefix length] + 1];
		}
		tagStr = [tagStr stringByAppendingFormat:@" xsi:type=\"%@\"", myType];
	}
	
	// add attributes
	NSArray *attrs = [[self class] attributeNames];
	if ([attrs count] > 0) {
		NSMutableArray *propArr = [NSMutableArray arrayWithCapacity:[attrs count]];
		for (NSString *prop in attrs) {
			id object = [self valueForKey:prop];
			
			if (object || ![[self class] canBeNull:prop]) {
				NSString *value = nil;
				if ([object isKindOfClass:[INObject class]]) {					// INObject
					value = [(INObject *)object attributeValue];
				}
				else if ([object isKindOfClass:[NSString class]]) {				// string
					value = object;
				}
				else if ([object isKindOfClass:[NSNumber class]]) {				// number
					value = [object stringValue];
				}
				else if ([object respondsToSelector:@selector(boolValue)]) {	// responds to bool
					value = [object performSelector:@selector(boolValue)] ? @"true" : @"false";
				}
				else {
					DLog(@"Not sure what to do with attribute %@ of class %@", object, NSStringFromClass([object class]));
				}
				
				// add
				if (value) {
					[propArr addObject:[NSString stringWithFormat:@"%@=\"%@\"", prop, value]];
				}
			}
		}
		tagStr = [tagStr stringByAppendingFormat:@" %@", [propArr componentsJoinedByString:@" "]];
	}
	
	return tagStr;
}

/**
 *	Returns the XML of all child nodes.
 */
- (NSString *)innerXML
{
	return nil;
}

/**
 *	Returns the value of this node usable as attribute to another node. Only some of our subclasses support being used as attributes, obviously.
 */
- (NSString *)asAttribute
{
	NSString *attrStr = [self attributeValue];
	return [NSString stringWithFormat:@"%@=\"%@\"", self.nodeName, (attrStr ? [attrStr xmlSafe] : @"")];
}

/**
 *	Returns the string that goes into the attribute value.
 */
- (NSString *)attributeValue
{
	return nil;
}



#pragma mark - Properties
/**
 *	We forward the class method on instance calls unless we have a personal nodeName.
 */
- (NSString *)nodeName
{
	if (_nodeName) {
		return _nodeName;
	}
	return [[self class] nodeName];
}

/**
 *	A class can have a default XML nodeName which will be returned by the instance getter if no specific name is set
 */
+ (NSString *)nodeName
{
	return nil;
}

/**
 *	We forward the class method on instance calls unless we have our personal nodeType
 */
- (NSString *)nodeType
{
	if (nodeType) {
		return nodeType;
	}
	return [[self class] nodeType];
}

/**
 *	This class' type
 */
+ (NSString *)nodeType
{
	return @"";
}


/*
#pragma mark - NSCopying
- (id)copyWithZone:(NSZone *)zone;
{
	INObject *o = [INObject new];
	o->nodeName = [self.nodeName copyWithZone:zone];
	return o;
}	*/



#pragma mark - Utilities
- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ <%@ /> (0x%x)", NSStringFromClass([self class]), self.nodeName, self];
}


@end
