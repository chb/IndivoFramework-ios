/*
 Indivo.h
 IndivoFramework
 
 Created by Pascal Pfiffner on 9/22/11.
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


/**
 *	Header file with constants, blocks and typedefs
 */


// Dictionary keys
extern NSString *const INErrorKey;						///< Dictionaries return an NSError for this key
extern NSString *const INRecordIDKey;					///< Dictionaries return an NSString for this key. The key reflects the oauth URL param name.
extern NSString *const INResponseStringKey;				///< Dictionaries return the server's response as an NSString for this key
extern NSString *const INResponseXMLKey;				///< Dictionaries return parsed XML as an INXMLNode from the server's response for this key
extern NSString *const INResponseArrayKey;				///< Dictionaries return an NSArray for this key

// Other globals
extern NSString *const INInternalScheme;				///< The URL scheme we use to identify when the framework should intercept a request

// Notifications
extern NSString *const INRecordDocumentsDidChangeNotification;		///< Notifications with this name will be posted if documents did change, right AFTER the callback has been called
extern NSString *const INRecordUserInfoKey;							///< For INRecordDocumentsDidChangeNotification notifications, use this key on the userInfo to find the record object

// Our blocks
typedef void (^INErrorBlock)(NSString * __autoreleasing errorMessage);									///< A block returning a message on failure, nil on success
typedef void (^INSuccessRetvalueBlock)(BOOL success, NSDictionary * __autoreleasing userInfo);			///< A block returning a success flag and a user info dictionary
typedef void (^INCancelErrorBlock)(BOOL userDidCancel, NSString * __autoreleasing errorMessage);		///< A block returning a flag whether the user cancelled and an error message on failure, nil otherwise

// Document status flags
typedef enum {
	INDocumentStatusUnknown = 0,						///< The status is unknown as of yet
	INDocumentStatusActive,								///< The document is active
	INDocumentStatusArchived,							///< This document has been archived, i.e. is no longer active
	INDocumentStatusVoid								///< This document has been voided, i.e. is to be considered deleted
} INDocumentStatus;

// You can uncomment this to not have XML pretty-formatted to save a couple of bytes
#define INDIVO_XML_PRETTY_FORMAT
