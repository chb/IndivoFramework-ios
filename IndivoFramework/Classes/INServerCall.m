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


#import "INServerCall.h"
#import "IndivoServer.h"
#import "INXMLParser.h"
#import "INXMLNode.h"


@interface INServerCall ()

@property (nonatomic, readwrite, assign) BOOL hasBeenFired;
@property (nonatomic, strong) NSDictionary *responseObject;

- (void)didFinishSuccessfully:(BOOL)success returnObject:(NSDictionary *)returnObject;

@end


@implementation INServerCall

@synthesize server;
@synthesize method, body, parameters, HTTPMethod, oauth, finishIfAuthenticated;
@synthesize hasBeenFired, responseObject, myCallback;


/**
 *	Convenience constructor
 */
+ (INServerCall *)call
{
	return [self new];
}

/**
 *	Convenience constructor, sets the server
 *	@param aServer An indivo server instance
 *	@return an autoreleased INServerCall instance
 */
+ (INServerCall *)callOnServer:(id)aServer
{
	return [[self alloc] initWithServer:aServer];
}

/**
 *	The designated initializer
 */
- (id)initWithServer:(id)aServer
{
	if ((self = [super init])) {
		self.server = aServer;
		self.HTTPMethod = @"GET";
	}
	return self;
}



#pragma mark - OAuth Setup
- (void)setOauth:(MPOAuthAPI *)newOAuth
{
	if (newOAuth != oauth) {
		if (oauth) {
			if (self == oauth.authDelegate) {
				oauth.authDelegate = nil;
			}
			if (self == oauth.loadDelegate) {
				oauth.loadDelegate = nil;
			}
			
			NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
			[center removeObserver:self name:MPOAuthNotificationAccessTokenReceived object:nil];
			[center removeObserver:self name:MPOAuthNotificationAccessTokenRejected object:nil];
			[center removeObserver:self name:MPOAuthNotificationAccessTokenRefreshed object:nil];
			[center removeObserver:self name:MPOAuthNotificationOAuthCredentialsReady object:nil];
			[center removeObserver:self name:MPOAuthNotificationErrorHasOccurred object:nil];
		}
		
		oauth = newOAuth;			// This certainly looks weird, holy new ARC technology...
		
		// we are the delegate of our oauth instance and we want to receive all its notifications
		if (oauth) {
			NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
			[center addObserver:self selector:@selector(oauthNotificationReceived:) name:MPOAuthNotificationAccessTokenReceived object:oauth];
			[center addObserver:self selector:@selector(oauthNotificationReceived:) name:MPOAuthNotificationAccessTokenRejected object:oauth];
			[center addObserver:self selector:@selector(oauthNotificationReceived:) name:MPOAuthNotificationAccessTokenRefreshed object:oauth];
			[center addObserver:self selector:@selector(oauthNotificationReceived:) name:MPOAuthNotificationOAuthCredentialsReady object:oauth];
			[center addObserver:self selector:@selector(oauthNotificationReceived:) name:MPOAuthNotificationErrorHasOccurred object:oauth];
			
			oauth.authDelegate = self;
			oauth.loadDelegate = self;
		}
	}
}



#pragma mark - Connection Fire Methods
/**
 *	Sends off as a GET request
 *	@param inMethod The method to use, i.e. the REST path
 *	@param inParameters An array full of @"key=value" NSString objects, can be nil
 *	@param inOAuth The MPOAuthAPI instance to use for the call
 *	@param inCallback The callback block to call when the method has finished
 */
- (void)get:(NSString *)inMethod withParameters:(NSArray *)inParameters oauth:(MPOAuthAPI *)inOAuth callback:(INSuccessRetvalueBlock)inCallback
{
	self.method = inMethod;
	self.parameters = inParameters;
	self.HTTPMethod = @"GET";
	self.oauth = inOAuth;
	self.myCallback = inCallback;
	
	[self fire];
}

/**
 *	Sends off as a POST request
 *	@param inMethod The method to use, i.e. the REST path
 *	@param inParameters An array full of @"key=value" NSString objects, can be nil
 *	@param inOAuth The MPOAuthAPI instance to use for the call
 *	@param inCallback The callback block to call when the method has finished
 */
- (void)post:(NSString *)inMethod withParameters:(NSArray *)inParameters oauth:(MPOAuthAPI *)inOAuth callback:(INSuccessRetvalueBlock)inCallback
{
	self.method = inMethod;
	self.parameters = inParameters;
	self.HTTPMethod = @"POST";
	self.oauth = inOAuth;
	self.myCallback = inCallback;
	
	[self fire];
}

/**
 *	Sends off a POST request with the given body
 *	@param inMethod The method to use, i.e. the REST path
 *	@param bodyString The body string to POST
 *	@param inOAuth The MPOAuthAPI instance to use for the call
 *	@param inCallback The callback block to call when the method has finished
 */
- (void)post:(NSString *)inMethod body:(NSString *)bodyString oauth:(MPOAuthAPI *)inOAuth callback:(INSuccessRetvalueBlock)inCallback
{
	self.method = inMethod;
	self.body = bodyString;
	self.HTTPMethod = @"POST";
	self.oauth = inOAuth;
	self.myCallback = inCallback;
	
	[self fire];
}

