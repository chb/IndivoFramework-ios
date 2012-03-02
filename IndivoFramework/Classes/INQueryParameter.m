//
//  INQueryParameter.m
//  IndivoFramework
//
//  Created by Pascal Pfiffner on 3/2/12.
//  Copyright (c) 2012 Harvard Medical School. All rights reserved.
//

#import "INQueryParameter.h"
#import "INURLLoader.h"
#import "INDate.h"
#import "INDateTime.h"


@interface INQueryParameter ()

@property (nonatomic, strong) NSMutableDictionary *customParameter;

@end


@implementation INQueryParameter

@synthesize status;
@synthesize offset, limit;
@synthesize orderBy, descending;
@synthesize groupBy, aggregateBy, aggregateOperator;
@synthesize dateRangeField, dateRangeStart, dateRangeEnd;
@synthesize dateGroupField, dateGroupIncrement;
@synthesize customParameter;


- (id)init
{
	if ((self = [super init])) {
	}
	return self;
}


/**
 *	Initializes the receiver with information found in the query string
 */
- (id)initWithQueryString:(NSString *)aQuery
{
	if ((self = [self init]) && [aQuery length] > 0) {
		[self setFromQueryString:aQuery];
	}
	return self;
}



#pragma mark - Overrides
/**
 *	When setting group by, the order by must be the same field (or the field in aggregate by). This setter checks for these restrictions.
 */
- (void)setGroupBy:(NSString *)newGroupBy
{
	if (newGroupBy != groupBy) {
		groupBy = newGroupBy;
		
		if ([groupBy length] > 0 && [orderBy length] > 0
			&& ![orderBy isEqualToString:groupBy]
			&& ![orderBy isEqualToString:aggregateBy]) {
			self.orderBy = groupBy;
		}
	}
}

/**
 *	When setting aggregate by, the order by must be the same field (or the field in group by). This setter checks for these restrictions.
 */
- (void)setAggregateBy:(NSString *)newAggBy
{
	if (newAggBy != aggregateBy) {
		aggregateBy = newAggBy;
		
		if ([aggregateBy length] > 0 && [orderBy length] > 0
			&& ![orderBy isEqualToString:aggregateBy]
			&& ![orderBy isEqualToString:groupBy]) {
			self.orderBy = aggregateBy;
		}
	}
}



#pragma mark - From and To URL String
/**
 *	Sets the receivers properties from the supplied query string.
 *	@attention Existing values will only be altered if they are present in the query string, unaffected values will not be reset to default.
 *	@param aQuery A query string, e.g. "offset=20&limit=20", from which to parse the properties
 */
- (void)setFromQueryString:(NSString *)aQuery
{
	NSDictionary *params = [INURLLoader queryFromRequestString:aQuery];
	for (NSString *key in [params allKeys]) {
		[self updateFromParameter:key withValue:[params objectForKey:key]];
	}
}


/**
 *	Sets the internal state represented by the given parameter string, according to the key
 *	@return YES if the parameter is handled internally, NO otherwise
 */
