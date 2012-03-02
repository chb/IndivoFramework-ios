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

#import <Foundation/Foundation.h>
#import "Indivo.h"

#define kINURLLoaderDefaultTimeoutInterval 60.0								///< timeout interval in seconds


/**
 *	This class simplifies loading data from a URL
 */
@interface INURLLoader : NSObject

@property (nonatomic, strong) NSURL *url;									///< The URL we will load from
@property (nonatomic, readonly, copy) NSData *responseData;					///< Will contain the response data as loaded from url
@property (nonatomic, readonly, copy) NSString *responseString;				///< Will contain the response as NSString as loaded from url
@property (nonatomic, readonly, assign) NSUInteger responseStatus;			///< The HTTP response status code
@property (nonatomic, assign) BOOL expectBinaryData;						///< NO by default. Set to YES if you expect binary data; "responseString" will be left nil!

+ (NSDictionary *)queryFromRequest:(NSURLRequest *)aRequest;
+ (NSDictionary *)queryFromRequestString:(NSString *)aString;

+ (id)loaderWithURL:(NSURL *)anURL;
- (id)initWithURL:(NSURL *)anURL;

- (void)getWithCallback:(INCancelErrorBlock)callback;
- (void)post:(NSString *)postBody withCallback:(INCancelErrorBlock)callback;
- (void)performRequest:(NSURLRequest *)aRequest withCallback:(INCancelErrorBlock)aCallback;

- (void)cancel;


@end