/**
 *	Most versatile fire method, used internally from the get: and post: methods.
 *	@param inMethod The method to use, i.e. the REST path
 *	@param inParameters An array full of @"key=value" NSString objects, can be nil
 *	@param httpMethod The HTTP-method (GET, PUT, POST) to use
 *	@param inOAuth The MPOAuthAPI instance to use for the call
 *	@param inCallback The callback block to call when the method has finished
 */
- (void)fire:(NSString *)inMethod withParameters:(NSArray *)inParameters httpMethod:(NSString *)httpMethod oauth:(MPOAuthAPI *)inOAuth callback:(INSuccessRetvalueBlock)inCallback
{
	self.method = inMethod;
	self.parameters = inParameters;
	self.HTTPMethod = httpMethod;
	self.oauth = inOAuth;
	self.myCallback = inCallback;
	
	[self fire];
}

/**
 *	Fires the request as currently prepared.
 *	All get, post and fire methods go through this method in their last step.
 */
- (void)fire
{
	if (!oauth) {
		DLog(@"Cannot fire without oauth property. Call: %@", self);
		return;
	}
	
	if (HTTPMethod) {
		self.oauth.defaultHTTPMethod = HTTPMethod;
	}
	self.hasBeenFired = YES;
	
	// let MPOAuth do its magic
	if (![oauth isAuthenticated]) {
		[oauth authenticate];
	}
	
	// the main work performing call
	else if (!self.finishIfAuthenticated) {
		if ([body length] > 0) {
			NSData *bodyData = [body dataUsingEncoding:NSUTF8StringEncoding];
			
			NSURL *fullURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", [self.oauth.baseURL absoluteString], self.method]];
			NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:fullURL];
			
			[request setHTTPMethod:HTTPMethod];
			[request setValue:@"application/xml" forHTTPHeaderField:@"Content-Type"];
			[request setValue:[NSString stringWithFormat:@"%d", [bodyData length]] forHTTPHeaderField:@"Content-Length"];
			[request setHTTPBody:bodyData];
			
			[self.oauth performURLRequest:request withDelegate:self];
		}
		else {
			[self.oauth performMethod:method withParameters:parameters delegate:self];
		}
	}
	
	// already authenticated and finishIfAuthenticated is set, finishing without round-trip to the server
	else {
		[self didFinishSuccessfully:YES returnObject:nil];
	}
}



#pragma mark - Finishing and Aborting
/**
 *	A method to finish the call early, but successfully.
 *	Use abortWithError: to finish a call early and unsuccessfully. This method provokes the same actions as if it was fired
 *	and returned successfully. This method is NOT being called when the URL connection finishes.
 */
- (void)finishWith:(NSDictionary *)returnObject
{
	if (self.hasBeenFired) {
		/// @todo Abort the connection
	}
	[self didFinishSuccessfully:YES returnObject:returnObject];
}

/**
 *	This method can be called to abort a call and have it send the provided error with its callback
 *	@param error An NSError object to be delivered through the callback
 */
- (void)abortWithError:(NSError *)error
{
	/// @todo truly abort loading, if in progress
	[self didFinishSuccessfully:NO returnObject:(error ? [NSDictionary dictionaryWithObject:error forKey:INErrorKey] : nil)];
}

/**
 *	Internal finishing method. Calls the callback, if there is one, and informs the server that the call has finished.
 */
- (void)didFinishSuccessfully:(BOOL)success returnObject:(NSDictionary *)returnObject
{
	self.oauth = nil;
	
	// send callback and inform the server
	SUCCESS_RETVAL_CALLBACK_OR_LOG_USER_INFO(myCallback, success, returnObject);
	self.myCallback = nil;
	
	// inform the server
	[server callDidFinish:self];
}



#pragma mark - OAuth Delegate Methods -- Asking us for information
/**
 *	MPOAuth will call this method to know where to redirect after successfull authentication
 */
- (NSURL *)callbackURLForCompletedUserAuthorization
{
	return [server authorizeCallbackURL];
}

/**
 *	MPOAuth will call this method to get ahold of the oAuth verifier.
 *	We must extract the verifier from the callback URL (specified in "- (NSURL *)callbackURLForCompletedUserAuthorization" and
 *	called on the App Delegate) and return it from this method
 */
- (NSString *)oauthVerifierForCompletedUserAuthorization
{
	return server.lastOAuthVerifier;
}

/**
 *	Indivo needs to associate a token with a given record id, so we provide that when performing the request token request
 */
- (NSDictionary *)additionalRequestTokenParameters
{
	return [NSDictionary dictionaryWithObject:server.activeRecordId forKey:@"indivo_record_id"];
}

/**
 *	If the server is our delegate, we return NO here and the server loads the login page
 */
- (BOOL)automaticallyRequestAuthenticationFromURL:(NSURL *)inAuthURL withCallbackURL:(NSURL *)inCallbackURL
{
	return [server shouldAutomaticallyAuthenticateFrom:inAuthURL];
}



