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
 *	The supported date-grouping values
 */
typedef enum {
	INDateGroupUnknown = 0,
	INDateGroupHour,
	INDateGroupDay,
	INDateGroupWeek,
	INDateGroupMonth,
	INDateGroupYear,
	INDateGroupHourOfDay,
	INDateGroupDayOfWeek,
	INDateGroupWeekOfYear,
	INDateGroupMonthOfYear
} INDateGroup;

INDateGroup dateGroupFor(NSString *stringType);
NSString* dateGroupIncrementStringFor(INDateGroup increment);


/**
 *	The supported field aggregation operators
 */
typedef enum {
	INAggregationOperatorUnknown = 0,
	INAggregationOperatorSum,
	INAggregationOperatorAverage,
	INAggregationOperatorMin,
	INAggregationOperatorMax,
	INAggregationOperatorCount
} INAggregationOperator;

INAggregationOperator aggregationOperatorFor(NSString *stringOperator);
NSString *aggregationOperatorStringFor(INAggregationOperator aggOperator);



/**
 *	Simplified use of Indivo's Query API
 */
@interface INQueryParameter : NSObject

@property (nonatomic, assign) INDocumentStatus status;			///< The status of the documents, INDocumentStatusUnknown by default

@property (nonatomic, assign) NSUInteger offset;				///< The offset where to start, 0 by default
@property (nonatomic, assign) NSUInteger limit;					///< How many items to get, 0 by default which will return the server's default
@property (nonatomic, copy) NSString *orderBy;					///< The field by which to order
@property (nonatomic, assign) BOOL descending;					///< NO by default, if YES the ordering is reversed

@property (nonatomic, copy) NSString *groupBy;					///< Group by values of this field. If "orderBy" is not nil it will be reset to this value.
@property (nonatomic, copy) NSString *aggregateBy;				///< The field by which to aggregate
@property (nonatomic, assign) INAggregationOperator aggregateOperator;		///< The operator to apply to the "aggregateBy" field

@property (nonatomic, copy) NSString *dateRangeField;			///< The field upon which to limit the date range
@property (nonatomic, strong) NSDate *dateRangeStart;			///< Starting date of the date range in field "dateRangeField"
@property (nonatomic, strong) NSDate *dateRangeEnd;				///< End date of the date range in field "dateRangeField"

@property (nonatomic, copy) NSString *dateGroupField;			///< The field which to group according to "dateGroupIncrement"
@property (nonatomic, assign) INDateGroup dateGroupIncrement;	///< The increment for date grouping


- (id)initWithQueryString:(NSString *)aQuery;
- (void)setFromQueryString:(NSString *)aQuery;
- (BOOL)updateFromParameter:(NSString *)paramString withValue:(NSString *)paramValue;
- (NSArray *)queryParameters;

- (void)addParameter:(NSString *)aParameter withValue:(NSString *)paramValue;
- (void)removeParameterForKey:(NSString *)aKey;


@end
