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

#import "INServerObject.h"

@class IndivoDocument;
@class IndivoContact;
@class IndivoDemographics;
@class INXMLNode;


@interface IndivoRecord : INServerObject

@property (nonatomic, copy) NSString *label;										///< This record's name
@property (nonatomic, readonly, assign) BOOL hasContactDoc;							///< YES if this record has a contact document that can be fetched
@property (nonatomic, readonly, strong) IndivoContact *contactDoc;					///< The contact document for this record
@property (nonatomic, readonly, assign) BOOL hasDemographicsDoc;					///< YES if this record has a demographics document that can be fetched
@property (nonatomic, readonly, strong) IndivoDemographics *demographicsDoc;		///< The contact document for this record
@property (nonatomic, readonly, strong) NSDate *created;							///< When this record has been created on the server

@property (nonatomic, copy) NSString *accessToken;									///< The last access token successfully used with this record
@property (nonatomic, copy) NSString *accessTokenSecret;							///< The last access token secret successfully used with this record

- (id)initWithId:(NSString *)anId name:(NSString *)aName onServer:(IndivoServer *)aServer;

// record info
- (void)fetchRecordInfoWithCallback:(INCancelErrorBlock)aCallback;
- (void)fetchContactDocumentWithCallback:(INCancelErrorBlock)aCallback;
- (void)fetchDemographicsDocumentWithCallback:(INCancelErrorBlock)aCallback;

// record reports
- (void)fetchReportsOfClass:(Class)documentClass withStatus:(INDocumentStatus)aStatus callback:(INSuccessRetvalueBlock)callback;
- (void)fetchAllReportsOfClass:(Class)documentClass callback:(INSuccessRetvalueBlock)callback;

// record documens
- (IndivoDocument *)addDocumentOfClass:(Class)documentClass error:(NSError * __autoreleasing *)error;

// messaging
- (void)sendMessage:(NSString *)messageSubject
		   withBody:(NSString *)messageBody
			 ofType:(INMessageType)type
		   severity:(INMessageSeverity)severity
		attachments:(NSArray *)attachments
		   callback:(INCancelErrorBlock)callback;
- (void)sendMessage:(NSString *)messageSubject
		   withBody:(NSString *)messageBody
			 ofType:(INMessageType)type
		   severity:(INMessageSeverity)severity
		attachments:(NSArray *)attachments
		  messageId:(NSString *)messageId										///< Allows to specify a custom message id, if needed
		   callback:(INCancelErrorBlock)callback;

@end
