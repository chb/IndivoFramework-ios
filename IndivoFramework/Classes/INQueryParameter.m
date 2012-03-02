//
//  INQueryParameter.m
//  IndivoFramework
//
//  Created by Pascal Pfiffner on 3/2/12.
//  Copyright (c) 2012 Harvard Medical School. All rights reserved.
//

#import "INQueryParameter.h"
#import "INURLLoader.h"

@implementation INQueryParameter

@synthesize offset, limit;
@synthesize orderBy, descending;
@synthesize status;


- (id)init
{
	if ((self = [super init])) {
		limit = 100;
		status = INDocumentStatusActive;
	}
	return self;
}


/**
 *	Initializes the receiver with information found in the query string
 */
- (id)initWithQueryString:(NSString *)aQuery
{
	if ((self = [self init]) && [aQuery length] > 0) {
		NSDictionary *params = [INURLLoader queryFromRequestString:aQuery];
		
		NSString *valueStr = [params objectForKey:@"offset"];
		if ([valueStr length] > 0) {
			offset = ABS([valueStr integerValue]);
		}
		valueStr = [params objectForKey:@"limit"];
		if ([valueStr length] > 0) {
			limit = ABS([valueStr integerValue]);
		}
		
		valueStr = [params objectForKey:@"order_by"];
		if ([valueStr length] > 0) {
			descending = [@"-" isEqualToString:[valueStr substringToIndex:1]];
			self.orderBy = descending ? [valueStr substringFromIndex:1] : valueStr;
		}
		
		valueStr = [params objectForKey:@"status"];
		if ([valueStr length] > 0) {
			self.status = documentStatusFor(valueStr);
		}
	}
	return self;
}



#pragma mark - To URL String
- (NSArray *)queryParameters
{
	NSMutableArray *params = [NSMutableArray array];
	
	if (offset > 0) {
		[params addObject:[NSString stringWithFormat:@"offset=%d", offset]];
	}
	if (limit > 0) {
		[params addObject:[NSString stringWithFormat:@"limit=%d", limit]];
	}
	if ([orderBy length] > 0) {
		[params addObject:[NSString stringWithFormat:@"order_by=%@%@", (descending ? @"-" : @""), orderBy]];
	}
	if (INDocumentStatusUnknown != status) {
		[params addObject:[NSString stringWithFormat:@"status=%@", stringStatusFor(status)]];
	}
	
	return params;
}




@end
