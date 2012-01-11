/*
 IndivoRecord.h
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

#import <Foundation/Foundation.h>
#import "INServerObject.h"

@class IndivoDocument;
@class INXMLNode;


@interface IndivoRecord : INServerObject

@property (nonatomic, copy) NSString *label;							///< This record's name
@property (nonatomic, copy) NSString *accessToken;						///< The last access token successfully used with this record
@property (nonatomic, copy) NSString *accessTokenSecret;				///< The last access token secret successfully used with this record

- (id)initWithId:(NSString *)anId name:(NSString *)aName onServer:(IndivoServer *)aServer;

- (void)fetchReportsOfClass:(Class)documentClass callback:(INSuccessRetvalueBlock)callback;
- (void)fetchReportsOfClass:(Class)documentClass withStatus:(INDocumentStatus)aStatus callback:(INSuccessRetvalueBlock)callback;
- (void)fetchAllReportsOfClass:(Class)documentClass callback:(INSuccessRetvalueBlock)callback;

- (IndivoDocument *)addDocumentOfClass:(Class)documentClass error:(NSError * __autoreleasing *)error;


@end
