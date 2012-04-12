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
@property (nonatomic, readwrite, strong) IndivoDemographics *demographicsDoc;
@property (nonatomic, readwrite, strong) NSDate *created;

@property (nonatomic, strong) NSMutableArray *metaDocuments;					///< Storage for this records fetched document metadata
@property (nonatomic, strong) NSMutableArray *documents;						///< Storage for this records fetched documents: Does NOT automatically contain all documents

@end


@implementation IndivoRecord

@synthesize label, hasContactDoc, contactDoc, hasDemographicsDoc, demographicsDoc, created;
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
- (id)initWithId:(NSString *)anId onServer:(IndivoServer *)aServer
{
	if ((self = [super initFromNode:nil withServer:aServer])) {
		self.uuid = anId;
	}
	return self;
}



#pragma mark - Record Details
/**
 *	Fetches basic record info.
 */
- (void)fetchRecordInfoWithCallback:(INCancelErrorBlock)aCallback
{
	NSString *path = [NSString stringWithFormat:@"/records/%@", self.uuid];
	
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
	NSString *path = [NSString stringWithFormat:@"/records/%@/documents/special/contact", self.uuid];
	
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
		
		// error occurred
		else {
			NSString *errorMsg = nil;
			NSError *error = [userInfo objectForKey:INErrorKey];
			if (404 == [error code]) {
				errorMsg = @"This record has no contact data";
			}
			else {
				errorMsg = error ? [error localizedDescription] : nil;
			}
			CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(aCallback, (nil == error), errorMsg)
		}
	}];
}

/**
 *	Fetches the record's demographics document.
 */
- (void)fetchDemographicsDocumentWithCallback:(INCancelErrorBlock)aCallback
{
	NSString *path = [NSString stringWithFormat:@"/records/%@/documents/special/demographics", self.uuid];
	
	[self get:path callback:^(BOOL success, NSDictionary *__autoreleasing userInfo) {
		
		// success, store the document
		if (success) {
			INXMLNode *doc = [userInfo objectForKey:INResponseXMLKey];
			if (!doc) {
				CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(aCallback, NO, @"Demographics XML was not valid")
			}
			else {
				self.demographicsDoc = [[IndivoDemographics alloc] initFromNode:doc forRecord:self withMeta:nil];
				CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(aCallback, NO, nil)
			}
		}
		
		// we're in trouble!
		else {
			NSString *errorMsg = nil;
			NSError *error = [userInfo objectForKey:INErrorKey];
			if (404 == [error code]) {
				errorMsg = @"This record has no demographics";
			}
			else {
				errorMsg = error ? [error localizedDescription] : nil;
			}
			CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(aCallback, (nil == error), errorMsg)
		}
	}];
}



#pragma mark - Record Documents
/**
 *	Fetch all documents of the receiver, calling GET on /records/{record id}/documents/.
 *	Upon callback, the "INResponseArrayKey" of the user-info dictionary will contain meta-documents for this record's documents.
 */
