//
//  INDateRangeFormatterTest.m
//  IndivoFramework
//
//  Created by Pascal Pfiffner on 12/8/11.
//  Copyright (c) 2011 Harvard Medical School. All rights reserved.
//

#import "INDateRangeFormatterTest.h"
#import "INDateRangeFormatter.h"

@implementation INDateRangeFormatterTest

// All code under test must be linked into the Unit Test bundle
- (void)testMath
{
    STAssertTrue((1 + 1) == 2, @"Compiler isn't feeling well today :-(");
	
	INDateRangeFormatter *f = [INDateRangeFormatter new];
	UIFont *sysFont = [UIFont systemFontOfSize:17.f];
	NSLocale *us = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
	NSLocale *uk = [[NSLocale alloc] initWithLocaleIdentifier:@"en_UK"];
	NSLocale *de = [[NSLocale alloc] initWithLocaleIdentifier:@"de"];
	NSDate *start = [NSDate dateWithTimeIntervalSince1970:1313000000];				// Aug 10, 2011
	NSDate *diffYear = [start dateByAddingTimeInterval:400 * 24 * 3600];			// Sep 13, 2012
	NSDate *diffMonth = [start dateByAddingTimeInterval:40 * 24 * 3600];			// Sep 19, 2011
	NSDate *sameMonth = [start dateByAddingTimeInterval:4 * 24 * 3600];				// Aug 14, 2011
	
	// Testing no range
	STAssertNil([f formattedRange], @"We should get nil");
	
	// Testing "Since"
	f.locale = us;
	f.from = start;
	STAssertNotNil([f formattedRange], @"We should get a range");
	STAssertEqualObjects(@"Since August 10, 2011", [f formattedRange], @"<xx");
	STAssertEqualObjects(@"Since 8/10/11", [f formattedRangeForMaxWidth:20.f withFont:sysFont], @"<xx");
	
	f.locale = uk;
	STAssertEqualObjects(@"Since 10 August 2011", [f formattedRange], @"<xx");
	STAssertEqualObjects(@"Since 10/08/2011", [f formattedRangeForMaxWidth:20.f withFont:sysFont], @"<xx");
	
	f.locale = de;
	STAssertEqualObjects(@"Since 10. August 2011", [f formattedRange], @"<xx");
	STAssertEqualObjects(@"Since 10.08.11", [f formattedRangeForMaxWidth:20.f withFont:sysFont], @"<xx");
	
	// Testing "Until"
	f.locale = us;
	f.from = nil;
	f.to = start;
	STAssertNotNil([f formattedRange], @"We should get a range");
	STAssertEqualObjects(@"Until August 10, 2011", [f formattedRange], @"<xx");
	STAssertEqualObjects(@"Until 8/10/11", [f formattedRangeForMaxWidth:20.f withFont:sysFont], @"<xx");
	
	f.locale = uk;
	STAssertEqualObjects(@"Until 10 August 2011", [f formattedRange], @"<xx");
	STAssertEqualObjects(@"Until 10/08/2011", [f formattedRangeForMaxWidth:20.f withFont:sysFont], @"<xx");
	
	f.locale = de;
	STAssertEqualObjects(@"Until 10. August 2011", [f formattedRange], @"<xx");
	STAssertEqualObjects(@"Until 10.08.11", [f formattedRangeForMaxWidth:20.f withFont:sysFont], @"<xx");
	
	// Testing real range
	f.locale = us;
	f.from = start;
	f.to = diffYear;
	STAssertNotNil([f formattedRange], @"We should get a range");
	STAssertEqualObjects(@"August 10, 2011 - September 13, 2012", [f formattedRange], @"<xx");
	STAssertEqualObjects(@"8/10/11 - 9/13/12", [f formattedRangeForMaxWidth:20.f withFont:sysFont], @"<xx");
	
	f.to = diffMonth;
	STAssertEqualObjects(@"August 10 - September 19, 2011", [f formattedRange], @"<xx");
	STAssertEqualObjects(@"8/10 - 9/19/2011", [f formattedRangeForMaxWidth:20.f withFont:sysFont], @"<xx");
	
	f.to = sameMonth;
	STAssertEqualObjects(@"August 10-14, 2011", [f formattedRange], @"<xx");
	STAssertEqualObjects(@"Aug 10-14, 2011", [f formattedRangeForMaxWidth:20.f withFont:sysFont], @"<xx");
	
	
	f.locale = uk;
	f.to = diffYear;
	STAssertNotNil([f formattedRange], @"We should get a range");
	STAssertEqualObjects(@"10 August 2011 - 13 September 2012", [f formattedRange], @"<xx");
	STAssertEqualObjects(@"10/08/2011 - 13/09/2012", [f formattedRangeForMaxWidth:20.f withFont:sysFont], @"<xx");
	
	f.to = diffMonth;
	STAssertEqualObjects(@"10 August - 19 September 2011", [f formattedRange], @"<xx");
	STAssertEqualObjects(@"10/8 - 19/9/2011", [f formattedRangeForMaxWidth:20.f withFont:sysFont], @"<xx");
	
	f.to = sameMonth;
	STAssertEqualObjects(@"10-14 August 2011", [f formattedRange], @"<xx");
	STAssertEqualObjects(@"10-14 Aug 2011", [f formattedRangeForMaxWidth:20.f withFont:sysFont], @"<xx");
	
	
	f.locale = de;
	f.to = diffYear;
	STAssertNotNil([f formattedRange], @"We should get a range");
	STAssertEqualObjects(@"10. August 2011 - 13. September 2012", [f formattedRange], @"<xx");
	STAssertEqualObjects(@"10.08.11 - 13.09.12", [f formattedRangeForMaxWidth:20.f withFont:sysFont], @"<xx");
	
	f.to = diffMonth;
	STAssertEqualObjects(@"10. August - 19. September 2011", [f formattedRange], @"<xx");
	STAssertEqualObjects(@"10.8. - 19.9.2011", [f formattedRangeForMaxWidth:20.f withFont:sysFont], @"<xx");
	
	f.to = sameMonth;
	STAssertEqualObjects(@"10-14. August 2011", [f formattedRange], @"<xx");
	STAssertEqualObjects(@"10-14. Aug 2011", [f formattedRangeForMaxWidth:20.f withFont:sysFont], @"<xx");
}


@end
