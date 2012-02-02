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
 *	from an Indivo XML (!).
 *	In subclasses, this methed replaces all properties with values found in the node, leaves those not present untouched. This method is
 *	called from the designated initializer, subclasses should override it to set custom properties and call  [super setFromNode:<node>]
 *	
 *	@attention If you are using INXMLNodes to parse your custom XML this method will only do the right thing if your XML has the same
 *	structure as Indivo has for the specific node. For custom XML it's usually better to create blank new INObjects and set their properties
 *	by hand.
 */
- (void)setFromNode:(INXMLNode *)node
{
	if (node) {
		self.nodeName = node.name;
		
		NSString *newType = [node attr:@"type"];
		if (newType) {
			self.nodeType = newType;
		}
	}
}

/**
 *	Tries to interpret the attribute string as representing our value. The INObject implementation does nothing.
 */
- (void)setWithAttr:(NSString *)attrName fromNode:(INXMLNode *)aNode
{
}



#pragma mark - Returning Data
/**
 *	An object can decide that it is null, i.e. does not carry data. This is useful for creating empty XML nodes instead of omitting the
 *	node at all by setting the property to nil.
 */
- (BOOL)isNull
{
	return NO;
}

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
	if (mustDeclareType) {
		NSString *myType = self.nodeType;
		if (0 == [myType rangeOfString:INClassGeneratorTypePrefix].location) {
			myType = [myType substringFromIndex:[INClassGeneratorTypePrefix length] + 1];
		}
		return [NSString stringWithFormat:@"%@ xsi:type=\"%@\"", self.nodeName, myType];
	}
	return self.nodeName;
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
	return nil;
}


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