- (void)fetchDocumentsWithCallback:(INSuccessRetvalueBlock)callback
{
	[self get:[NSString stringWithFormat:@"/records/%@/documents/", self.uuid]
	 callback:^(BOOL success, NSDictionary *__autoreleasing userInfo) {
		 NSDictionary *usrIfo = nil;
		 
		 // fetched successfully...
		 if (success) {
			 INXMLNode *documentsNode = [userInfo objectForKey:INResponseXMLKey];
			 NSArray *docs = [documentsNode childrenNamed:@"Document"];
			 
			 // create documents
			 NSMutableArray *metaArr = [NSMutableArray arrayWithCapacity:[docs count]];
			 for (INXMLReport *document in docs) {
				 IndivoMetaDocument *meta = [[IndivoMetaDocument alloc] initFromNode:document forRecord:self];
				 if (meta) {
					 [metaArr addObject:meta];
				 }
			 }
			 
			 usrIfo = [NSDictionary dictionaryWithObject:metaArr forKey:INResponseArrayKey];
		 }
		 else {
			 usrIfo = userInfo;
		 }
		 
		 SUCCESS_RETVAL_CALLBACK_OR_LOG_USER_INFO(callback, success, usrIfo);
	 }];
}



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
	
	// pre-populate non-nil properties
	for (NSString *propName in [[newDocument class] nonNilPropertyNames]) {
		Class propClass = [[newDocument class] classForProperty:propName];
		id propObj = [propClass new];
		if (propObj) {
			[newDocument setValue:propObj forKey:propName];
		}
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

/**
 *	Fetch app specific documents of the receiver, calling GET on /records/{record id}/apps/{app id}/documents/.
 *	Upon callback, the "INResponseArrayKey" of the user-info dictionary will contain IndivoAppDocument instances.
 */
- (void)fetchAppSpecificDocumentsWithCallback:(INSuccessRetvalueBlock)callback
{
	[self get:[NSString stringWithFormat:@"/records/%@/apps/%@/documents/", self.uuid, self.server.appId]
	 callback:^(BOOL success, NSDictionary *__autoreleasing userInfo) {
		 NSDictionary *usrIfo = nil;
		 
		 // fetched successfully
		 if (success) {
			 //DLog(@"Got XML:  %@", [userInfo objectForKey:INResponseStringKey]);
			 INXMLNode *documentsNode = [userInfo objectForKey:INResponseXMLKey];
			 NSArray *docs = [documentsNode childrenNamed:@"Document"];
			 
			 // create documents
			 NSMutableArray *appdocArr = [NSMutableArray arrayWithCapacity:[docs count]];
			 for (INXMLReport *document in docs) {
				 IndivoAppDocument *doc = [[IndivoAppDocument alloc] initFromNode:document forRecord:self];
				 if (doc) {
					 [appdocArr addObject:doc];
				 }
			 }
			 
			 usrIfo = [NSDictionary dictionaryWithObject:appdocArr forKey:INResponseArrayKey];
		 }
		 else {
			 usrIfo = userInfo;
		 }
		 
		 SUCCESS_RETVAL_CALLBACK_OR_LOG_USER_INFO(callback, success, usrIfo);
	 }];
}



#pragma mark - Reporting Calls
/**
 *	Fetches reports of given type with any status from the server
 */
- (void)fetchAllReportsOfClass:(Class)documentClass callback:(INSuccessRetvalueBlock)callback
{
	NSMutableArray *reports = [NSMutableArray array];
	
	// fetch active
	[self fetchReportsOfClass:documentClass withStatus:INDocumentStatusActive callback:^(BOOL success, NSDictionary *__autoreleasing userInfo) {
		if (!success) {
			SUCCESS_RETVAL_CALLBACK_OR_LOG_USER_INFO(callback, NO, userInfo);
			return;
		}
		[reports addObjectsFromArray:[userInfo objectForKey:INResponseArrayKey]];
		
		// fetch archived
		[self fetchReportsOfClass:documentClass withStatus:INDocumentStatusArchived callback:^(BOOL success, NSDictionary *__autoreleasing userInfo) {
			if (!success) {
				SUCCESS_RETVAL_CALLBACK_OR_LOG_USER_INFO(callback, NO, userInfo);
				return;
			}
			[reports addObjectsFromArray:[userInfo objectForKey:INResponseArrayKey]];
			
			// fetch voided
			[self fetchReportsOfClass:documentClass withStatus:INDocumentStatusVoid callback:^(BOOL success, NSDictionary *__autoreleasing userInfo) {
				[reports addObjectsFromArray:[userInfo objectForKey:INResponseArrayKey]];
				NSMutableDictionary *newUserInfo = [NSMutableDictionary dictionaryWithDictionary:userInfo];
				[newUserInfo setObject:reports forKey:INResponseArrayKey];
				
				SUCCESS_RETVAL_CALLBACK_OR_LOG_USER_INFO(callback, success, newUserInfo);
			}];
		}];
	}];
}

/**
 *	Fetches reports with given status of given type from the server
 */
- (void)fetchReportsOfClass:(Class)documentClass withStatus:(INDocumentStatus)aStatus callback:(INSuccessRetvalueBlock)callback
{
	INQueryParameter *aQuery = [INQueryParameter new];
	aQuery.status = aStatus;
	
	[self fetchReportsOfClass:documentClass withQuery:aQuery callback:callback];
}


/**
 *	Fetches reports limited by the query parameters given.
 *	@attention The "INResponseArrayKey" will contain either IndivoAggregateReport objects or IndivoDocument-subclass objects (of the class supplied to the method)
 *	@param documentClass The class representing the desired document type (e.g. IndivoMedication for medication reports)
 *	@param aQuery The query parameters restricting the query
 *	@param callback The block to execute upon success or failure
 */
- (void)fetchReportsOfClass:(Class)documentClass withQuery:(INQueryParameter *)aQuery callback:(INSuccessRetvalueBlock)callback
{
	if (!documentClass || ![documentClass isSubclassOfClass:[IndivoDocument class]]) {
		NSString *errStr = [NSString stringWithFormat:@"Invalid Class, must be a subclass of IndivoDocument. Class given: %@", NSStringFromClass(documentClass)];
		SUCCESS_RETVAL_CALLBACK_OR_LOG_ERR_STRING(callback, errStr, 10)
		return;
	}
	
	// create URL
	NSString *path = [documentClass fetchReportPathForRecord:self];
	if (!path) {
		NSString *errStr = [NSString stringWithFormat:@"This class does not offer reporting: %@", NSStringFromClass(documentClass)];
		SUCCESS_RETVAL_CALLBACK_OR_LOG_ERR_STRING(callback, errStr, 2200)
		return;
	}
	
	// fetch
	[self get:path
   parameters:[aQuery queryParameters]
	 callback:^(BOOL success, NSDictionary *__autoreleasing userInfo) {
		 NSDictionary *usrIfo = nil;
		 
		 // fetched successfully...
		 if (success) {
			 //DLog(@"Incoming XML: %@", [userInfo objectForKey:INResponseStringKey]);
			 INXMLNode *reportsNode = [userInfo objectForKey:INResponseXMLKey];
			 NSArray *reports = [reportsNode childrenNamed:@"Report"];
			 
			 // create documents
			 NSMutableArray *reportArr = [NSMutableArray arrayWithCapacity:[reports count]];
			 for (INXMLReport *report in reports) {
				 IndivoMetaDocument *meta = [[IndivoMetaDocument alloc] initFromNode:[report metaDocumentNode] forRecord:self];
				 meta.documentClass = documentClass;
				 
				 // document?
				 INXMLNode *docNode = [report documentNode];
				 if (docNode) {
					 IndivoDocument *doc = [[documentClass alloc] initFromNode:docNode forRecord:self withMeta:meta];
					 if (doc) {
						 [reportArr addObject:doc];
					 }
				 }
				 
				 // aggregate report?
				 else {
					 INXMLNode *aggNode = [report aggregateReportNode];
					 if (aggNode) {
						 IndivoAggregateReport *aggregate = [[IndivoAggregateReport alloc] initFromNode:aggNode forRecord:self withMeta:meta];
						 if (aggregate) {
							 [reportArr addObject:aggregate];
						 } 
					 }
				 }
			 }
			 
			 // return in user info
			 usrIfo = [NSDictionary dictionaryWithObject:reportArr forKey:INResponseArrayKey];
		 }
		 
		 SUCCESS_RETVAL_CALLBACK_OR_LOG_USER_INFO(callback, success, usrIfo);
	 }];
}


/**
 *	@todo Create a method that fetches by type string
 */
// GET /records/{record_id}/documents/types/{type}/
// GET /records/{record_id}/documents/?type={type_url}




#pragma mark - Messaging
/**
 *	Posts a message to the record's inbox. This method auto-generates a message id, which generally is what you want.
 *	This method generates an API call POST /records/{RECORD_ID}/inbox/{MESSAGE_ID} with the given arguments. If attachments are supplied, the callback will only be called
 *	once all attachments have been uploaded.
 *	@param messageSubject The message subject
 *	@param messageBody The message's body
 *	@param type How to interpret the message body
 *	@param severity The severity or priority of the message
 *	@param attachments An array containing IndivoDocument instances.
 *	@param callback The block to be called when the operation finishes.
 */
- (void)sendMessage:(NSString *)messageSubject
		   withBody:(NSString *)messageBody
			 ofType:(INMessageType)type
		   severity:(INMessageSeverity)severity
		attachments:(NSArray *)attachments
		   callback:(INCancelErrorBlock)callback
{
	CFUUIDRef generatedUUID = CFUUIDCreate(kCFAllocatorDefault);
	NSString *newUUID = (__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault, generatedUUID);
	CFRelease(generatedUUID);
	
	[self sendMessage:messageBody withBody:messageSubject ofType:type severity:severity attachments:attachments messageId:[newUUID lowercaseString] callback:callback];
}

/**
 *	Posts a message to the record's inbox.
 *	This method generates an API call POST /records/{RECORD_ID}/inbox/{MESSAGE_ID} with the given arguments. If attachments are supplied, the callback will only be called
 *	once all attachments have been uploaded.
 *	@param messageSubject The message subject
 *	@param messageBody The message's body
 *	@param type How to interpret the message body
 *	@param severity The severity or priority of the message
 *	@param attachments An array containing IndivoDocument instances.
 *	@param messageId A message id
 *	@param callback The block to be called when the operation finishes.
 */
- (void)sendMessage:(NSString *)messageSubject
		   withBody:(NSString *)messageBody
			 ofType:(INMessageType)type
		   severity:(INMessageSeverity)severity
		attachments:(NSArray *)attachments
		  messageId:(NSString *)messageId
		   callback:(INCancelErrorBlock)callback
{
	NSString *path = [NSString stringWithFormat:@"/records/%@/inbox/%@", self.uuid, messageId];
	NSString *body = [NSString stringWithFormat:
					  @"body=%@&body_type=%@&subject=%@&severity=%@&num_attachments=%d",
					  messageBody ? [messageBody stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] : @"",
					  messageTypeStringFor(type),
					  [messageSubject stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
					  messageSeverityStringFor(severity),
					  [attachments count]
					  ];
	
	// sending a message with attachments
	if ([attachments count] > 0) {
		[self post:path body:body callback:^(BOOL success, NSDictionary *__autoreleasing userInfo) {
			if (!success) {
				CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(callback, NO, @"failed")
			}
			else {
				NSUInteger i = 0;
				for (IndivoDocument *doc in attachments) {
					i++;			// increment before as the attachment-number is 1-based
					NSString *postPath = [NSString stringWithFormat:@"/records/%@/inbox/%@/attachments/%d", self.uuid, messageId, i];
					[self post:postPath body:[doc documentXML] callback:NULL];
				}
				CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(callback, NO, nil)
			}
		}];
	}
	
	// sending a message without attachments
	else {
		[self post:path body:body callback:^(BOOL success, NSDictionary *__autoreleasing userInfo) {
			if (success) {
				CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(callback, NO, nil)
			}
			else {
				NSError *error = [userInfo objectForKey:INErrorKey];
				NSString *errMsg = error ? [error localizedDescription] : @"Failed to send a message";
				CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(callback, NO, errMsg)
			}
		}];
	}
}



#pragma mark - Utilities
- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ <0x%X> \"%@\" (id: %@)", NSStringFromClass([self class]), self, label, self.uuid];
}


