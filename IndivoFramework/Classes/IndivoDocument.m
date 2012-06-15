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
@property (nonatomic, readwrite, assign) INDocumentStatus documentStatus;
@property (nonatomic, readwrite, assign) BOOL fetched;

@property (nonatomic, readwrite, strong) IndivoPrincipal *creator;
@property (nonatomic, readwrite, copy) NSString *uuidLatest;
@property (nonatomic, readwrite, copy) NSString *uuidOriginal;
@property (nonatomic, readwrite, copy) NSString *uuidReplaces;

+ (NSMutableDictionary *)cacheDictionary;
+ (dispatch_queue_t)cacheQueue;

@end


@implementation IndivoDocument

@synthesize label, documentStatus, fetched;
@synthesize creator, uuidLatest, uuidReplaces, uuidOriginal;


/**
 *	The designated initializer
 */
- (id)initFromNode:(INXMLNode *)aNode forRecord:(IndivoRecord *)aRecord withMeta:(IndivoMetaDocument *)aMetaDocument
{
	if ((self = [super initFromNode:aNode forRecord:(aRecord ? aRecord : aMetaDocument.record)])) {
		[self updateWithMeta:aMetaDocument];
	}
	return self;
}



#pragma mark - Data Server Paths
/**
 *	The base path to get reports for documents of this class
 */
+ (NSString *)fetchReportPathForRecord:(IndivoRecord *)aRecord
{
	NSString *reportType = [self reportType];
	if (reportType && aRecord.uuid) {
		return [NSString stringWithFormat:@"/records/%@/reports/%@/", aRecord.uuid, reportType];
	}
	return nil;
}

/**
 *	The path to this document, i.e. the path I can GET to receive this document instance
 */
- (NSString *)documentPath
{
	if (self.record.uuid && self.uuid) {
		return [NSString stringWithFormat:@"/records/%@/documents/%@", self.record.uuid, self.uuid];
	}
	return nil;
}

/**
 *	The base path, e.g. "/records/{record id}/documents/" for documents.
 *	POSTing XML to this path should result in creation of a new object of this class (given it doesn't fail on the server)
 */
- (NSString *)basePostPath
{
	if (self.record.uuid) {
		return [NSString stringWithFormat:@"/records/%@/documents/", self.record.uuid];
	}
	return nil;
}



#pragma mark - Document Properties
/**
 *	This name is used to construct the report path for this kind of document. For example, "IndivoMedication" will return "medications" from
 *	this method, so the path will be "/records/<record-id>/medications/".
 */
+ (NSString *)reportType
{
	return nil;
}


/**
 *	@returns YES if the receiver's status matches the supplied status, which can be an OR-ed list of status
 */
- (BOOL)hasStatus:(INDocumentStatus)aStatus
{
	return (self.documentStatus & aStatus);
}


/**
 *	@returns YES if this document has not (yet) been replaced by a newer version
 */
- (BOOL)isLatest
{
	return (nil == self.uuidLatest || [self.uuidLatest isEqualToString:self.uuid]);
}


/**
 *	Fetch the document's version history.
 *	Upon success, the userInfo dictionary will contain an array of IndivoMetaDocument objects for the INResponesArrayKey key.
 *	@param callback An INCancelErrorBlock callback
 */
- (void)fetchVersionsWithCallback:(INSuccessRetvalueBlock)callback
{
	NSString *path = [self.documentPath stringByAppendingString:@"/versions/"];		// cannot use path component method as this strips the trailing shlash
	if (!path) {
		SUCCESS_RETVAL_CALLBACK_OR_LOG_ERR_STRING(callback, @"Can't fetch document version history because we're missing the document- or record-id", 0)
		return;
	}
	
	[self get:path
	 callback:^(BOOL success, NSDictionary *__autoreleasing userInfo) {
		 NSDictionary *usrIfo = nil;
		 
		 // fetched successfully...
		 if (success) {
			 INXMLNode *documentsNode = [userInfo objectForKey:INResponseXMLKey];
			 NSArray *docs = [documentsNode childrenNamed:@"Document"];
			 
			 // create documents
			 if ([docs count] > 0) {
				 NSMutableArray *metaArr = [NSMutableArray arrayWithCapacity:[docs count]];
				 for (INXMLNode *document in docs) {
					 IndivoMetaDocument *meta = [[IndivoMetaDocument alloc] initFromNode:document forRecord:self.record];
					 if (meta) {
						 [metaArr addObject:meta];
					 }
				 }
				 
				 usrIfo = [NSDictionary dictionaryWithObject:metaArr forKey:INResponseArrayKey];
			 }
		 }
		 else {
			 usrIfo = userInfo;
		 }
		 
		 SUCCESS_RETVAL_CALLBACK_OR_LOG_USER_INFO(callback, success, usrIfo);
	 }];
}