- (BOOL)updateFromParameter:(NSString *)aParameter withValue:(NSString *)paramValue
{
	BOOL found = NO;
	
	if ([paramValue length] > 0 && [aParameter length] > 0) {
		
		// status
		if ([@"status" isEqualToString:aParameter]) {
			self.status = documentStatusFor(paramValue);
			found = YES;
		}
		
		// paging and ordering
		else if ([@"offset" isEqualToString:aParameter]) {
			offset = ABS([paramValue integerValue]);
			found = YES;
		}
		
		else if ([@"limit" isEqualToString:aParameter]) {
			limit = ABS([paramValue integerValue]);
			found = YES;
		}
		
		else if ([@"order_by" isEqualToString:aParameter]) {
			descending = [@"-" isEqualToString:[paramValue substringToIndex:1]];
			self.orderBy = descending ? [paramValue substringFromIndex:1] : paramValue;
			found = YES;
		}
		
		// grouping and aggregation
		else if ([@"group_by" isEqualToString:aParameter]) {
			self.groupBy = paramValue;
			found = YES;
		}
		else if ([@"aggregate_by" isEqualToString:aParameter]) {
			NSArray *parts = [paramValue componentsSeparatedByString:@"*"];
			if ([parts count] > 1) {
				self.aggregateOperator = aggregationOperatorFor([parts objectAtIndex:0]);
				self.aggregateBy = [parts objectAtIndex:1];
			}
			found = YES;
		}
		
		// date range
		else if ([@"date_range" isEqualToString:aParameter]) {
			NSArray *parts = [paramValue componentsSeparatedByString:@"*"];
			NSDate *startDate = nil;
			NSDate *endDate = nil;
			
			if ([parts count] > 0) {
				self.dateRangeField = [parts objectAtIndex:0];
				
				// start date
				if ([parts count] > 1) {
					startDate = [INDateTime parseDateFromISOString:[parts objectAtIndex:1]];
					if (!startDate) {
						startDate = [INDate parseDateFromISOString:[parts objectAtIndex:1]];
					}
					
					// end date
					if ([parts count] > 2) {
						endDate = [INDateTime parseDateFromISOString:[parts objectAtIndex:2]];
						if (!endDate) {
							endDate = [INDate parseDateFromISOString:[parts objectAtIndex:2]];
						}
					}
				}
			}
			
			self.dateRangeStart = startDate;
			self.dateRangeEnd = endDate;
			found = YES;
		}
		
		// date group
		else if ([@"date_group" isEqualToString:aParameter]) {
			NSArray *parts = [paramValue componentsSeparatedByString:@"*"];
			
			if ([parts count] > 1) {
				self.dateGroupField = [parts objectAtIndex:0];
				self.dateGroupIncrement = dateGroupFor([parts objectAtIndex:1]);
			}
			found = YES;
		}
	}
	return found;
}


