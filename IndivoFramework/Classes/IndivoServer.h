/*
 IndivoServer.h
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

/**
 *	@mainpage
 *	Welcome to the API documentation of IndivoFramework for iOS.
 *	
 *	@section Instructions
 *	Instructions an how to setup the framework can be found in the README also provided with the framework, which
 *	can be viewed nicely formatted on our github page: https://github.com/chb/IndivoFramework-ios
 *	
 *	@section Creating an Xcode Docset
 *	You can use Doxygen to create a documentation. The easiest way to do this is to open the Doxyfile with DoxyWizard and press "Run". This
 *	will create an HTML documentation in `Docs/html` and a ready-to-build LaTeX documentation in `Docs/latex`.
 *	
 *	After building the documentation like mentioned above, you just need to install it:<br>
 *		$ cd IndivoFramework-ios/Docs/html<br>
 *		$ make install<br>
 *	After you relaunch Xcode, the documentation should be available in the Organizer and can be accessed like the standard Cocoa documentation
 *	by `ALT`-clicking code parts.
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "Indivo.h"
#import "INServerCall.h"
#import "IndivoLoginViewController.h"

@class IndivoServer;
@class IndivoRecord;


/**
 *	The Indivo Server Delegate Protocol
 */
@protocol IndivoServerDelegate <NSObject>

/**
 *	Return a view controller from which you want to present the login view controller.
 *	The login view controller will be passed into this method so you can customize its chrome.
 *	@remark The delegate MUST respond to this method.
 *	@param loginViewController The login view controller about to load the login screen
 *	@return A view controller from which to present the login view controller
 */
- (UIViewController *)viewControllerToPresentLoginViewController:(IndivoLoginViewController *)loginViewController;

/**
 *	This delegate method is called when the user logs out. You must implement this method in your delegate, and ideally
 *	unload all record data once the user logs out.
 *	@remark The delegate MUST respond to this method.
 *	@param fromServer The server from which the user disconnected
 */
- (void)userDidLogout:(IndivoServer *)fromServer;

@end



/**
 *	A class to represent the server you want to connect to.
 *	This is the main interaction point of the framework with your targeted Indivo Server.
 */
@interface IndivoServer : NSObject <IndivoLoginViewControllerDelegate>

@property (nonatomic, assign) id<IndivoServerDelegate> delegate;				///< A delegate to receive notifications

@property (nonatomic, strong) NSURL *url;										///< The server URL
@property (nonatomic, strong) NSURL *ui_url;									///< The UI-server URL (needed for login)
@property (nonatomic, copy) NSString *appId;									///< The id of the app as it is known on the server
@property (nonatomic, copy) NSString *consumerKey;								///< The consumer key for the app
@property (nonatomic, copy) NSString *consumerSecret;							///< The consumer secret for the app
@property (nonatomic, copy) NSString *callbackScheme;							///< Defaults to "indivo-framework", but you can use your own

@property (nonatomic, strong) IndivoRecord *activeRecord;						///< The currently active record
@property (nonatomic, readonly, copy) NSString *activeRecordId;					///< Shortcut method to get the id of the currently active record
@property (nonatomic, readonly, strong) NSMutableArray *knownRecords;			///< A cache of the known records on this server. Not currently used by the framework.

@property (nonatomic, assign) BOOL storeCredentials;							///< NO by default. If you set this to YES, a successful login will save credentials to the system keychain
@property (nonatomic, readonly, copy) NSString *lastOAuthVerifier;				///< Storing our OAuth verifier here until MPOAuth asks for it


+ (id)serverWithDelegate:(id<IndivoServerDelegate>)aDelegate;

- (void)selectRecord:(INCancelErrorBlock)callback;
- (void)authenticate:(INCancelErrorBlock)callback;
- (IndivoRecord *)recordWithId:(NSString *)recordId;

// authentication
- (BOOL)readyToConnect:(NSError **)error;
- (BOOL)shouldAutomaticallyAuthenticateFrom:(NSURL *)authURL;
- (NSURL *)authorizeCallbackURL;

// app-specific storage
- (void)fetchAppSpecificDocumentsWithCallback:(INSuccessRetvalueBlock)callback;

// performing calls
- (void)performCall:(INServerCall *)aCall;
- (void)callDidFinish:(INServerCall *)aCall;
- (void)suspendCall:(INServerCall *)aCall;

// OAuth
- (MPOAuthAPI *)createOAuthWithAuthMethodClass:(NSString *)authClass error:(NSError *__autoreleasing *)error;


@end
