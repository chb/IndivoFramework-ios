/*
 IndivoDocument.m
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

#import "IndivoDocument.h"
#import "IndivoMetaDocument.h"
#import "IndivoRecord.h"

@interface IndivoDocument ()

@property (nonatomic, readwrite, copy) NSString *label;
@property (nonatomic, readwrite, assign) INDocumentStatus status;
@property (nonatomic, readwrite, assign) BOOL fetched;

@end


@implementation IndivoDocument

@synthesize label, status, fetched;


/**
 *	The designated initializer
 */
- (id)initFromNode:(INXMLNode *)aNode forRecord:(IndivoRecord *)aRecord withMeta:(IndivoMetaDocument *)aMetaDocument
{
	if ((self = [super initFromNode:aNode forRecord:(aRecord ? aRecord : aMetaDocument.record)])) {
		self.udid = aMetaDocument.udid;
		self.type = aMetaDocument.type;
		status = documentStatusFor(aMetaDocument.status.string);
	}
	return self;
}



#pragma mark - Data Server Paths
/**
 *	The base path to get documents of this class
 */
+ (NSString *)fetchReportPathForRecord:(IndivoRecord *)aRecord
{
	return [NSString stringWithFormat:@"/records/%@/documents/types/%@/", aRecord.udid, [self type]];
}

/**
 *	The path to this document, i.e. the path I can GET and receive this document instance
 */
- (NSString *)documentPath
{
	return [NSString stringWithFormat:@"/records/%@/documents/%@", self.record.udid, self.udid];
}

/**
 *	The base path, e.g. "/records/{record id}/documents/" for documents.
 *	POSTing XML to this path should result in creation of a new object of this class (given it doesn't fail on the server)
 */
- (NSString *)basePostPath
{
	return [NSString stringWithFormat:@"/records/%@/documents/", self.record.udid];
}



#pragma mark - Document Status
/**
 *	Returns YES if the receiver's status matches the supplied status, which can be an OR-ed list of status
 */
- (BOOL)hasStatus:(INDocumentStatus)aStatus
{
	return (self.status & aStatus);
}



#pragma mark - Getting documents
- (void)pull:(INCancelErrorBlock)callback
{
	__unsafe_unretained IndivoDocument *this = self;
	[self get:[self documentPath]
	 callback:^(BOOL success, NSDictionary *userInfo) {
		 if (success) {
			 INXMLNode *xmlNode = [userInfo objectForKey:INResponseXMLKey];
			 if ([[xmlNode attr:@"id"] isEqualToString:this.udid]) {
				 [this setFromNode:xmlNode];
				 this.fetched = YES;
			 }
			 else {
				 DLog(@"Not good, have udid %@ but fetched %@", this.udid, [xmlNode attr:@"id"]);
			 }
			 if (callback) {
				 callback(NO, nil);
			 }
		 }
		 else {
			 CANCEL_ERROR_CALLBACK_OR_LOG_USER_INFO(callback, userInfo)
		 }
	 }];
}



#pragma mark - Updating documents
/**
 *	This method puts a new document on the server.
 *	@attention If you have assigned a udid yourself already, this udid will change.
 *	Use "replace:" to update a modified document on the server.
 */
- (void)push:(INCancelErrorBlock)callback
{
	if (!self.onServer) {
		[self post:[self basePostPath]
			  body:[self xml]
		  callback:^(BOOL success, NSDictionary *userInfo) {
			  if (success) {
				  if (callback) {
					  callback(NO, nil);
				  }
				  DOCUMENTS_DID_CHANGE_FOR_RECORD_NOTIFICATION(self.record)
			  }
			  else {
				  CANCEL_ERROR_CALLBACK_OR_LOG_USER_INFO(callback, userInfo)
			  }
		  }];
	}
	else if (callback) {
		callback(NO, @"This document was fetched from the server already, so it cannot be pushed. Use \"replace:\" instead.");
	}
}

/**
 *	This method updates the receiver's version on the server with new data from the receiver's properties. If the document does not yet exist,
 *	this method automatically calls "push:" to create the document.
 */
