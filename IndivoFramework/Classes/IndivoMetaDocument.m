/*
 IndivoMetaDocument.h
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

#import "IndivoMetaDocument.h"
#import "IndivoDocument.h"
#import "IndivoRecord.h"

@interface IndivoMetaDocument ()

@property (nonatomic, readwrite, strong) IndivoDocument *document;
@property (nonatomic, readwrite, copy) NSString *digest;

@end


@implementation IndivoMetaDocument

@synthesize document, documentClass, type;
@synthesize digest;
@synthesize createdAt, creator, suppressedAt, suppressor, replacedBy, replaces, original, latest, status, nevershare;



#pragma mark - Document Handling
- (IndivoDocument *)document
{
	if (!document) {
		if (!self.documentClass) {
			DLog(@"WARNING: No class found for meta document of type \"%@\", will return a nil document", type);
		}
		
		// app-specific documents may not have a record
		if (!self.record) {
			self.document = [[documentClass alloc] initFromNode:nil withServer:self.server];
			[document updateWithMeta:self];
		}
		else {
			self.document = [[documentClass alloc] initFromNode:nil forRecord:self.record withMeta:self];
		}
	}
	
	return document;
}



#pragma mark - XML
- (void)setFromNode:(INXMLNode *)node
{
	/// @todo this method is called from the init method and thus BEFORE self.record is set. Think of a way to verify record_id with the actually
	//	assigned record, potentially a string ivar to be checked in setRecord:
	NSString *recordId = [node attr:@"record_id"];
	if (self.record && ![self.record is:recordId]) {
		DLog(@"The record ID received does not match our current record. Found \"%@\" but have %@", recordId, self.record);
		// we should probably fail here
	}
	
	// sounds good, proceed
	[super setFromNode:node];
	if (node) {
		NSString *xmlType = [node attr:@"type"];
		if (NSNotFound != [xmlType rangeOfString:@"#"].location) {
			self.type = [xmlType substringFromIndex:([xmlType rangeOfString:@"#"].location + 1)];
		}
		self.digest = [node attr:@"digest"];
		/// @todo digest checking?
	}
}


- (NSString *)xml
{
#ifdef INDIVO_XML_PRETTY_FORMAT
	return [NSString stringWithFormat:@"<%@ id=\"%@\" type=\"%@\" size=\"\" digest=\"%@\" record_id=\"%@\">\n\t%@\n</%@>", self.nodeName, self.uuid, self.nameSpace, self.digest, self.record.uuid, [self innerXML], self.nodeName];
#else
	return [NSString stringWithFormat:@"<%@ id=\"%@\" type=\"%@\" size=\"\" digest=\"%@\" record_id=\"%@\">%@</%@>", self.nodeName, self.udid, self.namespace, self.digest, self.record.udid, [self innerXML], self.nodeName];
#endif
}



#pragma mark - KVC
- (Class)documentClass
{
	if (!documentClass) {
		self.documentClass = [IndivoDocument documentClassForType:self.type];
	}
	return documentClass;
}


@end
