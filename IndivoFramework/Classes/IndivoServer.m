/*
 IndivoServer.m
 IndivoFramework
 
 Created by Pascal Pfiffner on 9/2/11.
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

#import "IndivoServer.h"
#import "IndivoConfig.h"
#import "Indivo.h"
#import "IndivoRecord.h"
#import "INServerCall.h"
#import "MPOAuthAPI.h"
#import "MPOAuthAuthenticationMethodOAuth.h"			// to get ahold of dictionary key constants


@interface IndivoServer ()

@property (nonatomic, strong) NSURL *startURL;									///< The start URL of the app, usually leads to a web screen where the user can select a record to use
@property (nonatomic, strong) NSURL *authorizeURL;								///< The URL where the user can authorize the app

@property (nonatomic, readwrite, strong) NSMutableArray *knownRecords;

@property (nonatomic, strong) MPOAuthAPI *oauth;								///< Handle to our MPOAuth instance with App credentials
@property (nonatomic, strong) NSMutableArray *callQueue;						///< Calls are queued instead of performed in parallel to avoid getting inconsistent results
@property (nonatomic, strong) INServerCall *currentCall;						///< Only one call at a time, this is the current one
@property (nonatomic, strong) INServerCall *recSelectCall;						///< The call currently performing authentication

@property (nonatomic, strong) IndivoLoginViewController *loginVC;				///< A handle to the currently shown login view controller
@property (nonatomic, readwrite, copy) NSString *lastOAuthVerifier;

@property (nonatomic, readwrite, strong) IndivoWebApp *webApp;

- (void)_presentLoginScreenAtURL:(NSURL *)loginURL;

- (MPOAuthAPI *)getOAuthOutError:(NSError * __autoreleasing *)error;

@end


@implementation IndivoServer

NSString *const INErrorKey = @"IndivoError";
NSString *const INRecordIDKey = @"xoauth_indivo_record_id";
NSString *const INResponseStringKey = @"INServerCallResponseText";
NSString *const INResponseXMLKey = @"INServerCallResponseXMLNode";
NSString *const INResponseArrayKey = @"INResponseArray";

NSString *const INInternalScheme = @"indivo-framework";

NSString *const INRecordDocumentsDidChangeNotification = @"INRecordDocumentsDidChangeNotification";
NSString *const INRecordUserInfoKey = @"INRecordUserInfoKey";

@synthesize delegate, activeRecord, knownRecords;
@synthesize appId, callbackScheme, url, ui_url, startURL, authorizeURL;
@dynamic activeRecordId;
@synthesize oauth, callQueue, currentCall, recSelectCall;
@synthesize loginVC, lastOAuthVerifier;
@synthesize consumerKey, consumerSecret, storeCredentials;
@synthesize webApp;



#pragma mark - Initialization
/**
 *	A convenience constructor creating the server for the given delegate. Configuration is automatically read from "IndivoConfig.h"
 */
+ (IndivoServer *)serverWithDelegate:(id<IndivoServerDelegate>)aDelegate
{
	IndivoServer *s = [self new];
	s.delegate = aDelegate;
	
	return s;
}


/**
 * The designated initializer
 */
- (id)init
{
	if ((self = [super init])) {
		if ([kIndivoFrameworkServerURL length] > 0) {
			self.url = [NSURL URLWithString:kIndivoFrameworkServerURL];
		}
		if ([kIndivoFrameworkUIServerURL length] > 0) {
			self.ui_url = [NSURL URLWithString:kIndivoFrameworkUIServerURL];
		}
		if ([kIndivoFrameworkAppId length] > 0) {
			self.appId = kIndivoFrameworkAppId;
		}
		if ([kIndivoFrameworkConsumerKey length] > 0) {
			self.consumerKey = kIndivoFrameworkConsumerKey;
		}
		if ([kIndivoFrameworkConsumerSecret length] > 0) {
			self.consumerSecret = kIndivoFrameworkConsumerSecret;
		}
		
		self.callQueue = [NSMutableArray arrayWithCapacity:2];
	}
	return self;
}

/**
 *	startURL is the start URL of the app, usually leads to a webpage where the user can choose a record. It is created from ui_url
 *	and by default is located at "indivo-ui-server.com/apps/app@id"
 */
- (NSURL *)startURL
{
	if (!startURL) {
		if ([appId length] < 1) {
			ALog(@"appId is not set, startURL will most likely be invalid!");
		}
		self.startURL = [[ui_url URLByAppendingPathComponent:@"apps"] URLByAppendingPathComponent:self.appId];
	}
	return startURL;
}

