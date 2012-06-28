/*
 INParentObject.m
 IndivoFramework
 
 Created by Pascal Pfiffner on 6/26/12.
 Copyright (c) 2012 Children's Hospital Boston
 
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

#import "INParentObject.h"
#import "NSObject+ClassUtils.h"
#import <objc/runtime.h>

@implementation INParentObject


- (NSString *)xml
{
#ifdef INDIVO_XML_PRETTY_FORMAT
	return [NSString stringWithFormat:@"<%@>\n\t%@\n</%@>", [self tagString], [self innerXML], self.nodeName];
#else
	return [NSString stringWithFormat:@"<%@>%@</%@>", [self tagString], [self innerXML], self.nodeName];
#endif
}


/**
 *	This method replaces all properties with values found in the node but leaves those properties not present untouched. This method is called from the
 *	designated initializer, subclasses should override it to set custom properties and call  [super setFromNode:node]
 */
- (void)setFromNode:(INXMLNode *)aNode
{
	if (aNode) {
		[super setFromNode:aNode];
		
		NSArray *myAttrs = [[self class] attributeNames];
		
		// try to auto-generate properties for all ivar names by inferring the node name and pull out their content
		unsigned int num, i;
		Ivar *ivars = class_copyIvarList([self class], &num);
		for (i = 0; i < num; i++) {
			id ivarObj = object_getIvar(self, ivars[i]);
			NSString *ivarName = ivarNameFromIvar(ivars[i]);
			Class ivarClass = ivarObj ? [ivarObj class] : classFromIvar(ivars[i]);
			if (!ivarClass) {
				DLog(@"Can't determine class for ivar \"%@\"", ivarName);
				continue;
			}
			
			BOOL useAttribute = [myAttrs containsObject:ivarName];
			id value = nil;
			INXMLNode *myNode = [aNode childNamed:ivarName];
			
			// depending on the class, instantiate our object
			if (myNode) {
				if ([ivarClass isSubclassOfClass:[INObject class]]) {							// INObject
					value = useAttribute ? [ivarClass objectFromAttribute:ivarName inNode:myNode] : [INObject objectFromNode:myNode];
				}
				else if ([ivarClass isSubclassOfClass:[NSString class]]) {						// NSString
					value = useAttribute ? [[myNode attr:ivarName] copy] : [myNode.text copy];
				}
				else if ([ivarClass isSubclassOfClass:[NSNumber class]]) {						// NSNumber
					NSString *numString = useAttribute ? [myNode attr:ivarName] : myNode.text;
					value = ([numString length] > 0) ? [[NSDecimalNumber alloc] initWithString:numString] : nil;
				}
				else {
					DLog(@"I don't know how to generate an object of class %@ as an attribute for %@", NSStringFromClass(ivarClass), ivarName);
				}
			}
			
			// set the ivar (even if it's nil!)
			object_setIvar(self, ivars[i], value);
		}
		free(ivars);
	}
}


/**
 *	Returns the XML of all child nodes.
 *	By default, this walks all the ivars of the class (NOT including the ivars of the superclass) and creates nodes based on the ivar name.
 */
- (NSString *)innerXML
{
	NSMutableArray *xmlValues = [NSMutableArray array];
	
	// collect all ivars
	unsigned int num, i;
	Ivar *ivars = class_copyIvarList([self class], &num);
	for (i = 0; i < num; ++i) {
		id anObject = object_getIvar(self, ivars[i]);
		
		// we can omit empty ivars
		if (anObject) {
			NSString *ivarName = ivarNameFromIvar(ivars[i]);
			NSString *content = @"";
			
			// ivar is another INObject
			if ([anObject respondsToSelector:@selector(innerXML)]) {
				content = [anObject innerXML];
			}
			
			// is it a string itself?
			else if ([anObject isKindOfClass:[NSString class]]) {
				content = anObject;
			}
			
			// does it respond to stringValue?
			else if ([anObject respondsToSelector:@selector(stringValue)]) {
				content = [anObject performSelector:@selector(stringValue)];
			}
			
			// nothing of the above, treat as BOOL
			else {
				content = @"true";
			}
			
			if (content) {
				[xmlValues addObject:[NSString stringWithFormat:@"<%@>%@</%@>", ivarName, content, ivarName]];
			}
		}
	}
	free(ivars);
	
	// compose
#ifdef INDIVO_XML_PRETTY_FORMAT
	return [xmlValues componentsJoinedByString:@"\n\t"];
#else
	return [xmlValues componentsJoinedByString:@""];
#endif
}


@end