@end



#pragma mark - Message Utility Functions
INMessageSeverity messageSeverityFor(NSString *stringSeverity)
{
	if ([@"low" isEqualToString:stringSeverity]) {
		return INMessageSeverityLow;
	}
	else if ([@"medium" isEqualToString:stringSeverity]) {
		return INMessageSeverityMedium;
	}
	else if ([@"high" isEqualToString:stringSeverity]) {
		return INMessageSeverityHigh;
	}
	
	DLog(@"Unknown message severity: \"%@\"", stringSeverity);
	return INMessageSeverityUnknown;
}

NSString* messageSeverityStringFor(INMessageSeverity severity)
{
	if (INMessageSeverityLow == severity) {
		return @"low";
	}
	else if (INMessageSeverityMedium == severity) {
		return @"medium";
	}
	else if (INMessageSeverityHigh == severity) {
		return @"high";
	}
	
	DLog(@"Unknown message severity, returning low");
	return @"low";
}

INMessageType messageTypeFor(NSString *stringType)
{
	if ([@"plaintext" isEqualToString:stringType]) {
		return INMessageTypePlaintext;
	}
	else if ([@"markdown" isEqualToString:stringType]) {
		return INMessageTypeMarkdown;
	}
	
	DLog(@"Unknown message type: \"%@\"", stringType);
	return INMessageTypeUnknown;
}

NSString* messageTypeStringFor(INMessageType type)
{
	if (INMessageTypePlaintext == type) {
		return @"plaintext";
	}
	else if (INMessageTypeMarkdown == type) {
		return @"markdown";
	}
	
	DLog(@"Unknown message type, returning plaintext");
	return @"plaintext";
}

