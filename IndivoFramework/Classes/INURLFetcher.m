/*
 INURLFetcher.h
 IndivoFramework
 
 Created by Pascal Pfiffner on 11/07/11.
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

#import "INURLFetcher.h"
#import "INURLLoader.h"


@interface INURLFetcher ()

@property (nonatomic, readwrite, copy) NSArray *successfulLoads;
@property (nonatomic, readwrite, copy) NSArray *failedLoads;
@property (nonatomic, strong) NSMutableArray *mySuccessfulLoads;
@property (nonatomic, strong) NSMutableArray *myFailedLoads;
@property (nonatomic, strong) NSMutableArray *queuedLoaders;
@property (nonatomic, strong) INURLLoader *currentLoader;
@property (nonatomic, copy) INCancelErrorBlock callback;

- (void)loaderDidFinish:(INURLLoader *)aLoader withErrorMessage:(NSString *)errorMessage;
- (void)didCancel;

@end


@implementation INURLFetcher

@synthesize successfulLoads, failedLoads;
@synthesize mySuccessfulLoads, myFailedLoads, queuedLoaders, currentLoader, callback;


/**
 *	Fetches all URLs sequentially and calls callback when finished.
 *	If one ...
 *	@param anURLArray An NSArray full of NSURL instances
 */
- (void)getURLs:(NSArray *)anURLArray callback:(INCancelErrorBlock)aCallback
{
	if (queuedLoaders) {
		CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(aCallback, NO, @"A queue is already being loaded, cannot begin a new one")
		return;
	}
	
	self.queuedLoaders = nil;
	self.successfulLoads = nil;
	self.failedLoads = nil;
	if ([anURLArray count] > 0) {
		self.callback = aCallback;
		self.queuedLoaders = [NSMutableArray arrayWithCapacity:[anURLArray count] - 1];
		self.currentLoader = [[INURLLoader alloc] initWithURL:[anURLArray objectAtIndex:0]];
		
		// create loaders for each URL
		BOOL first = YES;
		for (NSURL *url in anURLArray) {
			if (!first) {
				INURLLoader *loader = [[INURLLoader alloc] initWithURL:url];
				[queuedLoaders addObject:loader];
			}
			else {
				first = NO;
			}
		}
		
		// prepare and launch the first one!
		self.mySuccessfulLoads = [NSMutableArray arrayWithCapacity:[anURLArray count]];
		self.myFailedLoads = [NSMutableArray arrayWithCapacity:[anURLArray count]];
		
		__block INURLFetcher *this = self;
		[currentLoader getWithCallback:^(BOOL userDidCancel, NSString *__autoreleasing errorMessage) {
			if (userDidCancel) {
				[self didCancel];
			}
			else {
				[this loaderDidFinish:currentLoader withErrorMessage:errorMessage];
			}
		}];
	}
}

/**
 *	Callback when a loader finished
 */
- (void)loaderDidFinish:(INURLLoader *)aLoader withErrorMessage:(NSString *)errorMessage
{
	// load succeeded
	if (!errorMessage && aLoader.responseStatus < 400) {
		[mySuccessfulLoads addObject:aLoader];
	}
	
	// a failed one, poor guy
	else {
		[myFailedLoads addObject:aLoader];
	}
	
	// continue
	[queuedLoaders removeObject:aLoader];
	if ([queuedLoaders count] > 0) {
		self.currentLoader = [queuedLoaders objectAtIndex:0];
		
		__block INURLFetcher *this = self;
		[currentLoader getWithCallback:^(BOOL userDidCancel, NSString *__autoreleasing errorMessage) {
			if (userDidCancel) {
				[self didCancel];
			}
			else {
				[this loaderDidFinish:currentLoader withErrorMessage:errorMessage];
			}
		}];
	}
	
	// finished!
	else {
		if (callback) {
			self.successfulLoads = mySuccessfulLoads;
			self.failedLoads = myFailedLoads;
			self.mySuccessfulLoads = nil;
			self.myFailedLoads = nil;
			callback(NO, ([myFailedLoads count] > 0) ? @"Some loaders failed to load" : nil);
			self.callback = nil;
		}
		self.currentLoader = nil;
	}
}


/**
 *	Abort loading
 */
- (void)cancel
{
	[self.currentLoader cancel];
}

/**
 *	Loading was cancelled
 */
- (void)didCancel
{
	if (callback) {
		self.mySuccessfulLoads = nil;
		self.myFailedLoads = nil;
		callback(YES, nil);
		self.callback = nil;
	}
	self.currentLoader = nil;
}


/**
 *	Returns YES if the queue is empty, which is true before loading has begun and after it has completed
 */
- (BOOL)isIdle
{
	return ([queuedLoaders count] < 1);
}


@end