- (void)replace:(INCancelErrorBlock)callback
{
	if (!self.onServer) {
		[self push:callback];
	}
	else {
		NSString *updatePath = [self.documentPath stringByAppendingPathComponent:@"replace"];
		__block IndivoDocument *this = self;
		[self post:updatePath
			  body:[self xml]
		  callback:^(BOOL success, NSDictionary *userInfo) {
			  if (success) {
				  this.status = INDocumentStatusArchived;
				  if (callback) {
					  callback(NO, nil);
				  }
				  DOCUMENTS_DID_CHANGE_FOR_RECORD_NOTIFICATION(this.record)
			  }
			  else {
				  CANCEL_ERROR_CALLBACK_OR_LOG_USER_INFO(callback, userInfo)
			  }
		  }];
	}
}

/**
 *	Label a document
 */
- (void)setLabel:(NSString *)aLabel callback:(INCancelErrorBlock)callback
{
	NSString *labelPath = [self.documentPath stringByAppendingPathComponent:@"label"];
	[self put:labelPath body:aLabel callback:^(BOOL success, NSDictionary *__autoreleasing userInfo) {
		if (success) {
			self.label = aLabel;
			if (callback) {
				callback(NO, nil);
			}
			DOCUMENTS_DID_CHANGE_FOR_RECORD_NOTIFICATION(self.record)
		}
		else {
			CANCEL_ERROR_CALLBACK_OR_LOG_USER_INFO(callback, userInfo)
		}
	}];
}

/**
 *	Void (or unvoid) a document for a given reason
 */
- (void)void:(BOOL)flag forReason:(NSString *)aReason callback:(INCancelErrorBlock)callback
{
	NSString *statusPath = [self.documentPath stringByAppendingPathComponent:@"set-status"];
	NSArray *params = [NSArray arrayWithObjects:
					   [NSString stringWithFormat:@"status=%@", (flag ? @"void" : @"active")],
					   [NSString stringWithFormat:@"reason=%@", ([aReason length] > 0) ? aReason : @""],
					   nil];
	
	[self post:statusPath parameters:params callback:^(BOOL success, NSDictionary *__autoreleasing userInfo) {
		if (success) {
			self.status = flag ? INDocumentStatusVoid : INDocumentStatusActive;
			if (callback) {
				callback(NO, nil);
			}
			DOCUMENTS_DID_CHANGE_FOR_RECORD_NOTIFICATION(self.record)
		}
		else {
			CANCEL_ERROR_CALLBACK_OR_LOG_USER_INFO(callback, userInfo)
		}
	}];
}

/**
 *	Archive (or unarchive) a document for the given reason. You must supply a reason, Indivo server will issue a 400 if there
 *	is no reason
 *	@param flag YES to archive, NO to re-activate
 *	@param aReason The reason for the status change, should not be nil if you want the call to succeed
 *	@param callback An INCancelErrorBlock callback
 */
- (void)archive:(BOOL)flag forReason:(NSString *)aReason callback:(INCancelErrorBlock)callback
{
	NSString *statusPath = [self.documentPath stringByAppendingPathComponent:@"set-status"];
	NSArray *params = [NSArray arrayWithObjects:
					   [NSString stringWithFormat:@"status=%@", (flag ? @"archived" : @"active")],
					   [NSString stringWithFormat:@"reason=%@", ([aReason length] > 0) ? aReason : @""],
					   nil];
	
	[self post:statusPath parameters:params callback:^(BOOL success, NSDictionary *__autoreleasing userInfo) {
		if (success) {
			self.status = flag ? INDocumentStatusArchived : INDocumentStatusActive;
			if (callback) {
				callback(NO, nil);
			}
			DOCUMENTS_DID_CHANGE_FOR_RECORD_NOTIFICATION(self.record)
		}
		else {
			CANCEL_ERROR_CALLBACK_OR_LOG_USER_INFO(callback, userInfo)
		}
	}];
}


@end