/**
 *	authorizeURL is created from ui_url
 */
- (NSURL *)authorizeURL
{
	if (!authorizeURL) {
		self.authorizeURL = [self.ui_url URLByAppendingPathComponent:@"oauth/authorize"];
	}
	return authorizeURL;
}

/**
 *	The callback to feed to authorizeURL
 */
- (NSURL *)authorizeCallbackURL
{
	return [NSURL URLWithString:[NSString stringWithFormat:@"%@:///did_receive_verifier/", INInternalScheme]];
}

- (NSString *)callbackScheme
{
	return callbackScheme ? callbackScheme : INInternalScheme;
}



#pragma mark - Server
/**
 *	Sets the active record and resets the oauth instance
 */
- (void)setActiveRecord:(IndivoRecord *)aRecord
{
	if (aRecord != activeRecord) {
		activeRecord = aRecord;
		self.oauth = nil;
	}
}

/**
 *	Shortcut to the active record id
 */
- (NSString *)activeRecordId
{
	return activeRecord.uuid;
}

/**
 *	Obviously returns the record with the given id, returns nil if it is not found
 */
- (IndivoRecord *)recordWithId:(NSString *)recordId
{
	for (IndivoRecord *record in knownRecords) {
		if ([record.uuid isEqualToString:recordId]) {
			return record;
		}
	}
	return nil;
}

/**
 *	Test server readyness
 *	@return A BOOL whether the server is ready; if NO, error is guaranteed to not be nil, if a pointer was passed
 */
- (BOOL)readyToConnect:(NSError * __autoreleasing *)error
{
	if ([[url absoluteString] length] < 5) {
		ERR(error, L_(@"No server URL provided"), 1001)
		return NO;
	}
	if ([[ui_url absoluteString] length] < 5) {
		ERR(error, L_(@"No UI server URL provided"), 1002)
		return NO;
	}
	if ([appId length] < 1) {
		ERR(error, L_(@"No App id provided"), 1003)
		return NO;
	}
	
	return YES;
}



#pragma mark - Record Selection
/**
 *	This is the main authentication entry point, this method will ask the delegate where to present a login view controller, if authentication is
 *	necessary, and handle all user interactions until login was successful or the user cancels the login operation.
 *	@param callback A block with a first BOOL argument, which will be YES if the user cancelled the action, and an error string argument, which
 *	will be nil if authentication was successful. By the time this callback is called, the "activeRecord" property will be set, if the call was
 *	successful
 */
- (void)selectRecord:(INCancelErrorBlock)callback
{
	NSError *error = nil;
	
	// a record select call is already active, abort
	if (recSelectCall) {
		DLog(@"A record selection call was already active, aborting that call");
		recSelectCall.myCallback = nil;
		[recSelectCall abortWithError:nil];
	}
	
	// check whether we are ready
	if (![self readyToConnect:&error]) {
		NSString *errorStr = error ? [error localizedDescription] : @"Error Connecting";
		CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(callback, NO, errorStr)
		return;
	}
	
	// construct the call
	__unsafe_unretained IndivoServer *this = self;
	self.recSelectCall = [INServerCall callOnServer:self];
	recSelectCall.HTTPMethod = @"POST";
	recSelectCall.finishIfAuthenticated = YES;
	
	// here's the callback once record selection has finished
	recSelectCall.myCallback = ^(BOOL success, NSDictionary *userInfo) {
		
		// successfully selected a record
		if (success) {
			NSString *forRecordId = [userInfo objectForKey:INRecordIDKey];
			if (forRecordId && [this.activeRecord is:forRecordId]) {
				this.activeRecord.accessToken = [userInfo objectForKey:@"oauth_token"];
				this.activeRecord.accessTokenSecret = [userInfo objectForKey:@"oauth_token_secret"];
			}
			
			// fetch the contact document
			[this.activeRecord fetchRecordInfoWithCallback:^(BOOL userDidCancel, NSString *__autoreleasing errorMessage) {
				if (this.loginVC) {
					[this.loginVC dismissAnimated:YES];
					this.loginVC = nil;
				}
				
				// we ignore errors fetching the contact document. Errors will only be logged, not passed on to the callback as the record was still selected successfully
				if (errorMessage) {
					DLog(@"Error fetching contact document: %@", errorMessage);
				}
				
				CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(callback, NO, nil)
			}];
		}
		
		// failed: Cancelled or other failure
		else {
			if (this.loginVC) {
				[this.loginVC dismissAnimated:YES];
				this.loginVC = nil;
			}
			
			CANCEL_ERROR_CALLBACK_OR_LOG_USER_INFO(callback, NO, userInfo)
		}
	};
	
	// present selection screen
	[self _presentLoginScreenAtURL:self.startURL];
}