/**
 *	Fetch the document's version history.
 *	Upon success, the userInfo dictionary will contain an array of INDocumentStatusNode objects for the INResponesArrayKey key.
 *	@param callback An INCancelErrorBlock callback
 */
- (void)fetchStatusHistoryWithCallback:(INSuccessRetvalueBlock)callback
{
	if (!self.onServer) {
		SUCCESS_RETVAL_CALLBACK_OR_LOG_ERR_STRING(callback, @"This document is not yet on the server and does not have a meta document", 0)
		return;
	}
	
	NSString *path = [self.documentPath stringByAppendingPathComponent:@"status-history"];
	if (!path) {
		SUCCESS_RETVAL_CALLBACK_OR_LOG_ERR_STRING(callback, @"Can't fetch status history because we're missing the document- or record-id", 0)
		return;
	}
	
	[self get:path
	 callback:^(BOOL success, NSDictionary *__autoreleasing userInfo) {
		 NSDictionary *usrIfo = nil;
		 
		 // fetched successfully...
		 if (success) {
			 INXMLNode *parentNode = [userInfo objectForKey:INResponseXMLKey];
			 if (![[parentNode attr:@"document_id"] isEqualToString:self.uuid]) {
				 SUCCESS_RETVAL_CALLBACK_OR_LOG_ERR_STRING(callback, @"Document id from history does not match our own id", 22)
				 return;
			 }
			 NSArray *statusNodes = [parentNode childrenNamed:@"DocumentStatus"];
			 
			 // create documents
			 NSMutableArray *nodeArr = [NSMutableArray arrayWithCapacity:[statusNodes count]];
			 for (INXMLNode *node in statusNodes) {
				 INDocumentStatusNode *stat = [[INDocumentStatusNode alloc] initFromNode:node];
				 if (stat) {
					 [nodeArr addObject:stat];
				 }
			 }
			 
			 usrIfo = [NSDictionary dictionaryWithObject:nodeArr forKey:INResponseArrayKey];
		 }
		 else {
			 usrIfo = userInfo;
		 }
		 
		 SUCCESS_RETVAL_CALLBACK_OR_LOG_USER_INFO(callback, success, usrIfo);
	 }];
}

/**
 *	Fetches the meta document for this document
 */
- (void)fetchMetaDocumentWithCallback:(INSuccessRetvalueBlock)callback
{
	if (!self.onServer) {
		SUCCESS_RETVAL_CALLBACK_OR_LOG_ERR_STRING(callback, @"This document is not yet on the server and does not have a meta document", 0)
		return;
	}
	
	NSString *path = [self.documentPath stringByAppendingPathComponent:@"meta"];
	if (!path) {
		SUCCESS_RETVAL_CALLBACK_OR_LOG_ERR_STRING(callback, @"Can't fetch meta document because we're missing the document- or record-id", 0)
		return;
	}
	
	// get
	[self get:path
	 callback:^(BOOL success, NSDictionary *__autoreleasing userInfo) {
		 if (success) {
			 INXMLNode *xmlNode = [userInfo objectForKey:INResponseXMLKey];
			 IndivoMetaDocument *meta = nil;
			 if (self.record) {
				 meta = [[IndivoMetaDocument alloc] initFromNode:xmlNode forRecord:self.record];
			 }
			 else {
				 meta = [[IndivoMetaDocument alloc] initFromNode:xmlNode withServer:self.server];
			 }
			
			if (meta) {
				userInfo = [NSDictionary dictionaryWithObject:meta forKey:INResponseDocumentKey];
			}
		}
		
		SUCCESS_RETVAL_CALLBACK_OR_LOG_USER_INFO(callback, success, userInfo)
		}];
}



