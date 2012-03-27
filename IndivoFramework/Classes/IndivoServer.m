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
#import "INURLLoader.h"
#import "IndivoServer.h"
#import "IndivoConfig.h"
#import "Indivo.h"
#import "IndivoRecord.h"
#import "IndivoDocuments.h"
#import "INServerCall.h"
#import "MPOAuthAPI.h"
#import "MPOAuthAuthenticationMethodOAuth.h"			// to get ahold of dictionary key constants


@interface IndivoServer ()

@property (nonatomic, strong) NSURL *startURL;									///< The start URL of the app, usually leads to a web screen where the user can select a record to use
@property (nonatomic, strong) NSURL *authorizeURL;								///< The URL where the user can authorize the app

@property (nonatomic, readwrite, strong) NSMutableArray *knownRecords;

@property (nonatomic, strong) MPOAuthAPI *oauth;								///< Handle to our MPOAuth instance with App credentials
@property (nonatomic, strong) NSMutableArray *callQueue;						///< Calls are queued instead of performed in parallel to avoid getting inconsistent results
@property (nonatomic, strong) NSMutableArray *suspendedCalls;					///< Calls that were dequeued, we need to hold on to them to not deallocate them
@property (nonatomic, strong) INServerCall *currentCall;						///< Only one call at a time, this is the current one

@property (nonatomic, strong) IndivoLoginViewController *loginVC;				///< A handle to the currently shown login view controller
@property (nonatomic, readwrite, copy) NSString *lastOAuthVerifier;

- (void)_presentLoginScreenAtURL:(NSURL *)loginURL;

- (MPOAuthAPI *)getOAuthOutError:(NSError * __autoreleasing *)error;

@end


@implementation IndivoServer

NSString *const INErrorKey = @"IndivoError";
NSString *const INRecordIDKey = @"xoauth_indivo_record_id";
NSString *const INResponseStringKey = @"INServerCallResponseText";
NSString *const INResponseXMLKey = @"INServerCallResponseXMLNode";
NSString *const INResponseArrayKey = @"INResponseArray";
NSString *const INResponseDocumentKey = @"INResponseDocument";

NSString *const INInternalScheme = @"indivo-framework";

NSString *const INRecordDocumentsDidChangeNotification = @"INRecordDocumentsDidChangeNotification";
NSString *const INRecordUserInfoKey = @"INRecordUserInfoKey";

@synthesize delegate, activeRecord, knownRecords;
@synthesize appId, callbackScheme, url, ui_url, startURL, authorizeURL;
@dynamic activeRecordId;
@synthesize oauth, callQueue, suspendedCalls, currentCall;
@synthesize loginVC, lastOAuthVerifier;
@synthesize consumerKey, consumerSecret, storeCredentials;



#pragma mark - Initialization
/**
 *	A convenience constructor creating the server for the given delegate. Configuration is automatically read from "IndivoConfig.h"
 */
+ (id)serverWithDelegate:(id<IndivoServerDelegate>)aDelegate
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
		self.suspendedCalls = [NSMutableArray arrayWithCapacity:2];
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
 *	Sets the active record and resets the oauth instance upon logout
 */
