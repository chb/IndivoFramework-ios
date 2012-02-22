/*
 INDocumentStatusNode.h
 IndivoFramework
 
 Created by Pascal Pfiffner on 2/22/12.
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

#import "INDocumentStatusNode.h"
#import "Indivo.h"
#import "INDateTime.h"


@implementation INDocumentStatusNode

@synthesize by, at, status, reason;


- (void)setFromNode:(INXMLNode *)node
{
	[super setFromNode:node];
	self.by = [node attr:@"by"];
	self.at = [INDateTime parseDateFromISOString:[node attr:@"at"]];
	self.status = documentStatusFor([node attr:@"status"]);
	self.reason = [node childNamed:@"reason"].text;
}


+ (NSString *)nodeType
{
	return @"indivo:DocumentStatus";
}

- (BOOL)isNull
{
	return (nil == self.by && nil == self.at);
}

- (NSString *)tagString
{
	NSMutableArray *parts = [NSMutableArray arrayWithCapacity:3];
	if (by) {
		[parts addObject:[NSString stringWithFormat:@"by=\"%@\"", by]];
	}
	if (at) {
		[parts addObject:[NSString stringWithFormat:@"at=\"%@\"", [INDateTime isoStringFrom:at]]];
	}
	if (INDocumentStatusUnknown != status) {
		[parts addObject:[NSString stringWithFormat:@"status=\"%@\"", stringStatusFor(status)]];
	}
	if ([parts count] > 0) {
		return [NSString stringWithFormat:@"%@ %@", self.nodeName, [parts componentsJoinedByString:@" "]];
	}
	return self.nodeName;
}

- (NSString *)xml
{
	if ([self isNull]) {
		return @"";
	}
	
#ifdef INDIVO_XML_PRETTY_FORMAT
	return [NSString stringWithFormat:@"<%@>\n\t<reason>%@</reason>\n</%@>", [self tagString], reason ? reason : @"", self.nodeName];
#else
	return [NSString stringWithFormat:@"<%@><reason>%@</reason></%@>", [self tagString], reason ? reason : @"", self.nodeName];
#endif
}


@end