#pragma mark - Getting documents
- (void)pull:(INCancelErrorBlock)callback
{
	NSString *path = self.documentPath;
	if (!path) {
		SUCCESS_RETVAL_CALLBACK_OR_LOG_ERR_STRING(callback, @"Can't pull document because we're missing the document- or record-id", 0)
		return;
	}
	
	[self get:path
	 callback:^(BOOL success, NSDictionary *userInfo) {
		 BOOL didCancel = NO;
		 if (success) {
			 INXMLNode *xmlNode = [userInfo objectForKey:INResponseXMLKey];
			 if (![xmlNode attr:@"id"] || [[xmlNode attr:@"id"] isEqualToString:self.uuid]) {
				 [self setFromNode:xmlNode];
				 [self markOnServer];
				 self.fetched = YES;
			 }
			 else {
				 DLog(@"Not good, have udid %@ but fetched %@ from node %@", self.uuid, [xmlNode attr:@"id"], xmlNode);
			 }
		 }
		 else {
			 if (![userInfo objectForKey:INErrorKey]) {
				 didCancel = YES;
			 }
		 }
		 
		 CANCEL_ERROR_CALLBACK_OR_LOG_USER_INFO(callback, didCancel, userInfo)
	 }];
}



#pragma mark - Document Actions
/**
 *	This method puts a new document on the server.
 *	@attention If you have assigned a udid yourself already, this udid will change.
 *	Use "replace:" to update a modified document on the server.
 */
