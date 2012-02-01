//
//  NSArray+NilProtection.h
//  MedReconcile
//
//  Created by Pascal Pfiffner on 11/7/11.
//  Copyright (c) 2011 Children's Hospital Boston. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (NilProtection)

- (id)firstObject;
- (id)objectOrNilAtIndex:(NSUInteger)index;

@end


@interface NSMutableArray (NilProtection) 

- (void)addObjectIfNotNil:(id)anObject;
- (void)unshiftObjectIfNotNil:(id)anObject;

@end
