/*
 IndivoAppDocument.h
 IndivoFramework
 
 Created by Pascal Pfiffner on 02/29/12.
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

#import "IndivoAppDocument.h"
#import "IndivoServer.h"

@implementation IndivoAppDocument

@synthesize tree;



+ (id)newOnServer:(IndivoServer *)aServer
{
	IndivoAppDocument *doc = [IndivoAppDocument new];
	doc.server = aServer;
	return doc;
}

/**
 *	Overridden because we only have a tree instance variable
 */
- (void)setFromNode:(INXMLNode *)node
{
	self.nodeName = node.name;
	NSString *newType = [node attr:@"type"];
	if (newType) {
		self.nodeType = newType;
	}
	
	// document id
	if ([node attr:@"id"]) {
		self.uuid = [node attr:@"id"];
	}
	
	// and the tree!
	self.tree = node;
}



#pragma mark - XML
- (INXMLNode *)tree
{
	if (!tree) {
		self.tree = [INXMLNode nodeWithName:@"tree"];
	}
	return tree;
}

/**
 *	Override this method to return the tree created from our "tree" instance node.
 */
- (NSString *)innerXML
{
	return [tree childXML];
}



#pragma mark - Server Actions
/**
 *	We override this method because we need a two-legged oauth call if this is a non-record specific document
 */
- (void)performMethod:(NSString *)aMethod withBody:(NSString *)body orParameters:(NSArray *)parameters httpMethod:(NSString *)httpMethod callback:(INSuccessRetvalueBlock)callback
{
	if (self.record) {
		[super performMethod:aMethod withBody:body orParameters:parameters httpMethod:httpMethod callback:callback];
	}
	
	if (!self.server) {
		NSString *errStr = [NSString stringWithFormat:@"Fatal Error: I have no server! %@", self];
		SUCCESS_RETVAL_CALLBACK_OR_LOG_ERR_STRING(callback, errStr, 2000)
		return;
	}
	
	// create the desired INServerCall instance
	INServerCall *call = [INServerCall new];
	call.method = aMethod;
	call.body = body;
	call.parameters = parameters;
	call.HTTPMethod = httpMethod;
	call.myCallback = callback;
	
	NSError *error = nil;
	call.oauth = [self.server createOAuthWithAuthMethodClass:@"MPOAuthAuthenticationMethodTwoLegged" error:&error];
	if (!call.oauth) {
		SUCCESS_RETVAL_CALLBACK_OR_LOG_ERR_STRING(callback, [error localizedDescription], [error code]);
		return;
	}
	
	// let the server do the work
	[self.server performCall:call];
}


/**
 *	App-specific documents don't support to be replaced, so we first post the new version of the document and then delete the old one
 */
- (void)replace:(INCancelErrorBlock)callback
{
	// when pushing, our UUID will change because we technically become a new document. Thus remember the old path for the delete-call later on
	NSString *deletePath = [self documentPath];
	
	// push us again
	[self forceNotOnServer];
	[self push:^(BOOL userDidCancel, NSString *__autoreleasing errorMessage) {
		if (!errorMessage) {
			
			// succeeded, delete old version
			[self performMethod:deletePath
					   withBody:nil
				   orParameters:nil
					 httpMethod:@"DELETE"
					   callback:^(BOOL success, NSDictionary *__autoreleasing userInfo) {
						   if (success) {
							   CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(callback, NO, nil)
						   }
						   else {
							   NSError *error = [userInfo objectForKey:INErrorKey];
							   CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(callback, nil != error, [error localizedDescription])
						   }
					   }];
		}
		else {
			CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(callback, userDidCancel, errorMessage)
		}
	}];
}


- (void)delete:(INCancelErrorBlock)callback
{
	[self performMethod:[self documentPath]
			   withBody:nil
		   orParameters:nil
			 httpMethod:@"DELETE"
			   callback:^(BOOL success, NSDictionary *__autoreleasing userInfo) {
				   if (success) {
					   CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(callback, NO, nil)
				   }
				   else {
					   NSError *error = [userInfo objectForKey:INErrorKey];
					   CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(callback, nil != error, [error localizedDescription])
				   }
			   }];
}



#pragma mark - Data Server Paths
/**
 *	The path to this document, i.e. the path I can GET to receive this document instance
 */
- (NSString *)documentPath
{
	if (self.record) {
		return [NSString stringWithFormat:@"/records/%@/apps/%@/documents/%@", self.record.uuid, self.server.appId, self.uuid];
	}
	return [NSString stringWithFormat:@"/apps/%@/documents/%@", self.server.appId, self.uuid];
}

/**
 *	The base path, e.g. "/records/{record id}/documents/" for documents.
 *	POSTing XML to this path should result in creation of a new object of this class (given it doesn't fail on the server)
 */
- (NSString *)basePostPath
{
	if (self.record) {
		return [NSString stringWithFormat:@"/records/%@/apps/%@/documents/", self.record.uuid, self.server.appId];
	}
	return [NSString stringWithFormat:@"/apps/%@/documents/", self.server.appId];
}

@end
