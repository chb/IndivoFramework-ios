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


@implementation INObject

@synthesize nodeName = _nodeName, nodeType;


/**
 *	Returns a fresh node with nodeName set
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
 *	The INObject implementation sets the node name and node type (if a type attribute is found in the XML node) from an
 *	INXMLNode parsed from an Indivo XML (!).
 *	In subclasses, this methed replaces all properties with values found in the node, leaves those not present untouched.
 *	This method is called from the designated initializer, subclasses should override it to set custom properties and call
 *	[super setFromNode:<node>]
 *	@attention If you are using INXMLNodes to parse your custom XML this method will only do the right thing if your XML
 *	has the same structure as Indivo has for the specific node. For custom XML it's usually better to create blank new
 *	INObjects and set their properties by hand.
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
 *	This method returns an object for the first child node found with the given name in the given node
 *	@param aNode A node to be searched for the child
 *	@param childName The name of the child node to find
 *	@param deaultObj If no desired child node exists, the default object will be returned
 */
+ (id)objectFromNode:(INXMLNode *)aNode forChildNamed:(NSString *)childName
{
	if (!childName) {
		return nil;
	}
	
	INXMLNode *child = [aNode childNamed:childName];
	
	// create new
	INObject *newObject = [[self alloc] initFromNode:child];
	if (!child) {
		newObject.nodeName = childName;
	}
	
	return newObject;
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
 *	Return an XML representation of the object
 */
- (NSString *)xml
{
	return [NSString stringWithFormat:@"<%@ />", self.nodeName];
}

/**
 *	Returns the XML of all child nodes
 */
- (NSString *)innerXML
{
	return nil;
}

/**
 *	We forward the class method on instance calls unless we have a personal nodeName
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
