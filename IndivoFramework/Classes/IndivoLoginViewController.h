/*
 IndivoLoginViewController.h
 IndivoFramework
 
 Created by Pascal Pfiffner on 9/12/11.
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


#import <UIKit/UIKit.h>

@class IndivoLoginViewController;


/**
 *	A protocol to receive notifications from an IndivoLoginViewController
 */
@protocol IndivoLoginViewControllerDelegate <NSObject>

- (void)loginView:(IndivoLoginViewController *)aLoginController didSelectRecordId:(NSString *)recordId label:(NSString *)recordLabel;		///< Called when a record was selected
- (void)loginView:(IndivoLoginViewController *)aLoginController didReceiveVerifier:(NSString *)aVerifier;		///< Called when the login screen gets called with our verifier callback URL
- (void)loginViewDidCancel:(IndivoLoginViewController *)aLoginController;										///< The user dismissed the login screen without loggin in successfully
- (void)loginViewDidLogout:(IndivoLoginViewController *)aLoginController;										///< If the user logged out, we want to discard cached data
- (NSString *)callbackSchemeForLoginView:(IndivoLoginViewController *)aLoginController;							///< Before loading a URL that URL is checked whether the scheme corresponds to the internal scheme, and if it does a different action may be performed than loading the URL in the webView

@end


/**
 *	This class provides the view controller to log the user in
 */
@interface IndivoLoginViewController : UIViewController <UIWebViewDelegate>

@property (nonatomic, assign) id <IndivoLoginViewControllerDelegate> delegate;				///< The delegate to receive callbacks
@property (nonatomic, strong) NSURL *startURL;												///< The URL to load initially

@property (nonatomic, readonly, strong) UIWebView *webView;									///< The web view to present HTML
@property (nonatomic, readonly, strong) UINavigationBar *titleBar;							///< A handle to the title bar being displayed
@property (nonatomic, readonly, strong) UIBarButtonItem *backButton;						///< To navigate back
@property (nonatomic, readonly, strong) UIBarButtonItem *cancelButton;						///< The cancel button which dismisses the login view

- (void)loadURL:(NSURL *)aURL;
- (void)reload:(id)sender;
- (void)cancel:(id)sender;
- (void)dismiss:(id)sender;
- (void)dismissAnimated:(BOOL)animated;

- (void)showLoadingIndicator:(id)sender;
- (void)hideLoadingIndicator:(id)sender;


@end