/**
 *	Asks our delegate where to place the login screen, then shows the login screen and loads the given URL
 *	@param loginURL The URL to load to show a login interface
 *	@param callbackURL The URL to load after successful authentication
 *	@return Returns NO if the login screen could not be presented, YES if it's being shown
 */
- (void)_presentLoginScreenAtURL:(NSURL *)loginURL
{
	// already showing a login screen, just load the URL
	if (loginVC) {
		[loginVC loadURL:loginURL];
		return;
	}
	
	// newly display a login screen
	IndivoLoginViewController *vc = [IndivoLoginViewController new];
	UIViewController *pvc = [delegate viewControllerToPresentLoginViewController:vc];
	if (pvc) {
		vc.delegate = self;
		vc.startURL = loginURL;
		self.loginVC = vc;
		if ([pvc respondsToSelector:@selector(presentViewController:animated:completion:)]) {		// iOS 5+ only
			[pvc presentViewController:loginVC animated:YES completion:NULL];
		}
		else {
			[pvc presentModalViewController:loginVC animated:YES];
		}
	}
	else {
		DLog(@"Delegate did not provide a view controller, cannot present login screen");
	}
}



#pragma mark - Login View Controller Delegate
/**
 *	Called when the user selected a record
 */
- (void)loginView:(IndivoLoginViewController *)aLoginController didSelectRecordId:(NSString *)recordId label:(NSString *)recordLabel
{
	NSError *error = nil;
	
	// got a record
	if ([recordId length] > 0) {
		[self.oauth discardCredentials];
		
		// set the active record
		IndivoRecord *selectedRecord = [self recordWithId:recordId];
		if (selectedRecord) {
			if (selectedRecord.accessToken) {
				[self.oauth setCredential:selectedRecord.accessToken withName:kMPOAuthCredentialAccessToken];
				[self.oauth setCredential:selectedRecord.accessTokenSecret withName:kMPOAuthCredentialAccessTokenSecret];
			}
		}
		
		// instantiate new record
		else {
			selectedRecord = [[IndivoRecord alloc] initWithId:recordId name:recordLabel onServer:self];
			if (!knownRecords) {
				self.knownRecords = [NSMutableArray array];
			}
			[knownRecords addObject:selectedRecord];
		}
		self.activeRecord = selectedRecord;
		
		// finish the record selection process
		[self performCall:recSelectCall];
	}
	
	// failed to select a record
	else {
		ERR(&error, @"Did not receive a record", 0)
		[recSelectCall abortWithError:error];
	}
}

/**
 *	A delegate method which gets called when the callback is received
 */
- (void)loginView:(IndivoLoginViewController *)aLoginController didReceiveVerifier:(NSString *)aVerifier
{
	self.lastOAuthVerifier = aVerifier;
	
	// we should have an active recSelectCall and an active record here, warn if not
	if (!recSelectCall) {
		DLog(@"WARNING -- did receive verifier, but no recSelectCall is in place! Verifier: %@", aVerifier);
	}
	if (!self.activeRecord) {
		DLog(@"WARNING -- no active record");
	}
	
	// continue the auth call by firing it again
	if (loginVC) {
		[loginVC showLoadingIndicator:nil];
	}
	[self performCall:recSelectCall];
}

/**
 *	Delegate method called when the user dismisses the login screen, i.e. cancels the record selection process
 */
- (void)loginViewDidCancel:(IndivoLoginViewController *)loginController
{
	if (recSelectCall) {
		[recSelectCall abortWithError:nil];
	}
	else {
		if (loginController != loginVC) {
			DLog(@"Very strange, an unknown login controller did just cancel...");
			[loginController dismissAnimated:YES];
		}
		else {
			[loginVC dismissAnimated:YES];
		}
		self.loginVC = nil;
	}
}

/**
 *	The user logged out
 */
- (void)loginViewDidLogout:(IndivoLoginViewController *)aLoginController
{
	self.activeRecord = nil;
	[recSelectCall abortWithError:nil];
	[delegate userDidLogout:self];
}

/**
 *	The scheme for URL that we treat differently internally (by default this is "indivo-framework")
 */
- (NSString *)callbackSchemeForLoginView:(IndivoLoginViewController *)aLoginController
{
	return self.callbackScheme;
}


