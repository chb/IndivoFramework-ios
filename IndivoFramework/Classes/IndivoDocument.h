/*
 IndivoDocument.h
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

#import "IndivoAbstractDocument.h"

@class IndivoMetaDocument;
@class IndivoPrincipal;


/**
 *	An IndivoDocument represents a document tied to a record. It's the superclass to all the specific document types we
 *	provide (IndivoMedication, IndivoAllergy and so on) and if you implement your own type, you should consider using
 *	this as the base class.
 */
@interface IndivoDocument : IndivoAbstractDocument

@property (nonatomic, readonly, copy) NSString *label;								///< This document's label
@property (nonatomic, readonly, assign) INDocumentStatus documentStatus;			///< This document's status
@property (nonatomic, readonly, assign) BOOL fetched;								///< YES if the document has been fetched from the server

@property (nonatomic, readonly, strong) IndivoPrincipal *creator;					///< The creator of the document
@property (nonatomic, readonly, copy) NSString *uuidLatest;							///< The udid of the latest document of the receiver
@property (nonatomic, readonly, copy) NSString *uuidOriginal;						///< The udid of the original document, if the receiver replaced a document
@property (nonatomic, readonly, copy) NSString *uuidReplaces;						///< The udid of the replaced document, if the receiver replaced a document

- (id)initFromNode:(INXMLNode *)aNode forRecord:(IndivoRecord *)aRecord withMeta:(IndivoMetaDocument *)aMetaDocument;

- (void)updateWithMeta:(IndivoMetaDocument *)aMetaDoc;

// Server paths
+ (NSString *)fetchReportPathForRecord:(IndivoRecord *)aRecord;
- (NSString *)documentPath;
- (NSString *)basePostPath;

// Document properties
+ (NSString *)reportType;
- (BOOL)hasStatus:(INDocumentStatus)aStatus;
- (BOOL)isLatest;
- (void)fetchVersionsWithCallback:(INSuccessRetvalueBlock)callback;
- (void)fetchStatusHistoryWithCallback:(INSuccessRetvalueBlock)callback;
- (void)fetchMetaDocumentWithCallback:(INSuccessRetvalueBlock)callback;

// Document actions
- (void)pull:(INCancelErrorBlock)callback;
- (void)push:(INCancelErrorBlock)callback;
- (void)replace:(INCancelErrorBlock)callback;
- (void)setLabel:(NSString *)aLabel callback:(INCancelErrorBlock)callback;
- (void)void:(BOOL)flag forReason:(NSString *)aReason callback:(INCancelErrorBlock)callback;
- (void)archive:(BOOL)flag forReason:(NSString *)aReason callback:(INCancelErrorBlock)callback;

// Registering type representations
+ (Class)documentClassForType:(NSString *)aType;
+ (void)registerDocumentClass:(Class)aClass;

// Caching
- (BOOL)cacheObject:(id)anObject asType:(NSString *)aType error:(__autoreleasing NSError **)error;
- (id)cachedObjectOfType:(NSString *)aType;
+ (BOOL)cacheObject:(id)anObject asType:(NSString *)aType forId:(NSString *)aUdid error:(__autoreleasing NSError **)error;
+ (id)cachedObjectOfType:(NSString *)aType forId:(NSString *)aUdid;


@end

// Make notifications easy
#ifndef POST_DOCUMENTS_DID_CHANGE_FOR_RECORD_NOTIFICATION
# define POST_DOCUMENTS_DID_CHANGE_FOR_RECORD_NOTIFICATION(r)\
	if (r) {\
		NSDictionary *userDict = [NSDictionary dictionaryWithObject:r forKey:INRecordUserInfoKey];\
		[[NSNotificationCenter defaultCenter] postNotificationName:INRecordDocumentsDidChangeNotification object:nil userInfo:userDict];\
	}
#endif


