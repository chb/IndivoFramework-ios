/*
 IndivoMedication+Report.m
 IndivoFramework
 
 Created by Pascal Pfiffner on 9/26/11.
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

#import "IndivoMedication+Report.h"
#import "IndivoRecord.h"
#import "INXMLNode.h"
#import "INObjects.h"

#import "INURLLoader.h"
#import "INXMLParser.h"
#import "IndivoConfig.h"

@implementation IndivoMedication (Report)


#pragma mark - Convenience Methods
/**
 *	Tries to find the best name to display
 */
- (NSString *)displayName
{
	if ([self.drugName.title length] > 0) {
		return self.drugName.title;
	}
	if ([self.drugName.identifier length] > 0) {
		return [NSString stringWithFormat:@"RxNorm: %@", self.drugName.identifier];
	}
	return @"Unknown";
}



#pragma mark - Pill Image
- (UIImage *)pillImage
{
	return [self cachedObjectOfType:@"pillImage"];
}

/**
 *	This method tries to load an image of the medication, caching it automatically (once implemented)
 */
- (void)loadPillImageBypassingCache:(BOOL)bypass callback:(INCancelErrorBlock)callback
{
	CANCEL_ERROR_CALLBACK_OR_LOG_USER_INFO(callback, YES, [NSDictionary dictionary])
	/*
	/// @todo search in cache
	BOOL inCache = NO;
	if (!inCache || bypass) {
		NSString *apiKey = kPillboxAPIKey;			/// @attention You will need your personal API key for the server to respond
		
		// load all pills with our ingredient
		NSString *url = [NSString stringWithFormat:@"http://pillbox.nlm.nih.gov/PHP/pillboxAPIService.php?key=%@&ingredient=%@&has_image=1", apiKey, [self.name.text stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
		
		DLog(@"->  %@", url);
		INURLLoader *loader = [INURLLoader loaderWithURL:[NSURL URLWithString:url]];
		[loader getWithCallback:^(BOOL userDidCancel, NSString *__autoreleasing errorMessage) {
			if (errorMessage) {
				CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(callback, NO, errorMessage)
			}
			else if (!userDidCancel) {
				
				// only try to parse XML
				if ([loader.responseString length] > 5 && [@"<?xml" isEqualToString:[loader.responseString substringToIndex:5]]) {
					NSError *error = nil;
					INXMLNode *root = [INXMLParser parseXML:loader.responseString error:&error];
					if (!root) {
						CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(callback, NO, [error localizedDescription])
					}
					
					// got pills matching the ingredient, find our rxcui
					else {
						NSString *want = self.name.value;
						NSMutableArray *found = [NSMutableArray array];
						NSArray *pills = [root childrenNamed:@"pill"];
						for (INXMLNode *pill in pills) {
							if ([want isEqualToString:[[pill childNamed:@"RXCUI"] text]]) {
								DLog(@"Image URL: http://pillbox.nlm.nih.gov/assets/small/%@sm.jpg", [[pill childNamed:@"image_id"] text]);
								[found addObject:pill];
							}
						}
						
						// found exact rxcui matches
						if ([found count] > 0) {
							for (INXMLNode *node in found) {
								NSString *imageId = [[node childNamed:@"image_id"] text];
								
								// has an image!
								if ([imageId length] > 0) {
									NSString *imgURL = [NSString stringWithFormat:@"http://pillbox.nlm.nih.gov/assets/small/%@sm.jpg", imageId];
									DLog(@"Image URL: %@", imgURL);
									
									INURLLoader *imgLoader = [INURLLoader loaderWithURL:[NSURL URLWithString:imgURL]];
									imgLoader.expectBinaryData = YES;
									[imgLoader getWithCallback:^(BOOL userDidCancel, NSString *__autoreleasing errorMessage) {
										if (!errorMessage && !userDidCancel) {
											UIImage *pImage = [UIImage imageWithData:imgLoader.responseData];
											NSError *cError = nil;
											if (![self cacheObject:pImage asType:@"pillImage" error:&cError]) {
												DLog(@"Error caching: %@", [cError localizedDescription]);
											}
										}
										CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(callback, NO, errorMessage)
									}];
									return;
								}
							}
						}
					}
				}		// end if (XML)
				
				CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(callback, NO, nil)
			}
		}];
	}				// */
}



#pragma mark - Report Path
+ (NSString *)reportType
{
	return @"Medication";
}


@end