- (void)setActiveRecord:(IndivoRecord *)aRecord
{
	if (aRecord != activeRecord) {
		activeRecord = aRecord;
		
		if (!activeRecord) {
			self.oauth = nil;
		}
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
	if ([consumerKey length] < 1) {
		ERR(error, L_(@"No consumer key provided"), 1004)
		return NO;
	}
	if ([consumerSecret length] < 1) {
		ERR(error, L_(@"No consumer secret provided"), 1005)
		return NO;
	}
	
	return YES;
}



#pragma mark - Record Selection
/**
 *	This is the main authentication entry point, this method will ask the delegate where to present a login view controller, if authentication is necessary, and
 *	handle all user interactions until login was successful or the user cancels the login operation.
 *	@param callback A block with a first BOOL argument, which will be YES if the user cancelled the action, and an error string argument, which will be nil if
 *	authentication was successful. By the time this callback is called, the "activeRecord" property will be set (if the call was successful).
 */
- (void)selectRecord:(INCancelErrorBlock)callback
{
	NSError *error = nil;
	
	// check whether we are ready
	if (![self readyToConnect:&error]) {
		NSString *errorStr = error ? [error localizedDescription] : @"Error Connecting";
		CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(callback, NO, errorStr)
		return;
	}
	
	// dequeue current call
	if (currentCall) {
		[self suspendCall:currentCall];
	}
	
	// construct the call
	__unsafe_unretained IndivoServer *this = self;
	self.currentCall = [INServerCall newForServer:self];
	currentCall.HTTPMethod = @"POST";
	currentCall.finishIfAuthenticated = YES;
	
	// here's the callback once record selection has finished
	currentCall.myCallback = ^(BOOL success, NSDictionary *userInfo) {
		BOOL didCancel = NO;
		
		// successfully selected a record
		if (success) {
			NSString *forRecordId = [userInfo objectForKey:INRecordIDKey];
			if (forRecordId && [this.activeRecord is:forRecordId]) {
				this.activeRecord.accessToken = [userInfo objectForKey:@"oauth_token"];
				this.activeRecord.accessTokenSecret = [userInfo objectForKey:@"oauth_token_secret"];
			}
			
			// fetch the contact document to get the record label (this non-authentication call will make the login view controller disappear, don't forget that if you remove it)
			if (this.activeRecord) {
				[this.activeRecord fetchRecordInfoWithCallback:^(BOOL userDidCancel, NSString *__autoreleasing errorMessage) {
					
					// we ignore errors fetching the contact document. Errors will only be logged, not passed on to the callback as the record was still selected successfully
					if (errorMessage) {
						DLog(@"Error fetching contact document: %@", errorMessage);
					}
					
					CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(callback, NO, nil)
				}];
			}
			else {
				DLog(@"There is no active record!");
				CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(callback, NO, @"No active record")
			}
		}
		
		// failed: Cancelled or other failure
		else {
			didCancel = (nil == [userInfo objectForKey:INErrorKey]);
			CANCEL_ERROR_CALLBACK_OR_LOG_USER_INFO(callback, didCancel, userInfo)
		}
	};
	
	// present selection screen
	[self _presentLoginScreenAtURL:self.startURL];
}


/**
 *	Strips current credentials and then does the OAuth dance again. The authorize screen is automatically shown if necessary.
 *	@attention This call is only useful if a call is in progress (but has hit an invalid access token), so it will not do anything without a current call.
 *	@param callback An INCancelErrorBlock callback
 */
- (void)authenticate:(INCancelErrorBlock)callback
{
	NSError *error = nil;
	
	// check whether we are ready
	if (![self readyToConnect:&error]) {
		NSString *errorStr = error ? [error localizedDescription] : @"Error Connecting";
		CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(callback, NO, errorStr)
		return;
	}
	
	// dequeue current call
	if (!currentCall) {
		NSString *errorStr = error ? [error localizedDescription] : @"No current call";
		CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(callback, NO, errorStr)
		return;
	}
	[self suspendCall:currentCall];
	
	// construct the call
	__unsafe_unretained IndivoServer *this = self;
	self.currentCall = [INServerCall newForServer:self];
	currentCall.HTTPMethod = @"POST";
	currentCall.finishIfAuthenticated = YES;
	
	// here's the callback once authentication has finished
	currentCall.myCallback = ^(BOOL success, NSDictionary *userInfo) {
		BOOL didCancel = NO;
		
		// successfully authenticated
		if (success) {
			NSString *forRecordId = [userInfo objectForKey:INRecordIDKey];
			if (forRecordId && [this.activeRecord is:forRecordId]) {
				this.activeRecord.accessToken = [userInfo objectForKey:@"oauth_token"];
				this.activeRecord.accessTokenSecret = [userInfo objectForKey:@"oauth_token_secret"];
			}
			
			userInfo = nil;
		}
		else if (![userInfo objectForKey:INErrorKey]) {
			didCancel = YES;
		}
		
		CANCEL_ERROR_CALLBACK_OR_LOG_USER_INFO(callback, didCancel, userInfo)
	};
	
	// force authentication by wiping current credentials
	currentCall.oauth = [self getOAuthOutError:nil];
	[currentCall.oauth discardCredentials];
	
	[self performCall:currentCall];
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
- (void)loginView:(IndivoLoginViewController *)aLoginController didSelectRecordId:(NSString *)recordId
{
	NSError *error = nil;
	
	/*--
	NSURL *testURL = [self.url URLByAppendingPathComponent:@"version"];
	DLog(@"TESTING: %@", testURL);
	INURLLoader *loader = [INURLLoader loaderWithURL:testURL];
	[loader getWithCallback:^(BOOL userDidCancel, NSString *__autoreleasing errorMessage) {
		DLog(@"GOT:  %@", loader.responseString);
	}];
	//--	*/
	
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
			selectedRecord = [[IndivoRecord alloc] initWithId:recordId onServer:self];
			if (!knownRecords) {
				self.knownRecords = [NSMutableArray array];
			}
			[knownRecords addObject:selectedRecord];
		}
		self.activeRecord = selectedRecord;
		
		// finish the record selection process
		[self performCall:currentCall];
	}
	
	// failed to select a record
	else {
		ERR(&error, @"Did not receive a record", 0)
		[currentCall abortWithError:error];
	}
}