- (NSArray *)queryParameters
{
	NSMutableArray *params = [NSMutableArray array];
	
	// status
	if (INDocumentStatusUnknown != status) {
		[params addObject:[NSString stringWithFormat:@"status=%@", stringStatusFor(status)]];
	}
	
	// paging and ordering
	if (offset > 0) {
		[params addObject:[NSString stringWithFormat:@"offset=%d", offset]];
	}
	if (limit > 0) {
		[params addObject:[NSString stringWithFormat:@"limit=%d", limit]];
	}
	if ([orderBy length] > 0) {
		[params addObject:[NSString stringWithFormat:@"order_by=%@%@", (descending ? @"-" : @""), orderBy]];
	}
	
	// aggregate by
	BOOL hasAggregateBy = NO;
	if ([aggregateBy length] > 0 && INAggregationOperatorUnknown != aggregateOperator) {
		[params addObject:[NSString stringWithFormat:@"aggregate_by=%@*%@", aggregationOperatorStringFor(aggregateOperator), aggregateBy]];
		hasAggregateBy = YES;
	}
	
	// group by
	if ([groupBy length] > 0) {
		[params addObject:[NSString stringWithFormat:@"group_by=%@", groupBy]];
		
		if (!hasAggregateBy) {
			[params addObject:[NSString stringWithFormat:@"aggregate_by=count*%@", groupBy]];		// must not be empty for the call to succeed
			hasAggregateBy = YES;
		}
	}
	
	// date range
	if ([dateRangeField length] > 0) {
		NSString *paramString = [NSString stringWithFormat:@"date_range=%@*%@*%@", dateRangeField, [INDateTime isoStringFrom:dateRangeStart], [INDateTime isoStringFrom:dateRangeEnd]];
		[params addObject:paramString];
	}
	
	// date group
	if ([dateGroupField length] > 0 && INDateGroupUnknown != dateGroupIncrement) {
		[params addObject:[NSString stringWithFormat:@"date_group=%@*%@", dateGroupField, dateGroupIncrementStringFor(dateGroupIncrement)]];
		
		if (!hasAggregateBy) {
			[params addObject:[NSString stringWithFormat:@"aggregate_by=count*%@", dateGroupField]];		// must not be empty for the call to succeed
			hasAggregateBy = YES;
		}
	}
	
	// custom parameters
	if ([customParameter count] > 0) {
		for (NSString *key in customParameter) {
			NSString *value = [[customParameter objectForKey:key] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			[params addObject:[NSString stringWithFormat:@"%@=%@", key, value]];
		}
	}
	
	return params;
}



#pragma mark - Custom Parameters
/**
 *	Adds a custom parameter. If it matches one of the supported types, that one is used instead.
 */
- (void)addParameter:(NSString *)aParameter withValue:(NSString *)paramValue
{
	if (!aParameter || !paramValue) {
		return;
	}
	if ([self updateFromParameter:aParameter withValue:paramValue]) {
		return;
	}
	
	if (!customParameter) {
		self.customParameter = [NSMutableDictionary dictionary];
	}
	[customParameter setObject:paramValue forKey:aParameter];
}

/**
 *	Unsets a custom parameter. If it matches a supported type, that one is unset instead (NOT YET IMPLEMENTED)
 */
- (void)removeParameterForKey:(NSString *)aKey;
{
	/// @todo unset built-in parameter
	[customParameter removeObjectForKey:aKey];
}


@end




INDateGroup dateGroupFor(NSString *stringGroup)
{
	if ([@"hour" isEqualToString:stringGroup]) {
		return INDateGroupHour;
	}
	else if ([@"day" isEqualToString:stringGroup]) {
		return INDateGroupDay;
	}
	else if ([@"week" isEqualToString:stringGroup]) {
		return INDateGroupWeek;
	}
	else if ([@"month" isEqualToString:stringGroup]) {
		return INDateGroupMonth;
	}
	else if ([@"year" isEqualToString:stringGroup]) {
		return INDateGroupYear;
	}
	else if ([@"hourofday" isEqualToString:stringGroup]) {
		return INDateGroupHourOfDay;
	}
	else if ([@"dayofweek" isEqualToString:stringGroup]) {
		return INDateGroupDayOfWeek;
	}
	else if ([@"weekofyear" isEqualToString:stringGroup]) {
		return INDateGroupWeekOfYear;
	}
	else if ([@"monthofyear" isEqualToString:stringGroup]) {
		return INDateGroupMonthOfYear;
	}
	
	DLog(@"Unknown date group \"%@\"", stringGroup);
	return INDateGroupUnknown;
}

NSString* dateGroupIncrementStringFor(INDateGroup increment)
{
	if (INDateGroupHour == increment) {
		return @"hour";
	}
	else if (INDateGroupDay == increment) {
		return @"day";
	}
	else if (INDateGroupWeek == increment) {
		return @"week";
	}
	else if (INDateGroupMonth == increment) {
		return @"month";
	}
	else if (INDateGroupYear == increment) {
		return @"year";
	}
	else if (INDateGroupHourOfDay == increment) {
		return @"hourofday";
	}
	else if (INDateGroupDayOfWeek == increment) {
		return @"dayofweek";
	}
	else if (INDateGroupWeekOfYear == increment) {
		return @"weekofyear";
	}
	else if (INDateGroupMonthOfYear == increment) {
		return @"monthofyear";
	}
	
	DLog(@"Unknown date group, returning empty string");
	return @"";
}



INAggregationOperator aggregationOperatorFor(NSString *stringOperator)
{
	if ([@"count" isEqualToString:stringOperator]) {
		return INAggregationOperatorCount;
	}
	else if ([@"sum" isEqualToString:stringOperator]) {
		return INAggregationOperatorSum;
	}
	else if ([@"avg" isEqualToString:stringOperator]) {
		return INAggregationOperatorAverage;
	}
	else if ([@"min" isEqualToString:stringOperator]) {
		return INAggregationOperatorMin;
	}
	else if ([@"max" isEqualToString:stringOperator]) {
		return INAggregationOperatorMax;
	}
	
	DLog(@"Unknown aggregation operator \"%@\"", stringOperator);
	return INAggregationOperatorUnknown;
}


NSString *aggregationOperatorStringFor(INAggregationOperator aggOperator)
{
	if (INAggregationOperatorSum == aggOperator) {
		return @"sum";
	}
	else if (INAggregationOperatorAverage == aggOperator) {
		return @"avg";
	}
	else if (INAggregationOperatorMin == aggOperator) {
		return @"min";
	}
	else if (INAggregationOperatorMax == aggOperator) {
		return @"max";
	}
	else if (INAggregationOperatorCount == aggOperator) {
		return @"count";
	}
	
	DLog(@"Unknown aggregation operator type, returning empty string");
	return @"";
}