#pragma mark - OAuth Auth Delegate Methods -- Final Responses
/**
 *	Delegate method after successful authentication
 */
- (void)authenticationDidSucceed
{
	if (finishIfAuthenticated) {
		[self didFinishSuccessfully:YES returnObject:self.responseObject];
	}
	else {
		[self fire];
	}
}

/**
 *	Delegate method that gets called after failure to receive an access_token
 */
- (void)authenticationDidFailWithError:(NSError *)error
{
	if (!error) {
		error = nil;
		ERR(&error, @"Authentication did fail with an unknown error", 0);
	}
	[self didFinishSuccessfully:NO returnObject:[NSDictionary dictionaryWithObject:error forKey:INErrorKey]];
}



#pragma mark - Receiving OAuth Notifications
/**
 *	One method to intercept all MPOAuth notifications.
 *	We only subscribe to receive notifications from "our" MPOAuthAPI object. The notifications will be delivered before the finishing
 *	authDelegate methods will be called.
 */
- (void)oauthNotificationReceived:(NSNotification *)aNotification
{
	NSString *nName = [aNotification name];
	NSDictionary *nDict = [aNotification userInfo];
	
	// credentials are now ready, that's what we've been waiting for
	if ([MPOAuthNotificationOAuthCredentialsReady isEqualToString:nName]) {
		self.responseObject = nDict;
	}
	
	// we finally got an access token, that's what we've been waiting for
	else if ([MPOAuthNotificationAccessTokenReceived isEqualToString:nName]) {
		if (![nDict objectForKey:INRecordIDKey]) {
			DLog(@"Got access token but no record id??\n%@", nDict);
		}
		self.responseObject = nDict;
	}
	
	// **access** token rejected
	else if ([MPOAuthNotificationAccessTokenRejected isEqualToString:nName]) {
		NSError *error = nil;
		//ERR(&error, [nDict objectForKey:NSLocalizedDescriptionKey] ? [nDict objectForKey:NSLocalizedDescriptionKey] : @"Access Token Rejected", 403);	// server does always send "Permission Denied"
		ERR(&error, @"Access Token Rejected", 403);
		self.responseObject = [NSDictionary dictionaryWithObject:error forKey:INErrorKey];
	}
	
	// general error
	else if ([MPOAuthNotificationErrorHasOccurred isEqualToString:nName]) {
		NSError *error = nil;
		ERR(&error, [nDict objectForKey:NSLocalizedDescriptionKey] ? [nDict objectForKey:NSLocalizedDescriptionKey] : @"OAuth Error", 400);
		self.responseObject = [NSDictionary dictionaryWithObject:error forKey:INErrorKey];
	}
	
	/// @todo unhandled notification, ignore as soon as everything works
	else {
		DLog(@"UNHANDLED NOTIFICATION RECEIVED: %@", aNotification);
	}
}



#pragma mark - OAuth Load Delegate
- (void)connectionFinishedWithResponse:(NSURLResponse *)aResponse data:(NSData *)inData
{
	NSString *retString = nil;
	
	// we always assume string data, so just create a string when we have response data
	if (inData) {
		retString = [[NSString alloc] initWithData:inData encoding:NSUTF8StringEncoding];
	}
	
	if ([retString length] > 0) {
		INXMLNode *xmlDoc = nil;
		NSError *xmlParseError = nil;
		
		// parse XML if we got XML
		if ([@"application/xml" isEqualToString:[aResponse MIMEType]]) {
			xmlDoc = [INXMLParser parseXML:retString error:&xmlParseError];
		}
		
		// compose the response; there is the possibility that we already got an OAuth notification in responseObject, don't discard that one
		NSMutableDictionary *retDict = responseObject ? [responseObject mutableCopy] : [NSMutableDictionary dictionary];
		[retDict setObject:retString forKey:INResponseStringKey];
		if (xmlDoc) {
			[retDict setObject:xmlDoc forKey:INResponseXMLKey];
		}
		if (xmlParseError) {
			[retDict setObject:xmlParseError forKey:INErrorKey];
		}
		self.responseObject = retDict;
	}
	[self didFinishSuccessfully:YES returnObject:responseObject];
}

- (void)connectionFailedWithResponse:(NSURLResponse *)aResponse error:(NSError *)inError
{
	if (![responseObject objectForKey:INErrorKey]) {
		self.responseObject = [NSDictionary dictionaryWithObject:inError forKey:INErrorKey];
	}
	else {
		DLog(@"Failed with error %@, but will return previously encountered error %@", inError, [responseObject objectForKey:INErrorKey]);
	}
	[self didFinishSuccessfully:NO returnObject:responseObject];
}



#pragma mark - Utilities
- (NSString *)description
{
	NSString *action = method ? [@"\n" stringByAppendingString:method] : @"Record Selection";
	NSString *bodyString = body ? [@"\n" stringByAppendingString:body] : @"";
	NSString *paramString = parameters ? [NSString stringWithFormat:@"with %@", parameters] : @"";
	return [NSString stringWithFormat:@"%@ <0x%X> %@: \"%@\"%@%@", NSStringFromClass([self class]), self, HTTPMethod, action, paramString, bodyString];
}


@end
