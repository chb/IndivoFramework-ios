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
 *	@file Indivo.h Header file with constants, blocks and typedefs
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

/**
 *	A block returning a success flag and a user info dictionary.
 *	If success is NO, you might find an NSError object in userInfo with key "INErrorKey". If no error is present, the operation was cancelled.
 */
typedef void (^INSuccessRetvalueBlock)(BOOL success, NSDictionary * __autoreleasing userInfo);

/**
 *	A block returning a flag whether the user cancelled and an error message on failure, nil otherwise.
 *	If userDidCancel is NO and errorMessage is nil, the operation completed successfully.
 */
typedef void (^INCancelErrorBlock)(BOOL userDidCancel, NSString * __autoreleasing errorMessage);

/**
 *	Document status flags.
 *	Note that if a document has been replaced, its status will still be "active", but it will return NO to [document isLatest]. This is a limitation of Indivo.
 */
typedef enum {
	INDocumentStatusUnknown = 0,						///< The status is unknown as of yet (e.g. the object has just been created)
	INDocumentStatusActive,								///< The document is active
	INDocumentStatusArchived,							///< This document has been archived, i.e. is no longer active
	INDocumentStatusVoid								///< This document has been voided, i.e. is to be considered deleted
} INDocumentStatus;

INDocumentStatus documentStatusFor(NSString *stringStatus);
NSString* stringStatusFor(INDocumentStatus documentStatus);

/**
 *	Message severity, aka priority
 */
typedef enum {
	INMessageSeverityUnknown = 0,
	INMessageSeverityLow,								///< "low" message priority/severity
	INMessageSeverityMedium,							///< "medium" message priority/severity
	INMessageSeverityHigh								///< "high" message priority/severity
} INMessageSeverity;

/**
 *	The type of a message. Indivo currently supports plaintext and MarkDown
 */
typedef enum {
	INMessageTypeUnknown = 0,
	INMessageTypePlaintext,								///< A plaintext message
	INMessageTypeMarkdown								///< A message formatted with markdown
} INMessageType;

INMessageSeverity messageSeverityFor(NSString *stringSeverity);
NSString* messageSeverityStringFor(INMessageSeverity severity);
INMessageType messageTypeFor(NSString *stringType);
NSString* messageTypeStringFor(INMessageType type);


/// You can uncomment this to not have XML pretty-formatted to save a couple of bytes
#define INDIVO_XML_PRETTY_FORMAT


/// DLog only displays if -DDEBUG is set, ALog always displays output regardless of the DEBUG setting
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

/// Macro to create an error in the NSCocoaErrorDomain domain
#ifndef ERR
# define ERR(p, s, c)\
	if (p != NULL && s) {\
		*p = [NSError errorWithDomain:NSCocoaErrorDomain code:(c ? c : 0) userInfo:[NSDictionary dictionaryWithObject:s forKey:NSLocalizedDescriptionKey]];\
	}\
	else {\
		DLog(@"Ignored Error: %@", s);\
	}
#endif

/// This creates an error object with NSXMLParserErrorDomain domain
#define XERR(p, s, c)\
	if (p != NULL && s) {\
		*p = [NSError errorWithDomain:NSXMLParserErrorDomain code:(c ? c : 0) userInfo:[NSDictionary dictionaryWithObject:s forKey:NSLocalizedDescriptionKey]];\
	}

/// Make callback or logging easy
#ifndef CANCEL_ERROR_CALLBACK_OR_LOG_FROM_USER_INFO
# define CANCEL_ERROR_CALLBACK_OR_LOG_FROM_USER_INFO(cb, userInfo)\
	NSError *error = [userInfo objectForKey:INErrorKey];\
	if (cb) {\
		cb((nil == error), [error localizedDescription]);\
	}\
	else if (error) {\
		DLog(@"No callback on this method, logging to debug. Error: %@", [error localizedDescription]);\
	}
#endif
#ifndef CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING
# define CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(cb, didCancel, errStr)\
	if (cb) {\
		cb(didCancel, errStr);\
	}\
	else if (errStr || didCancel) {\
		DLog(@"No callback on this method, logging to debug. Error: %@ (Cancelled: %d)", errStr, didCancel);\
	}
#endif
#ifndef SUCCESS_RETVAL_CALLBACK_OR_LOG_USER_INFO
# define SUCCESS_RETVAL_CALLBACK_OR_LOG_USER_INFO(cb, userInfo)\
	if (cb) {\
		cb(nil == [userInfo objectForKey:INErrorKey], userInfo);\
	}\
	else if ([userInfo objectForKey:INErrorKey]) {\
		DLog(@"No callback on this method, logging to debug. Result: %@", [[userInfo objectForKey:INErrorKey] localizedDescription]);\
	}
#endif
#ifndef SUCCESS_RETVAL_CALLBACK_OR_LOG_ERR_STRING
# define SUCCESS_RETVAL_CALLBACK_OR_LOG_ERR_STRING(cb, errStr, errCode)\
	if (cb) {\
		NSError *error = nil;\
		if (errStr) {\
			error = [NSError errorWithDomain:NSCocoaErrorDomain code:(errCode ? errCode : 0) userInfo:[NSDictionary dictionaryWithObject:errStr forKey:NSLocalizedDescriptionKey]];\
		}\
		cb((nil == error), error ? [NSDictionary dictionaryWithObject:error forKey:INErrorKey] : nil);\
	}\
	else if (errStr) {\
		DLog(@"No callback on this method, logging to debug. Error: %@", errStr);\
	}
#endif