#pragma mark - Call Handling
/**
 *	Perform a method on our server
 *	This method is usally called by INServerObject subclasses, but you can use it bare if you wish
 *	@param aCall The call to perform
 */
- (void)performCall:(INServerCall *)aCall
{
	if (!aCall) {
		DLog(@"No call to perform");
		return;
	}
	
	// there already is a call in progress (skip for recSelectCall)
	if (recSelectCall != aCall && [currentCall hasBeenFired]) {
		[callQueue addObject:aCall];
		return;
	}
	
	// assure our OAuthAPI is correctly setup
	NSError *error = nil;
	aCall.oauth = [self getOAuthOutError:&error];
	if (!aCall.oauth) {
		[aCall abortWithError:error];
		return;
	}
	
	// setup call
	aCall.server = self;
	if (recSelectCall != aCall) {
		self.currentCall = aCall;
	}
	
	[aCall fire];
}

/**
 *	Callback to let us know a call has finished.
 *	The call will have called the callback by now, no need for us to do any further handling
 */
- (void)callDidFinish:(INServerCall *)aCall
{
	if (aCall == currentCall) {
		[callQueue removeObject:aCall];
		self.currentCall = nil;
		
		// move on
		if ([callQueue count] > 0) {
			INServerCall *nextCall = [callQueue objectAtIndex:0];
			[self performCall:nextCall];
		}
	}
	if (aCall == recSelectCall) {
		self.recSelectCall = nil;
	}
}

/**
 *	Callback when the call is stuck at user authorization
 *	@return We always return NO here, but display the login screen ourselves, loaded from the provided URL
 */
- (BOOL)shouldAutomaticallyAuthenticateFrom:(NSURL *)authURL
{
	[self _presentLoginScreenAtURL:authURL];
	return NO;
}



#pragma mark - MPOAuth Creation
/**
 *	Creates an MPOAuthAPI instance with credentials appropriate for either our App
 *	@param error A pointer to an error pointer, guaranteed to not be nil if returning NO
 *	@return Whether or not the MPOAuthAPI instance was created successfully
 *	@todo Improve caching
 */
- (MPOAuthAPI *)getOAuthOutError:(NSError *__autoreleasing *)error
{
	// if we already have the correct instance, return it
	if (self.oauth) {
		return self.oauth;
	}
	
	NSString *errStr = nil;
	NSUInteger errCode = 0;
	NSDictionary *credentials = [NSDictionary dictionaryWithObjectsAndKeys:
								 self.consumerKey, kMPOAuthCredentialConsumerKey,
								 self.consumerSecret, kMPOAuthCredentialConsumerSecret,
								 nil];
	
	// we need a URL
	if (!url) {
		errStr = @"Cannot create our oauth instance: No URL set";
		errCode = 1001;
	}
	
	// and we certainly need consumer key and secret
	else if ([[credentials objectForKey:kMPOAuthCredentialConsumerKey] length] < 1) {
		errStr = @"Cannot create our oauth instance: No consumer key provided";
		errCode = 1004;
	}
	else if ([[credentials objectForKey:kMPOAuthCredentialConsumerSecret] length] < 1) {
		errStr = @"Cannot create our oauth instance: No consumer secret provided";
		errCode = 1005;
	}
	
	// create our instance with credentials and configured with the correct URLs
	else {
		NSMutableDictionary *config = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									   [[url URLByAppendingPathComponent:@"oauth/request_token"] absoluteString], MPOAuthRequestTokenURLKey,
									   [self.authorizeURL absoluteString], MPOAuthUserAuthorizationURLKey,
									   [[url URLByAppendingPathComponent:@"oauth/access_token"] absoluteString], MPOAuthAccessTokenURLKey,
									   self.authorizeURL, MPOAuthAuthenticationURLKey,
									   url, MPOAuthBaseURLKey,
									   nil];
		
		MPOAuthAPI *myOAuth = [[MPOAuthAPI alloc] initWithCredentials:credentials withConfiguration:config autoStart:NO];
		[myOAuth discardCredentials];
		
		if (!myOAuth) {
			errStr = @"Failed to create OAuth API";
			errCode = 2001;
		}
		else {
			self.oauth = myOAuth;
		}
	}
	
	// report an error
	if (errCode > 0) {
		if (error) {
			ERR(error, errStr, errCode)
		}
		else {
			DLog(@"Error %d: %@", errCode, errStr);
		}
		return nil;
	}
	return oauth;
}



#pragma mark - Utilities
- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ <0x%X> Server at %@", NSStringFromClass([self class]), self, url];
}


@end