/**
 *	A delegate method which gets called when the callback is received
 */
- (void)loginView:(IndivoLoginViewController *)aLoginController didReceiveVerifier:(NSString *)aVerifier
{
	self.lastOAuthVerifier = aVerifier;
	
	// we should have an active call and an active record here, warn if not
	if (!currentCall) {
		DLog(@"WARNING -- did receive verifier, but no call is in place! Verifier: %@", aVerifier);
	}
	if (!self.activeRecord) {
		DLog(@"WARNING -- no active record");
	}
	
	// continue the auth call by firing it again
	if (loginVC) {
		[loginVC showLoadingIndicator:nil];
	}
	[self performCall:currentCall];
}

/**
 *	Delegate method called when the user dismisses the login screen, i.e. cancels the record selection process
 */
- (void)loginViewDidCancel:(IndivoLoginViewController *)loginController
{
	if (currentCall) {
		[currentCall cancel];
	}
	
	// dismiss login view controller
	if (loginController != loginVC) {
		DLog(@"Very strange, an unknown login controller did just cancel...");
	}
	[loginController dismissAnimated:YES];
	self.loginVC = nil;
}

/**
 *	The user logged out
 */
- (void)loginViewDidLogout:(IndivoLoginViewController *)aLoginController
{
	self.activeRecord = nil;
	[currentCall cancel];
	[delegate userDidLogout:self];
	
	if (loginVC) {
		[loginVC dismissAnimated:YES];
		self.loginVC = nil;
	}
}

/**
 *	The scheme for URL that we treat differently internally (by default this is "indivo-framework")
 */
- (NSString *)callbackSchemeForLoginView:(IndivoLoginViewController *)aLoginController
{
	return self.callbackScheme;
}



#pragma mark - App Specific Documents
/**
 *	Fetches global, app-specific documents.
 *	GETs documents from /apps/<app id>/documents/ with a two-legged OAuth call.
 */
