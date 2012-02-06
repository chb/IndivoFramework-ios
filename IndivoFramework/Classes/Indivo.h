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
extern NSString *const INClassGeneratorClassPrefix;		///< The class generator uses this prefix for our classes ("Indivo" by default). We need to know it to instantiate nodes from XML.
extern NSString *const INClassGeneratorTypePrefix;		///< The class generator uses this prefix for our types ("indivo" by default).

// Notifications
extern NSString *const INRecordDocumentsDidChangeNotification;		///< Notifications with this name will be posted if documents did change, right AFTER the callback has been called
extern NSString *const INRecordUserInfoKey;							///< For INRecordDocumentsDidChangeNotification notifications, use this key on the userInfo to find the record object

// Our blocks
typedef void (^INErrorBlock)(NSString * __autoreleasing errorMessage);									///< A block returning a message on failure, nil on success
typedef void (^INSuccessRetvalueBlock)(BOOL success, NSDictionary * __autoreleasing userInfo);			///< A block returning a success flag and a user info dictionary
typedef void (^INCancelErrorBlock)(BOOL userDidCancel, NSString * __autoreleasing errorMessage);		///< A block returning a flag whether the user cancelled and an error message on failure, nil otherwise

// Document status flags
typedef enum {
	INDocumentStatusUnknown = 0,						///< The status is unknown as of yet (e.g. the object has just been created)
	INDocumentStatusActive,								///< The document is active
	INDocumentStatusArchived,							///< This document has been archived, i.e. is no longer active
	INDocumentStatusVoid								///< This document has been voided, i.e. is to be considered deleted
} INDocumentStatus;

// You can uncomment this to not have XML pretty-formatted to save a couple of bytes
#define INDIVO_XML_PRETTY_FORMAT


// ** the following are defined in the PCH but we put it here because we want them to be usable in other targets as well

// DLog only displays if -DDEBUG is set, ALog always displays output regardless of the DEBUG setting
#ifndef DLog
# ifdef INDIVO_DEBUG
#  define DLog(fmt, ...) NSLog((@"%s (line %d) " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
# else
#  define DLog(...) do { } while (0)
# endif
#endif
#ifndef ALog
# define ALog(fmt, ...) NSLog((@"%s (line %d) " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#endif

// Make error reporting easy
#ifndef ERR
# define ERR(p, s, c)\
	if (p != NULL && s) {\
		*p = [NSError errorWithDomain:NSCocoaErrorDomain code:(c ? c : 0) userInfo:[NSDictionary dictionaryWithObject:s forKey:NSLocalizedDescriptionKey]];\
	}\
	else {\
		DLog(@"Ignored Error: %@", s);\
	}
#endif
#define XERR(p, s, c)\
	if (p != NULL && s) {\
		*p = [NSError errorWithDomain:NSXMLParserErrorDomain code:(c ? c : 0) userInfo:[NSDictionary dictionaryWithObject:s forKey:NSLocalizedDescriptionKey]];\
	}

// Make callback or logging easy
#ifndef CANCEL_ERROR_CALLBACK_OR_LOG_USER_INFO
# define CANCEL_ERROR_CALLBACK_OR_LOG_USER_INFO(cb, userInfo)\
	NSError *error = [userInfo objectForKey:INErrorKey];\
	if (cb) {\
		cb((nil == error), [error localizedDescription]);\
	}\
	else {\
		DLog(@"%@", [error localizedDescription]);\
	}
#endif
#ifndef CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING
# define CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(cb, didCancel, errstr)\
	if (cb) {\
		cb(didCancel, errstr);\
	}\
	else {\
		DLog(@"%@ (Cancelled: %d)", errstr, didCancel);\
	}
#endif
#ifndef SUCCESS_RETVAL_CALLBACK_OR_LOG_USER_INFO
# define SUCCESS_RETVAL_CALLBACK_OR_LOG_USER_INFO(cb, userInfo)\
	if (cb) {\
		cb(nil == [userInfo objectForKey:INErrorKey], userInfo);\
	}\
	else {\
		DLog(@"%@", [userInfo objectForKey:INErrorKey] ? [[userInfo objectForKey:INErrorKey] localizedDescription] : @"Success");\
	}
#endif
#ifndef SUCCESS_RETVAL_CALLBACK_OR_LOG_ERR_STRING
# define SUCCESS_RETVAL_CALLBACK_OR_LOG_ERR_STRING(cb, s, c)\
	NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:(c ? c : 0) userInfo:[NSDictionary dictionaryWithObject:s forKey:NSLocalizedDescriptionKey]];\
	if (cb) {\
		cb(NO, [NSDictionary dictionaryWithObject:error forKey:INErrorKey]);\
	}\
	else {\
		DLog(@"%@", s);\
	}
#endif
