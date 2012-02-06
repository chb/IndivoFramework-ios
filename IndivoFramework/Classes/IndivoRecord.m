/*
 IndivoRecord.m
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

#import "IndivoRecord.h"
#import "IndivoDocuments.h"
#import "INXMLParser.h"
#import "INXMLReport.h"


@interface IndivoRecord ()

@property (nonatomic, readwrite, assign) BOOL hasContactDoc;
@property (nonatomic, readwrite, strong) IndivoContact *contactDoc;
@property (nonatomic, readwrite, assign) BOOL hasDemographicsDoc;
@property (nonatomic, readwrite, strong) NSDate *created;

@property (nonatomic, strong) NSMutableArray *metaDocuments;					///< Storage for this records fetched document metadata
@property (nonatomic, strong) NSMutableArray *documents;						///< Storage for this records fetched documents: Does NOT automatically contain all documents

@end


@implementation IndivoRecord

@synthesize label, hasContactDoc, contactDoc, hasDemographicsDoc, created;
@synthesize accessToken, accessTokenSecret;
@synthesize metaDocuments, documents;


/**
 *	Initializes a record instance from values found in the passed XML node
 */
- (id)initFromNode:(INXMLNode *)node withServer:(IndivoServer *)aServer
{
	if ((self = [super initFromNode:node withServer:aServer])) {
		self.label = [node attr:@"label"];
	}
	return self;
}

/**
 *	Initializes a record from given parameters
 */
- (id)initWithId:(NSString *)anId name:(NSString *)aName onServer:(IndivoServer *)aServer
{
	if ((self = [super initFromNode:nil withServer:aServer])) {
		self.udid = anId;
		self.label = aName;
	}
	return self;
}



#pragma mark - Record Details
/**
 *	Fetches basic record info.
 */
- (void)fetchRecordInfoWithCallback:(INCancelErrorBlock)aCallback
{
	NSString *path = [NSString stringWithFormat:@"/records/%@", self.udid];
	
	[self get:path callback:^(BOOL success, NSDictionary *__autoreleasing userInfo) {
		
		// success, extract information
		if (success) {
			INXMLNode *doc = [userInfo objectForKey:INResponseXMLKey];
			if (!doc) {
				CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(aCallback, NO, @"Record Info XML was not valid")
			}
			else {
				if ([doc attr:@"label"]) {
					self.label = [doc attr:@"label"];
				}
				if ([[[doc childNamed:@"contact"] attr:@"document_id"] length] > 0) {
					self.hasContactDoc = YES;
				}
				if ([[[doc childNamed:@"demographics"] attr:@"document_id"] length] > 0) {
					self.hasContactDoc = YES;
				}
				
				NSString *docCreated = [[doc childNamed:@"created"] attr:@"at"];
				if ([docCreated length] > 0) {
					self.created = [INDateTime parseDateFromISOString:docCreated];
				}
				
				CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(aCallback, NO, nil)
			}
		}
		
		// no success today
		else {
			NSError *error = [userInfo objectForKey:INErrorKey];
			NSString *errorMsg = error ? [error localizedDescription] : nil;
			
			CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(aCallback, (nil == error), errorMsg)
		}
	}];
}

/**
 *	Fetches the record's contact document.
 */
- (void)fetchContactDocumentWithCallback:(INCancelErrorBlock)aCallback
{
	NSString *path = [NSString stringWithFormat:@"/records/%@/documents/special/contact", self.udid];
	
	[self get:path callback:^(BOOL success, NSDictionary *__autoreleasing userInfo) {
		
		// success, store the document
		if (success) {
			INXMLNode *doc = [userInfo objectForKey:INResponseXMLKey];
			if (!doc) {
				CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(aCallback, NO, @"Contact XML was not valid")
			}
			else {
				self.contactDoc = [[IndivoContact alloc] initFromNode:doc forRecord:self withMeta:nil];
				CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(aCallback, NO, nil)
			}
		}
		
		// we're in trouble!
		else {
			/// @todo Treat 404 differently
			NSError *error = [userInfo objectForKey:INErrorKey];
			NSString *errorMsg = error ? [error localizedDescription] : nil;
			
			CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(aCallback, (nil == error), errorMsg)
		}
	}];
}



#pragma mark - Managing Documents
/**
 *	Fetches the active reports of given type from the server
 *	@deprecated, use fetchReportsOfClass:withStatus:callback:
 */
- (void)fetchReportsOfClass:(Class)documentClass callback:(INSuccessRetvalueBlock)callback
{
	DLog(@"Deprecated, change this call to \"fetchReportsOfClass:withStatus:callback:\"");
	[self fetchReportsOfClass:documentClass withStatus:INDocumentStatusActive callback:callback];
}

/**
 *	Fetches reports of given type with any status from the server
 */