- (void)fetchAppSpecificDocumentsWithCallback:(INSuccessRetvalueBlock)callback
{
	// create the desired INServerCall instance
	INServerCall *call = [INServerCall new];
	call.method = [NSString stringWithFormat:@"/apps/%@/documents/", self.appId];
	call.HTTPMethod = @"GET";
	
	// create callback
	call.myCallback = ^(BOOL success, NSDictionary *__autoreleasing userInfo) {
		NSDictionary *usrIfo = nil;
		
		// fetched successfully...
		if (success) {
			//DLog(@"Incoming XML: %@", [userInfo objectForKey:INResponseStringKey]);
			INXMLNode *docNode = [userInfo objectForKey:INResponseXMLKey];
			NSArray *metaDocuments = [docNode childrenNamed:@"Document"];
			
			// instantiate meta documents...
			NSMutableArray *appDocArr = [NSMutableArray arrayWithCapacity:[metaDocuments count]];
			for (INXMLNode *metaNode in metaDocuments) {
				IndivoMetaDocument *meta = [[IndivoMetaDocument alloc] initFromNode:metaNode withServer:self];
				if (meta) {
					meta.documentClass = [IndivoAppDocument class];
					
					// ...but return the actual app documents
					IndivoAppDocument *appDoc = (IndivoAppDocument *)[meta document];
					if (appDoc) {
						[appDocArr addObject:appDoc];
					}
				}
			}
			
			usrIfo = [NSDictionary dictionaryWithObject:appDocArr forKey:INResponseArrayKey];
		}
		else {
			usrIfo = userInfo;
		}
		
		SUCCESS_RETVAL_CALLBACK_OR_LOG_USER_INFO(callback, success, usrIfo)
	};
	
	// shoot!
	[self performCall:call];
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
	
	// performing an arbitrary call, we can dismiss any login view controller
	if (loginVC && ![aCall isAuthenticationCall]) {
		[loginVC dismissAnimated:YES];
		self.loginVC = nil;
	}
	
	// maybe this call was suspended, remove it from the store
	[suspendedCalls removeObject:aCall];
	
	// there already is a call in progress
	if (aCall != currentCall && [currentCall hasBeenFired]) {
		[callQueue addObject:aCall];
		return;
	}
	
	// assure our OAuthAPI is correctly setup
	NSError *error = nil;
	if (!aCall.oauth) {
		aCall.oauth = [self getOAuthOutError:&error];
	}
	if (!aCall.oauth) {
		[aCall abortWithError:error];
		return;
	}
	
	// setup and fire
	aCall.server = self;
	self.currentCall = aCall;
	
	[aCall fire];
}

/**
 *	Callback to let us know a call has finished.
 *	The call will have called the callback by now, no need for us to do any further handling
 */
- (void)callDidFinish:(INServerCall *)aCall
{
	[callQueue removeObject:aCall];
	if (aCall == currentCall) {
		self.currentCall = nil;
	}
	
	// move on
	INServerCall *nextCall = nil;
	if ([callQueue count] > 0) {
		nextCall = [callQueue objectAtIndex:0];
	}
	else if ([suspendedCalls count] > 0) {
		nextCall = [suspendedCalls objectAtIndex:0];
	}
	
	if (nextCall) {
		[self performCall:nextCall];
	}
}

/**
 *	Dequeues a call without finishing it. This is useful for calls that need to be re-performed after another call has been made, e.g. if the token was
 *	rejected and we'll be retrying the call after obtaining a new token. In this case, we don't want the call to finish, but we can't leave it in the queue
 *	because it would block subsequent calls.
 *	@attention Do NOT use this to cancel a call because the callback will not be called!
 */
- (void)suspendCall:(INServerCall *)aCall
{
	[suspendedCalls addObject:aCall];
	[callQueue removeObject:aCall];
	
	if (aCall == currentCall) {
		self.currentCall = nil;
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
 *	Returns our standard oauth instance or fills the error, if it couldn't be created
 *	@param error An error pointer to be filled if OAuth creation fails
 *	@return self.oauth
 */
- (MPOAuthAPI *)getOAuthOutError:(NSError *__autoreleasing *)error
{
	if (!oauth) {
		self.oauth = [self createOAuthWithAuthMethodClass:nil error:error];
	}
	return oauth;
}


/**
 *	Creates a new MPOAuthAPI instance with our current settings.
 *	@param authClass An MPOAuthAuthenticationMethod class name. If nil picks three-legged oauth.
 */
- (MPOAuthAPI *)createOAuthWithAuthMethodClass:(NSString *)authClass error:(NSError *__autoreleasing *)error;
{
	MPOAuthAPI *api = nil;
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
		
		// specify authentication method
		if ([authClass length] > 0) {
			[config setObject:authClass forKey:MPOAuthAuthenticationMethodKey];
		}
		
		// create
		api = [[MPOAuthAPI alloc] initWithCredentials:credentials withConfiguration:config autoStart:NO];
		[api discardCredentials];
		
		if (!api) {
			errStr = @"Failed to create OAuth API";
			errCode = 2001;
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
	}
	return api;
}



#pragma mark - Utilities
- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ <0x%X> Server at %@", NSStringFromClass([self class]), self, url];
}


@end
