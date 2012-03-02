//
//  INQueryParameter.h
//  IndivoFramework
//
//  Created by Pascal Pfiffner on 3/2/12.
//  Copyright (c) 2012 Harvard Medical School. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Indivo.h"


/**
 *	Simplified use of Indivo's Query API
 */
@interface INQueryParameter : NSObject

@property (nonatomic, assign) NSUInteger offset;			///< The offset where to start, 0 by default
@property (nonatomic, assign) NSUInteger limit;				///< How many items to get, 100 by default

@property (nonatomic, copy) NSString *orderBy;				///< The field by which to order
@property (nonatomic, assign) BOOL descending;				///< NO by default, if YES the ordering is reversed

@property (nonatomic, assign) INDocumentStatus status;		///< The status of the documents, INDocumentStatusActive by default


- (id)initWithQueryString:(NSString *)aQuery;
- (NSArray *)queryParameters;


@end
