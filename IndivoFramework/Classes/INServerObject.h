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

#import "INObject.h"
#import "IndivoServer.h"


/**
 *	INServerObject extends INObject in that it represents an XML document tree "belonging" to a given server.
 */
@interface INServerObject : INObject

@property (nonatomic, assign) IndivoServer *server;									///< Our beloved server
@property (nonatomic, strong) NSString *udid;										///< This object's udid
@property (nonatomic, readonly, assign, getter=isOnServer) BOOL onServer;			///< Indicates whether this document lives on the server

- (id)initFromNode:(INXMLNode *)node withServer:(IndivoServer *)aServer;

// performing server calls
- (void)get:(NSString *)aMethod callback:(INSuccessRetvalueBlock)callback;
- (void)get:(NSString *)aMethod parameters:(NSArray *)paramArray callback:(INSuccessRetvalueBlock)callback;
- (void)put:(NSString *)aMethod body:(NSString *)bodyString callback:(INSuccessRetvalueBlock)callback;
- (void)post:(NSString *)aMethod body:(NSString *)bodyString callback:(INSuccessRetvalueBlock)callback;
- (void)post:(NSString *)aMethod parameters:(NSArray *)paramArray callback:(INSuccessRetvalueBlock)callback;

- (void)performMethod:(NSString *)aMethod withBody:(NSString *)body orParameters:(NSArray *)parameters httpMethod:(NSString *)httpMethod callback:(INSuccessRetvalueBlock)callback;

// Utils
- (BOOL)is:(NSString *)anId;


@end
