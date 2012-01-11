/*
 INProvider.m
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

#import "INProvider.h"

@implementation INProvider

@synthesize name, institution;


- (void)setFromNode:(INXMLNode *)node
{
	[super setFromNode:node];
	self.name = [node childNamed:@"name"].text;
	self.institution = [node childNamed:@"institution"].text;
}

+ (NSString *)nodeType
{
	return @"indivo:Provider";
}

- (BOOL)isNull
{
	return ([name length] < 1 && [institution length] < 1);
}

- (NSString *)xml
{
	if ([self isNull]) {
		return [NSString stringWithFormat:@"<%@ />", self.nodeName];
	}
	
#ifdef INDIVO_XML_PRETTY_FORMAT
	return [NSString stringWithFormat:@"<%@ type=\"%@\">\n\t<name>%@</name>\n\t<institution>%@</institution>\n</%@>", self.nodeName, self.nodeType, (self.name ? self.name : @""), (self.institution ? self.institution : @""), self.nodeName];
#else
	return [NSString stringWithFormat:@"<%@ type=\"%@\"><name>%@</name><institution>%@</institution></%@>", self.nodeName, self.nodeType, (self.name ? self.name : @""), (self.institution ? self.institution : @""), self.nodeName]
#endif
}


@end
