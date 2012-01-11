/*
 INXMLNode.h
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


#import "INXMLNode.h"

@implementation INXMLNode

@synthesize parent, name;
@synthesize attributes, children, text;


/**
 *	Returns an empty node with given node name
 */
+ (INXMLNode *)nodeWithName:(NSString *)aName
{
	return [self nodeWithName:aName attributes:nil];
}

/**
 *	Returns a node with given name and attributes
 */
+ (INXMLNode *)nodeWithName:(NSString *)aName attributes:(NSDictionary *)attributes
{
	INXMLNode *n = [self new];
	n.name = aName;
	n.attributes = [attributes mutableCopy];
	return n;
}

/**
 *	Add a child node
 */
- (void)addChild:(INXMLNode *)aNode
{
	aNode.parent = self;
	if (!children) {
		self.children = [NSMutableArray arrayWithObject:aNode];
	}
	else {
		[children addObject:aNode];
	}
}


/**
 *	Return the first child node or nil, if there are none
 */
- (INXMLNode *)firstChild
{
	if ([children count] > 0) {
		return [children objectAtIndex:0];
	}
	return nil;
}

/**
 *	Returns the first child node matching the given name. Only the direct child nodes are checked, no deep searching is performed.
 */
- (INXMLNode *)childNamed:(NSString *)childName
{
	if ([children count] > 0) {
		for (INXMLNode *child in children) {
			if ([child.name isEqualToString:childName]) {
				return child;
			}
		}
	}
	return nil;
}

/**
 *	Searches child nodes for a node with given name. Only the direct child nodes are checked, no deep searching is performed.
 *	@return Returns an array with nodes matching the name, nil otherwise
 */
- (NSArray *)childrenNamed:(NSString *)childName
{
	NSMutableArray *found = nil;
	if ([children count] > 0) {
		found = [NSMutableArray array];
		for (INXMLNode *child in children) {
			if ([child.name isEqualToString:childName]) {
				[found addObject:child];
			}
		}
	}
	return found;
}

/**
 *	A shortcut to get the object representing the attribute with the given name
 */
- (id)attr:(NSString *)attributeName
{
	if ([attributeName length] > 0 && attributes) {
		return [attributes objectForKey:attributeName];
	}
	return nil;
}

/**
 *	Sets an attribute
 */
- (void)setAttr:(NSString *)attrValue forKey:(NSString *)attrKey
{
	if (attrKey && attrValue) {
		if (!attributes) {
			self.attributes = [NSMutableDictionary dictionary];
		}
		[attributes setObject:attrValue forKey:attrKey];
	}
}



#pragma mark - Utilities
- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ \"%@\" <0x%x>", NSStringFromClass([self class]), name, self];
}


@end