- (void)fetchAllReportsOfClass:(Class)documentClass callback:(INSuccessRetvalueBlock)callback
{
	NSMutableArray *reports = [NSMutableArray array];
	
	// fetch active
	[self fetchReportsOfClass:documentClass withStatus:INDocumentStatusActive callback:^(BOOL success, NSDictionary *__autoreleasing userInfo) {
		if (!success) {
			SUCCESS_RETVAL_CALLBACK_OR_LOG_USER_INFO(callback, userInfo);
			return;
		}
		[reports addObjectsFromArray:[userInfo objectForKey:INResponseArrayKey]];
		
		// fetch archived
		[self fetchReportsOfClass:documentClass withStatus:INDocumentStatusArchived callback:^(BOOL success, NSDictionary *__autoreleasing userInfo) {
			if (!success) {
				SUCCESS_RETVAL_CALLBACK_OR_LOG_USER_INFO(callback, userInfo);
				return;
			}
			[reports addObjectsFromArray:[userInfo objectForKey:INResponseArrayKey]];
			
			// fetch voided
			[self fetchReportsOfClass:documentClass withStatus:INDocumentStatusVoid callback:^(BOOL success, NSDictionary *__autoreleasing userInfo) {
				[reports addObjectsFromArray:[userInfo objectForKey:INResponseArrayKey]];
				NSMutableDictionary *newUserInfo = [NSMutableDictionary dictionaryWithDictionary:userInfo];
				[newUserInfo setObject:reports forKey:INResponseArrayKey];
				
				SUCCESS_RETVAL_CALLBACK_OR_LOG_USER_INFO(callback, newUserInfo);
			}];
		}];
	}];
}

/**
 *	Fetches reports with given status of given type from the server
 */
- (void)fetchReportsOfClass:(Class)documentClass withStatus:(INDocumentStatus)aStatus callback:(INSuccessRetvalueBlock)callback
{
	if (!documentClass || ![documentClass isSubclassOfClass:[IndivoDocument class]]) {
		NSString *errStr = [NSString stringWithFormat:@"Invalid Class, must be a subclass of IndivoDocument. Class given: %@", NSStringFromClass(documentClass)];
		SUCCESS_RETVAL_CALLBACK_OR_LOG_ERR_STRING(callback, errStr, 10)
		return;
	}
	
	// create URL
	NSString *path = [documentClass fetchReportPathForRecord:self];
	NSArray *params = [NSArray arrayWithObject:[NSString stringWithFormat:@"status=%@", stringStatusFor(aStatus)]];
	
	// fetch
	[self get:path
   parameters:params
	 callback:^(BOOL success, NSDictionary *__autoreleasing userInfo) {
		 
		 // fetched successfully...
		 if (success) {
			 //DLog(@"userInfo: %@", userInfo);
			 INXMLNode *reportsNode = [userInfo objectForKey:INResponseXMLKey];
			 NSArray *reports = [reportsNode childrenNamed:@"Report"];
			 
			 // create documents
			 NSMutableArray *reportArr = [NSMutableArray arrayWithCapacity:[reports count]];
			 for (INXMLReport *report in reports) {
				 IndivoMetaDocument *meta = [[IndivoMetaDocument alloc] initFromNode:[report metaDocumentNode] forRecord:self representingClass:documentClass];
				 IndivoDocument *doc = [[documentClass alloc] initFromNode:[report documentNode] forRecord:self withMeta:meta];
				 if (doc) {
					 [reportArr addObject:doc];
				 }
			 }
			 
			 NSDictionary *usrIfo = [NSDictionary dictionaryWithObject:reportArr forKey:INResponseArrayKey];
			 SUCCESS_RETVAL_CALLBACK_OR_LOG_USER_INFO(callback, usrIfo)
		 }
		 
		 // failed to fetch (or cancelled)
		 else {
			 SUCCESS_RETVAL_CALLBACK_OR_LOG_USER_INFO(callback, userInfo)
		 }
	 }];
}


/**
 *	@todo Create a method that fetches by type string
 */
// GET /records/{record_id}/documents/types/{type}/
// GET /records/{record_id}/documents/?type={type_url}


/**
 *	Instantiates a document of given class and adds it to our documents cache.
 *	@param documentClass Must be a subclass of IndivoDocument
 *	@param error An error pointer
 *	@return A newly instantiated object of the desired class
 */
- (IndivoDocument *)addDocumentOfClass:(Class)documentClass error:(NSError * __autoreleasing *)error
{
	if (!documentClass || ![documentClass isSubclassOfClass:[IndivoDocument class]]) {
		NSString *errStr = [NSString stringWithFormat:@"Invalid Class to add, must be a subclass of IndivoDocument. Class given: %@", NSStringFromClass(documentClass)];
		ERR(error, errStr, 10);
		return nil;
	}
	
	// instantiate
	IndivoDocument *newDocument = [documentClass newWithRecord:self];
	if (!newDocument) {
		NSString *errStr = [NSString stringWithFormat:@"Failed to instantiate %@", NSStringFromClass(documentClass)];
		ERR(error, errStr, 11);
		return nil;
	}
	
	// store and return
	if (!documents) {
		self.documents = [NSMutableArray arrayWithObject:newDocument];
	}
	else {
		[documents addObject:newDocument];
	}
	return newDocument;
}



#pragma mark - Utilities
- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ <0x%X> \"%@\" (id: %@)", NSStringFromClass([self class]), self, label, self.udid];
}


@end