- (void)push:(INCancelErrorBlock)callback
{
	NSString *path = [self basePostPath];
	if (!path) {
		SUCCESS_RETVAL_CALLBACK_OR_LOG_ERR_STRING(callback, @"Can't push document because we're missing the record-id", 0)
		return;
	}
	
	if (!self.onServer) {
		NSString *xml = [self documentXML];
		//DLog(@"Pushing XML:  %@", xml);
		
		[self post:path
			  body:xml
		  callback:^(BOOL success, NSDictionary *userInfo) {
			  if (success) {
				  
				  // success, mark it as on-server and parse the returned meta to extract the udidi
				  [self markOnServer];
				  INXMLNode *meta = [userInfo objectForKey:INResponseXMLKey];
				  if (meta) {
					  IndivoMetaDocument *metaDoc = [IndivoMetaDocument objectFromNode:meta];
					  [self updateWithMeta:metaDoc];
				  }
				  
				  CANCEL_ERROR_CALLBACK_OR_LOG_USER_INFO(callback, NO, userInfo)
				  POST_DOCUMENTS_DID_CHANGE_FOR_RECORD_NOTIFICATION(self.record)
			  }
			  else {
				  BOOL didCancel = NO;
				  if (![userInfo objectForKey:INErrorKey]) {
					  didCancel = YES;
				  }
				  else {
					  // we log the XML if push fails because most likely, it didn't validate, so here's your chance to take a look
					  DLog(@"PUSH FAILED BECAUSE %@:\n%@", [[userInfo objectForKey:INErrorKey] localizedDescription], xml);
				  }
				  CANCEL_ERROR_CALLBACK_OR_LOG_USER_INFO(callback, didCancel, userInfo)
			  }
		  }];
		return;
	}
	
	CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(callback, NO, @"This document was fetched from the server already, so it cannot be pushed. Use \"replace:\" instead.")
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
		if (!updatePath) {
			SUCCESS_RETVAL_CALLBACK_OR_LOG_ERR_STRING(callback, @"Can't replace document because we're missing the document- or record-id", 0)
			return;
		}
		
		NSString *xml = [self documentXML];
		[self post:updatePath
			  body:xml
		  callback:^(BOOL success, NSDictionary *userInfo) {
			  if (success) {
				  
				  // success, update values from meta
				  INXMLNode *meta = [userInfo objectForKey:INResponseXMLKey];
				  if (meta) {
					  IndivoMetaDocument *metaDoc = [IndivoMetaDocument objectFromNode:meta];
					  [self updateWithMeta:metaDoc];
				  }
				  
				  CANCEL_ERROR_CALLBACK_OR_LOG_USER_INFO(callback, NO, userInfo)
				  POST_DOCUMENTS_DID_CHANGE_FOR_RECORD_NOTIFICATION(self.record)
			  }
			  else {
				  BOOL didCancel = NO;
				  if (![userInfo objectForKey:INErrorKey]) {
					  didCancel = YES;
				  }
				  else {
					  DLog(@"FAILED: %@", xml);
				  }
				  CANCEL_ERROR_CALLBACK_OR_LOG_USER_INFO(callback, didCancel, userInfo)
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
	if (!labelPath) {
		SUCCESS_RETVAL_CALLBACK_OR_LOG_ERR_STRING(callback, @"Can't set label because we're missing the document- or record-id", 0)
		return;
	}
	
	[self put:labelPath body:aLabel callback:^(BOOL success, NSDictionary *__autoreleasing userInfo) {
		if (success) {
			self.label = aLabel;
			CANCEL_ERROR_CALLBACK_OR_LOG_USER_INFO(callback, NO, userInfo)
			POST_DOCUMENTS_DID_CHANGE_FOR_RECORD_NOTIFICATION(self.record)
		}
		else {
			BOOL didCancel = (![userInfo objectForKey:INErrorKey]);
			CANCEL_ERROR_CALLBACK_OR_LOG_USER_INFO(callback, didCancel, userInfo)
		}
	}];
}

/**
 *	Void (or unvoid) a document for a given reason.
 *	@param flag YES to void, NO to re-activate
 *	@param aReason The reason for the status change, should not be nil if you want the call to succeed
 *	@param callback An INCancelErrorBlock callback
 */
- (void)void:(BOOL)flag forReason:(NSString *)aReason callback:(INCancelErrorBlock)callback
{
	NSString *statusPath = [self.documentPath stringByAppendingPathComponent:@"set-status"];
	if (!statusPath) {
		SUCCESS_RETVAL_CALLBACK_OR_LOG_ERR_STRING(callback, @"Can't flag document because we're missing the document- or record-id", 0)
		return;
	}
	
	NSArray *params = [NSArray arrayWithObjects:
					   [NSString stringWithFormat:@"status=%@", (flag ? @"void" : @"active")],
					   [NSString stringWithFormat:@"reason=%@", ([aReason length] > 0) ? aReason : @""],
					   nil];
	
	[self post:statusPath parameters:params callback:^(BOOL success, NSDictionary *__autoreleasing userInfo) {
		if (success) {
			self.documentStatus = flag ? INDocumentStatusVoid : INDocumentStatusActive;
			CANCEL_ERROR_CALLBACK_OR_LOG_USER_INFO(callback, NO, userInfo)
			POST_DOCUMENTS_DID_CHANGE_FOR_RECORD_NOTIFICATION(self.record)
		}
		else {
			BOOL didCancel = (![userInfo objectForKey:INErrorKey]);
			CANCEL_ERROR_CALLBACK_OR_LOG_USER_INFO(callback, didCancel, userInfo)
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
	if (!statusPath) {
		SUCCESS_RETVAL_CALLBACK_OR_LOG_ERR_STRING(callback, @"Can't archive document because we're missing the document- or record-id", 0)
		return;
	}
	
	NSArray *params = [NSArray arrayWithObjects:
					   [NSString stringWithFormat:@"status=%@", (flag ? @"archived" : @"active")],
					   [NSString stringWithFormat:@"reason=%@", ([aReason length] > 0) ? aReason : @""],
					   nil];
	
	[self post:statusPath parameters:params callback:^(BOOL success, NSDictionary *__autoreleasing userInfo) {
		if (success) {
			self.documentStatus = flag ? INDocumentStatusArchived : INDocumentStatusActive;
			CANCEL_ERROR_CALLBACK_OR_LOG_USER_INFO(callback, NO, userInfo)
			POST_DOCUMENTS_DID_CHANGE_FOR_RECORD_NOTIFICATION(self.record)
		}
		else {
			BOOL didCancel = (![userInfo objectForKey:INErrorKey]);
			CANCEL_ERROR_CALLBACK_OR_LOG_USER_INFO(callback, didCancel, userInfo)
		}
	}];
}



#pragma mark - Meta Document Handling
/**
 *	This method updates our udid, type and status from the given meta document
 *	@todo There is more information in the meta doc, either store the whole meta doc or store the data in the instance.
 */
- (void)updateWithMeta:(IndivoMetaDocument *)aMetaDoc
{
	if (aMetaDoc.uuid) {
		self.uuid = aMetaDoc.uuid;		// the meta doc is always right!
	}
	if (aMetaDoc.status) {
		documentStatus = documentStatusFor(aMetaDoc.status.string);
	}
	
	if (aMetaDoc.creator) {
		self.creator = aMetaDoc.creator;
	}
	
	if (aMetaDoc.original) {
		self.uuidOriginal = [aMetaDoc.original attr:@"id"];
	}
	if (aMetaDoc.replaces) {
		self.uuidReplaces = [aMetaDoc.replaces attr:@"id"];
	}
	if (aMetaDoc.latest) {
		self.uuidLatest = [aMetaDoc.latest attr:@"id"];
	}
}



#pragma mark - Class Registration
static NSMutableArray *registeredClasses = nil;
static NSDictionary *registeredClassHash = nil;

/**
 *	Returns the class for a previously registered type, or "IndivoDocument" if the type has not been registered
 */
+ (Class)documentClassForType:(NSString *)aType
{
	// convert the array to a hash the first time we're called
	if (!registeredClassHash) {
		if (!registeredClasses) {
			DLog(@"WARNING: No classes have registered");
			return self;
		}
		NSMutableDictionary *tempDict = [NSMutableDictionary dictionaryWithCapacity:[registeredClasses count]];
		for (Class aClass in registeredClasses) {
			NSString *type = [[aClass nodeType] stringByReplacingOccurrencesOfString:@"indivo:" withString:@""];
			if (type) {
				[tempDict setObject:aClass forKey:type];
			}
		}
		registeredClassHash = tempDict;
		registeredClasses = nil;
	}
	
	// search
	Class foundClass = [registeredClassHash objectForKey:aType];
	if (foundClass) {
		return foundClass;
	}
	
	return self;
}

/**
 *	Our IndivoDocument subclasses call this in their +load method.
 *	Since we are auto-generating the classes from a template, this method is potentially also called by non-IndivoDocument-subclasses, which is
 *	why we check for subclass status here instead.
 */
+ (void)registerDocumentClass:(Class)aClass
{
	if ([aClass isSubclassOfClass:self]) {
		if (!registeredClasses) {
			registeredClasses = [[NSMutableArray alloc] init];
		}
		
		[registeredClasses addObject:aClass];
	}
}



#pragma mark - Caching Facility
/**
 *	Caches the object for a given type.
 */
- (BOOL)cacheObject:(id)anObject asType:(NSString *)aType error:(__autoreleasing NSError **)error
{
	return [[self class] cacheObject:anObject asType:aType forId:self.uuid error:error];
}

/**
 *	Retrieves the object for a given type from cache.
 */
- (id)cachedObjectOfType:(NSString *)aType
{
	return [[self class] cachedObjectOfType:aType forId:self.uuid];
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
	
	// get the queue
	dispatch_queue_t cacheQueue = [self cacheQueue];
	
	// store the object in cache
	dispatch_sync(cacheQueue, ^{
		NSMutableDictionary *cacheDict = [self cacheDictionary];
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
	
	// get the queue
	dispatch_queue_t cacheQueue = [self cacheQueue];
	
	// retrieve the object
	__block id theObject = nil;
	dispatch_sync(cacheQueue, ^{
		NSMutableDictionary *cacheDict = [self cacheDictionary];
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
