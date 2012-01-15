/*
 INURLFetcher.h
 IndivoFramework
 
 Created by Pascal Pfiffner on 11/07/11.
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

#import <Foundation/Foundation.h>
#import "Indivo.h"


/**
 *	The fetcher is an accessor-class to INURLLoader objects; for example if you want to queue up loading multiple URLs you
 *	can use one fetcher instead of handling multiple INURLLoader instances yourself.
 */
@interface INURLFetcher : NSObject

@property (nonatomic, readonly, copy) NSArray *successfulLoads;					///< Contains INURLLoader instances which loaded with an HTTP response < 400
@property (nonatomic, readonly, copy) NSArray *failedLoads;						///< Contains all INURLLoader instances that failed to load for any reason

- (void)getURLs:(NSArray *)anURLArray callback:(INCancelErrorBlock)aCallback;
- (void)cancel;
- (BOOL)isIdle;


@end
