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


#import <Foundation/Foundation.h>
#import "Indivo.h"
#import "MPOAuthAPI.h"

@class IndivoServer;


/**
 *	Our internal class to handle a call to the server
 */
@interface INServerCall : NSObject <MPOAuthAPIAuthDelegate, MPOAuthAPILoadDelegate>

@property (nonatomic, assign) IndivoServer *server;							///< The server upon which we are called
@property (nonatomic, copy) NSString *method;								///< The method to call on the server URL
@property (nonatomic, copy) NSString *HTTPMethod;							///< Will be GET by default
@property (nonatomic, copy) NSString *body;									///< Body data, takes precedence over "parameters" if length is > 0
@property (nonatomic, strong) NSArray *parameters;							///< An array with @"key=value" strings to be passed to the server, overridden by "body"
@property (nonatomic, strong) MPOAuthAPI *oauth;							///< The call will retain a copy of the oauth instance
@property (nonatomic, assign) BOOL finishIfAuthenticated;					///< If yes the call is merely a proxy to the OAuth authentication call
@property (nonatomic, copy) INSuccessRetvalueBlock myCallback;				///< The callback after finishing our call
@property (nonatomic, readonly, assign) BOOL hasBeenFired;					///< As the name suggests, tells us whether it has been sent on the journey

+ (INServerCall *)newForServer:(IndivoServer *)aServer;
- (id)initWithServer:(IndivoServer *)aServer;

- (void)get:(NSString *)inMethod withParameters:(NSArray *)inParameters oauth:(MPOAuthAPI *)inOAuth callback:(INSuccessRetvalueBlock)inCallback;
- (void)post:(NSString *)inMethod withParameters:(NSArray *)inParameters oauth:(MPOAuthAPI *)inOAuth callback:(INSuccessRetvalueBlock)inCallback;
- (void)post:(NSString *)inMethod body:(NSString *)dataString oauth:(MPOAuthAPI *)inOAuth callback:(INSuccessRetvalueBlock)inCallback;
- (void)fire:(NSString *)inMethod withParameters:(NSArray *)inParameters httpMethod:(NSString *)httpMethod oauth:(MPOAuthAPI *)inOAuth callback:(INSuccessRetvalueBlock)inCallback;
- (void)fire;

- (void)finishWith:(NSDictionary *)returnObject;
- (void)abortWithError:(NSError *)error;


@end
