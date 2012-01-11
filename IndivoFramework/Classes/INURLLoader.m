/*
 INURLLoader.h
 IndivoFramework
 
 Created by Pascal Pfiffner on 10/13/11.
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

#import "INURLLoader.h"

@interface INURLLoader ()

@property (nonatomic, copy) INCancelErrorBlock callback;
@property (nonatomic, strong) NSMutableData *loadingCache;
@property (nonatomic, readwrite, copy) NSData *responseData;
@property (nonatomic, readwrite, copy) NSString *responseString;
@property (nonatomic, readwrite, assign) NSUInteger responseStatus;
@property (nonatomic, strong) NSURLResponse *currentResponse;

- (void)prepareWithCallback:(INCancelErrorBlock)aCallback;
- (void)didFinishWithError:(NSError *)anError;

@end


@implementation INURLLoader

@synthesize url, callback, loadingCache;
@synthesize responseData, responseString, responseStatus, currentResponse;
@synthesize expectBinaryData;


- (id)initWithURL:(NSURL *)anURL
{
	if ((self = [super init])) {
		self.url = anURL;
	}
	return self;
}

+ (id)loaderWithURL:(NSURL *)anURL
{
	return [[self alloc] initWithURL:anURL];
}



#pragma mark - URL Loading
/**
 *	Praparations before beginning to load
 */
- (void)prepareWithCallback:(INCancelErrorBlock)aCallback
{
	self.responseData = nil;
	self.responseString = nil;
	self.responseStatus = 1000;
	self.currentResponse = nil;
	self.callback = aCallback;
	self.loadingCache = [NSMutableData data];
}

/**
 *	Start loading data from an URL
 */
- (void)getWithCallback:(INCancelErrorBlock)aCallback
{
	if (!url) {
		CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(aCallback, @"No URL given");
		return;
	}
	
	NSURLRequest *request = [NSURLRequest requestWithURL:url];
	[self performRequest:request withCallback:aCallback];
}

/**
 *	POST body values to our URL
 */
- (void)post:(NSString *)postBody withCallback:(INCancelErrorBlock)aCallback
{
	if (!url) {
		CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(aCallback, @"No URL given");
		return;
	}
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
	request.HTTPMethod = @"POST";
	request.HTTPBody = [postBody dataUsingEncoding:NSUTF8StringEncoding];			/// @todo Should we URL encode this?
	
	[self performRequest:request withCallback:aCallback];
}

/**
 *	Perform an NSURLRequest asynchronically. This method is also internally used as the endpoint of all convenience methods
 */
- (void)performRequest:(NSURLRequest *)aRequest withCallback:(INCancelErrorBlock)aCallback
{
	if (!url) {
		self.url = aRequest.URL;
		if (!url) {
			CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(aCallback, @"No URL given");
			return;
		}
	}
	
	[self prepareWithCallback:aCallback];
	[NSURLConnection connectionWithRequest:aRequest delegate:self];
}


/**
 *	This finishing method creates an NSString from any loaded data and calls the callback, if one was given
 */
- (void)didFinishWithError:(NSError *)anError
{
	if ([loadingCache length] > 0) {
		if ([currentResponse isKindOfClass:[NSHTTPURLResponse class]]) {
			self.responseStatus = [(NSHTTPURLResponse *)currentResponse statusCode];
		}
		
		// extract response string
		self.responseData = loadingCache;
		self.loadingCache = nil;
		if (!expectBinaryData) {
			self.responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
		}
	}
	
	if (callback) {
		callback(NO, [anError localizedDescription]);
		self.callback = nil;
	}
}



#pragma mark - NSURLConnection Delegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	self.currentResponse = response;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[loadingCache appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	[self didFinishWithError:nil];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	if (!error) {
		error = nil;
		ERR(&error, @"Unknown Error", 0);
	}
	[self didFinishWithError:error];
}



#pragma mark - Parsing URL Requests
/**
 *	Parses arguments from a request
 *	@return An NSDictionary containing all arguments found in the request
 */
+ (NSDictionary *)queryFromRequest:(NSURLRequest *)aRequest
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	NSString *queryString = [aRequest.URL query];
	
	// parse args
	NSArray *params = [queryString componentsSeparatedByString:@"&"];
	if ([params count] > 0) {
		for (NSString *param in params) {
			NSArray *hat = [param componentsSeparatedByString:@"="];
			if ([hat count] > 1) {
				NSString *key = [hat objectAtIndex:0];
				hat = [hat mutableCopy];
				[(NSMutableArray *)hat removeObjectAtIndex:0];
				NSString *val = [hat componentsJoinedByString:@"="];
				
				[dict setObject:[val stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] forKey:key];
			}
		}
	}
	
	/// @todo look in header and body for more arguments
	
	return dict;
}


@end
