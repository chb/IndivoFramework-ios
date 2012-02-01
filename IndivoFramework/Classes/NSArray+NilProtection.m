//
//  NSArray+NilProtection.m
//  MedReconcile
//
//  Created by Pascal Pfiffner on 11/7/11.
//  Copyright (c) 2011 Children's Hospital Boston. All rights reserved.
//

#import "NSArray+NilProtection.h"

@implementation NSArray (NilProtection)

/**
 *	Returns the first object or nil
 */
- (id)firstObject
{
	if ([self count] > 0) {
		return [self objectAtIndex:0];
	}
	return nil;
}

/**
 *	Returns the object at given index or nil, if the index is out of bounds
 */
- (id)objectOrNilAtIndex:(NSUInteger)index
{
	if ([self count] > index) {
		return [self objectAtIndex:index];
	}
	return nil;
}

@end



@implementation NSMutableArray (NilProtection)

- (void)addObjectIfNotNil:(id)anObject
{
	if (anObject) {
		[self addObject:anObject];
	}
}

- (void)unshiftObjectIfNotNil:(id)anObject
{
	if (anObject) {
		[self insertObject:anObject atIndex:0];
	}
}


@end