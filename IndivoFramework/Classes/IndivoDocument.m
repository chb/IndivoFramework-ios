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
#import <objc/runtime.h>
#import "IndivoMetaDocument.h"
#import "IndivoRecord.h"
#import "NSArray+NilProtection.h"

@interface IndivoDocument ()

@property (nonatomic, readwrite, copy) NSString *label;
@property (nonatomic, readwrite, assign) INDocumentStatus status;
@property (nonatomic, readwrite, assign) BOOL fetched;

+ (NSMutableDictionary *)cacheDictionary;
+ (dispatch_queue_t)cacheQueue;

@end


@implementation IndivoDocument

@synthesize label, status, fetched;


/**
 *	The designated initializer
 */
- (id)initFromNode:(INXMLNode *)aNode forRecord:(IndivoRecord *)aRecord withMeta:(IndivoMetaDocument *)aMetaDocument
{
	if ((self = [super initFromNode:aNode forRecord:(aRecord ? aRecord : aMetaDocument.record)])) {
		if (aMetaDocument) {
			self.udid = aMetaDocument.udid;
			self.type = aMetaDocument.type;
			status = documentStatusFor(aMetaDocument.status.string);
		}
	}
	return self;
}



#pragma mark - Data Server Paths
/**
 *	The base path to get documents of this class
 */
+ (NSString *)fetchReportPathForRecord:(IndivoRecord *)aRecord
{
	return [NSString stringWithFormat:@"/records/%@/reports/minimal/%@/", aRecord.udid, [self reportType]];
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



#pragma mark - Document Properties
/**
 *	This name is used to construct the report path for this kind of document. For example, "IndivoMedication" will return "medications" from
 *	this method, so the path will be "/records/<record-id>/reports/minimal/medications/".
 */
+ (NSString *)reportType
{
	return @"";
}


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
			  body:[self documentXML]
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
			  body:[self documentXML]
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



#pragma mark - Caching Facility
/**
 *	Caches the object for a given type.
 */
- (BOOL)cacheObject:(id)anObject asType:(NSString *)aType error:(__autoreleasing NSError **)error
{
	return [[self class] cacheObject:anObject asType:aType forId:self.udid error:error];
}

/**
 *	Retrieves the object for a given type from cache.
 */
- (id)cachedObjectOfType:(NSString *)aType
{
	return [[self class] cachedObjectOfType:aType forId:self.udid];
}


/**
 *	Stores an object of a given type for the document of the given udid.
 */
+ (BOOL)cacheObject:(id)anObject asType:(NSString *)aType forId:(NSString *)aUdid error:(__autoreleasing NSError **)error
{
	if (!anObject) {
		ERR(error, @"No object given", 21)
		return NO;
	}
	if (!aUdid) {
		ERR(error, @"No id given", 0)
		return NO;
	}
	if (!aType) {
		aType = @"generic";
	}
	
	// get global objects
	NSMutableDictionary *cacheDict = [self cacheDictionary];
	dispatch_queue_t cacheQueue = [self cacheQueue];
	
	// store the object in cache
	dispatch_sync(cacheQueue, ^{
		NSMutableDictionary *typeDictionary = [cacheDict objectForKey:aType];
		if (!typeDictionary) {
			typeDictionary = [NSMutableDictionary dictionaryWithObject:anObject forKey:aUdid];
			[cacheDict setObject:typeDictionary forKey:aType];
		}
		else {
			[typeDictionary setObject:anObject forKey:aUdid];
		}
		
		/// @todo cache to disk
	});
	return YES;
}


/**
 *	Retrieves the cached object of a given type for a given document udid.
 */
+ (id)cachedObjectOfType:(NSString *)aType forId:(NSString *)aUdid
{
	if (!aUdid) {
		return nil;
	}
	if (!aType) {
		aType = @"generic";
	}
	
	// get global objects
	NSMutableDictionary *cacheDict = [self cacheDictionary];
	dispatch_queue_t cacheQueue = [self cacheQueue];
	
	// retrieve the object
	__block id theObject = nil;
	dispatch_sync(cacheQueue, ^{
		theObject = [[cacheDict objectForKey:aType] objectForKey:aUdid];
		
		// not loaded, try to load from disk
		if (!theObject) {
			/// @todo load from disk
		}
	});
	return theObject;
}


+ (NSMutableDictionary *)cacheDictionary
{
	static NSMutableDictionary *cacheDict = nil;
	if (!cacheDict) {
		cacheDict = [[NSMutableDictionary alloc] init];
	}
	return cacheDict;
}


+ (dispatch_queue_t)cacheQueue
{
	static dispatch_queue_t cacheQueue = NULL;
	if (!cacheQueue) {
		cacheQueue = dispatch_queue_create("org.chip.indivo.framework.cachequeue", NULL);
	}
	return cacheQueue;
}


@end
