//
//  IndivoMockServer.h
//  IndivoFramework
//
//  Created by Pascal Pfiffner on 3/27/12.
//  Copyright (c) 2012 Harvard Medical School. All rights reserved.
//

#import "IndivoServer.h"


/**
 *	Mock Server to replace IndivoServer for unit testing.
 *	When performing a call it parses the request URL and immediately calls the "didFinishSuccessfully:returnObject:" method, supplying data of the respective
 *	call if the request URL was understood by the mock server.
 */
@interface IndivoMockServer : IndivoServer

@property (nonatomic, strong) IndivoRecord *mockRecord;
@property (nonatomic, copy) NSDictionary *mockMappings;				///< Two dimensional, first level is the method (GET, POST, ...), second a mapping path -> fixture.xml

- (NSString *)readFixture:(NSString *)fileName;


@end
