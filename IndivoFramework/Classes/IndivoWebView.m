/*
 IndivoWebView.h
 IndivoFramework
 
 Created by Pascal Pfiffner on 9/9/11.
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


#import "IndivoWebView.h"


@interface IndivoWebView ()

@property(nonatomic, assign) BOOL loaded;							///< A private BOOL to keep track of our loaded state
@property(nonatomic, readwrite, strong) UIWebView *webView;
@property(nonatomic, strong) UIControl *loadingView;					///< A private view overlaid during loading activity

- (void) showLoadingIndicator:(id)sender;
- (void) hideLoadingIndicator:(id)sender;

@end


@implementation IndivoWebView

@synthesize url, loaded;
@synthesize webView, loadingView;


/**
 *	The designated initializer
 */
- (id)init
{
	return [super initWithNibName:nil bundle:nil];
}



#pragma mark - View lifecycle

/**
 *	Load our view
 */
- (void)loadView
{
	CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
	appFrame.origin = CGPointZero;
	
	// the view
	UIView *v = [[UIView alloc] initWithFrame:appFrame];
	v.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	v.backgroundColor = [UIColor viewFlipsideBackgroundColor];
	
	// add a WebView
	self.webView = [[UIWebView alloc] initWithFrame:appFrame];
	webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	webView.scalesPageToFit = YES;
	webView.delegate = self;
	webView.dataDetectorTypes = UIDataDetectorTypeNone;
	[v addSubview:webView];
	
	self.view = v;
}


/**
 *	Called when the view unloads, let's release all our view-related properties
 */
- (void)viewDidUnload
{
    [super viewDidUnload];
	webView.delegate = nil;
	self.webView = nil;
	self.loadingView = nil;
	self.loaded = NO;
}

/**
 *	Called when memory on the device is low. By default releases the view if it doesn't have a superview.
 */
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}



#pragma mark - View Handling
/**
 *	Called when the view is about to appear. Load the URL if it hasn't yet been loaded
 */
- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// load (or reload if due)
	if (url && !loaded && !webView.loading) {
		[self load];
	}
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	
	if (loadingView) {
		[self hideLoadingIndicator:nil];
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (UIUserInterfaceIdiomPad == UI_USER_INTERFACE_IDIOM()) || (interfaceOrientation == UIInterfaceOrientationPortrait);
}



#pragma mark - URL Loading

/**
 *	The load method only loads if the page has not yet been loaded
 */
- (void)load
{
	if (![self isViewLoaded]) {
		DLog(@"It's too early to call loadURL, the view is not yet loaded!");
		return;
	}
	
	if (url) {
		if (!loaded && !webView.loading) {
			[webView loadRequest:[NSURLRequest requestWithURL:url]];
		}
	}
	else {
		[webView loadHTMLString:@"<h1>Error loading</h1><h2>Got no URL to load</h2>" baseURL:nil];
	}
}

/**
 *	As a difference to load, reload also loads if the page was already loaded
 */
- (void)reload:(id)sender
{
	if (![self isViewLoaded]) {
		DLog(@"It's too early to call reload, the view is not yet loaded!");
		return;
	}
	
	if (url) {
		if (!webView.loading) {
			[webView loadRequest:[NSURLRequest requestWithURL:url]];
		}
	}
	else {
		[webView loadHTMLString:@"<h1>Error reloading</h1><h2>Got no URL to load</h2>" baseURL:nil];
	}
}

/**
 *	This method forces the view to be loaded and then loads the url
 */
- (void)preload:(id)sender
{
	if (![self isViewLoaded]) {
		[self view];
		[self performSelector:@selector(load) withObject:nil afterDelay:0.0];
	}
	else {
		[self load];
	}
}



#pragma mark - UIWebViewDelegate
- (BOOL) webView:(UIWebView *)aWebView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType;
{
	NSURL *loadURL = [request URL];
	loaded = NO;
	
	// show loading indicator if loading from web
	if (![[loadURL scheme] isEqualToString:@"file"]) {
		[self showLoadingIndicator:nil];
	}
	
    return YES;
}

- (void) webViewDidFinishLoad:(UIWebView *)aWebView
{
	[self hideLoadingIndicator:nil];
	loaded = YES;
}

- (void) webView:(UIWebView *)aWebView didFailLoadWithError:(NSError *)error
{
	// don't show cancel message
	if ([[error domain] isEqualToString:NSURLErrorDomain] && NSURLErrorCancelled == [error code]) {
		return;
	}
	
	// show error
	if (loadingView && error) {
		UILabel *warnLabel = [[UILabel alloc] initWithFrame:CGRectInset(loadingView.bounds, 20.f, 20.f)];
		warnLabel.opaque = NO;
		warnLabel.backgroundColor = [UIColor clearColor];
		warnLabel.numberOfLines = 0;
		warnLabel.textColor = [UIColor whiteColor];
		warnLabel.textAlignment = UITextAlignmentCenter;
		warnLabel.font = [UIFont systemFontOfSize:17.f];
		warnLabel.minimumFontSize = 10.f;
		warnLabel.adjustsFontSizeToFitWidth = YES;
		warnLabel.text = [error localizedDescription];
		
		[[loadingView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
		[loadingView addSubview:warnLabel];
		
		// if the original page has never been loaded, allow to try to reload on tap
		if (!loaded) {
			[loadingView removeTarget:self action:@selector(hideLoadingIndicator:) forControlEvents:UIControlEventTouchUpInside];
			[loadingView addTarget:self action:@selector(reload:) forControlEvents:UIControlEventTouchUpInside];
		}
	}
	else {
		DLog(@"Failed loading URL: %@", [error localizedDescription]);
	}
}



#pragma mark - Progress Indicator
- (void) showLoadingIndicator:(id)sender
{
	if (loadingView) {
		[self hideLoadingIndicator:sender];
	}
	
	self.loadingView = [[UIControl alloc] initWithFrame:webView.bounds];
	loadingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	loadingView.opaque = NO;
	loadingView.backgroundColor = [UIColor colorWithWhite:0.f alpha:0.8f];
	[loadingView addTarget:self action:@selector(hideLoadingIndicator:) forControlEvents:UIControlEventTouchUpInside];
	[webView addSubview:loadingView];
	
	UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	CGPoint vCenter = loadingView.center;
	vCenter.y *= 0.9f;
	spinner.center = vCenter;
	
	[loadingView addSubview:spinner];
	[spinner startAnimating];
}

- (void) hideLoadingIndicator:(id)sender
{
	[loadingView removeFromSuperview];
	self.loadingView = nil;
}



#pragma mark - KVC
- (void) setUrl:(NSURL *)newURL
{
	if (newURL != url) {
		url = newURL;
		
		loaded = NO;
		if ([self isViewLoaded]) {
			[self load];
		}
	}
}


@end
