/*
 INServerCall.h
 IndivoFramework
 
 Created by Pascal Pfiffner on 9/16/11.
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

#import "INServerObject.h"
#import "INServerCall.h"


@interface INServerObject ()

@property (nonatomic, readwrite, assign) BOOL onServer;

@end


@implementation INServerObject

@synthesize server, uuid, onServer;


/**
 *	The designated initializer
 */
- (id)initFromNode:(INXMLNode *)node withServer:(IndivoServer *)aServer
{
	if ((self = [super initFromNode:node])) {
		self.server = aServer;
		if (node) {
			self.onServer = YES;
		}
	}
	return self;
}

- (void)setFromNode:(INXMLNode *)node
{
	[super setFromNode:node];
	
	NSString *newId = [node attr:@"id"];
	if (newId) {
		self.uuid = newId;
	}
}



#pragma mark - Data Fetching
/**
 *	The basic method to perform REST methods on the server with App credentials.
 *	Uses a INServerCall instance to handle the loading; INServerCall only allows a body string or parameters, but not both, with
 *	the body string taking precedence.
 *	@param aMethod The path to call on the server
 *	@param body The body string
 *	@param parameters An array full of strings in the form "key=value"
 *	@param httpMethod The http method, for now GET, PUT or POST
 *	@param callback A block to execute when the call has finished
 */
- (void)performMethod:(NSString *)aMethod withBody:(NSString *)body orParameters:(NSArray *)parameters httpMethod:(NSString *)httpMethod callback:(INSuccessRetvalueBlock)callback
{
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
	
	// let the server do the work
	[self.server performCall:call];
}


/**
 *	Shortcut for GETting data
 */
- (void)get:(NSString *)aMethod callback:(INSuccessRetvalueBlock)callback
{
	[self performMethod:aMethod withBody:nil orParameters:nil httpMethod:@"GET" callback:callback];
}

/**
 *	Shortcut for GETting data with parameters
 */
- (void)get:(NSString *)aMethod parameters:(NSArray *)paramArray callback:(INSuccessRetvalueBlock)callback
{
	[self performMethod:aMethod withBody:nil orParameters:paramArray httpMethod:@"GET" callback:callback];	
}

/**
 *	Shortcut for PUTting data
 */
- (void)put:(NSString *)aMethod body:(NSString *)bodyString callback:(INSuccessRetvalueBlock)callback
{
	[self performMethod:aMethod withBody:bodyString orParameters:nil httpMethod:@"PUT" callback:callback];
}

/**
 *	Shortcut for POSTing body data
 */
- (void)post:(NSString *)aMethod body:(NSString *)bodyString callback:(INSuccessRetvalueBlock)callback
{
	[self performMethod:aMethod withBody:bodyString orParameters:nil httpMethod:@"POST" callback:callback];
}

/**
 *	Shortcut for POSTing parameters
 *	@param aMethod The method, aka REST-path, to perform
 *	@param paramArray An array full of "key=value" strings; will be URL-encoded automatically
 *	@param callback The callback-block to call when the method has finished
 */
- (void)post:(NSString *)aMethod parameters:(NSArray *)paramArray callback:(INSuccessRetvalueBlock)callback
{
	[self performMethod:aMethod withBody:nil orParameters:paramArray httpMethod:@"POST" callback:callback];
}



#pragma mark - Utilities
/**
 *	Sets onServer to YES for the receiver
 */
- (void)markOnServer
{
	self.onServer = YES;
}

/**
 *	This is provided for subclasses, the fact that onServer is readonly but settable by this and markOnServer underlines the fact that
 *	you should only change this property when you know what you're doing.
 */
- (void)forceNotOnServer
{
	self.onServer = NO;
}

/**
 *	Shortcut method to test if the document has the given ID
 */
- (BOOL)is:(NSString *)anId
{
	return [self.uuid isEqualToString:anId];
}

/**
 *	Objects are considered equal if:
 *	- They are pointer equal
 *	- They are of the same class and have the same udid
 */
- (BOOL)isEqual:(id)object
{
	if (self == object) {
		return YES;
	}
	if ([object isMemberOfClass:[self class]]) {
		if ([[object uuid] isEqualToString:self.uuid]) {
			return YES;
		}
	}
	return NO;
}

- (NSUInteger)hash
{
	return [self.uuid hash];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ <%@ id=\"%@\" /> (%p)", NSStringFromClass([self class]), self.nodeName, self.uuid, self];
}


@end
