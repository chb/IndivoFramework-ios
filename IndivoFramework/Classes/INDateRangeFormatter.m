/*
 IndivoConfig.h
 IndivoFramework
 
 Created by Pascal Pfiffner on 12/8/11.
 Copyright (c) 2011 Harvard Medical School
 
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

#import "INDateRangeFormatter.h"


@interface INDateRangeFormatter ()

@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, copy) NSArray *dateFormats;								///< This array contains date formatting string, with descending verbosity in descending order

@end


@implementation INDateRangeFormatter

@synthesize from, to;
@synthesize sinceString, untilString;
@synthesize dateFormatter, dateFormats;
@synthesize locale;


+ (id)rangeFormatterFrom:(NSDate *)fromDate to:(NSDate *)toDate
{
	INDateRangeFormatter *f = [self new];
	f.from = fromDate;
	f.to = toDate;
	
	return f;
}



#pragma mark - Actual Formatting Methods
/**
 *	Calls "formattedRangeForMaxWith:withFont:" with a width of CGFLOAT_MAX and no font
 */
- (NSString *)formattedRange
{
	return [self formattedRangeForMaxWidth:CGFLOAT_MAX withFont:nil];
}

/**
 *	Calls "formattedRangeForMaxWidth:withFont:" with the label's bounds and font
 */
- (NSString *)formattedRangeForLabel:(UILabel *)aLabel
{
	return [self formattedRangeForMaxWidth:[aLabel bounds].size.width withFont:aLabel.font];
}

/**
 *	Formats the date range according to the given dates and tries to find the optimal format to fit into the given width.
 *	@param maxWidth The maximum width the string should have, not guaranteed that the requirement will be met.
 *	@param aFont The font to be used to determine whether the string fits or not.
 *	@return A formatted string representing the date range
 */
- (NSString *)formattedRangeForMaxWidth:(CGFloat)maxWidth withFont:(UIFont *)aFont
{
	NSString *formatted = nil;
	self.dateFormatter.locale = self.locale;
	
	if (from && to) {
		NSCalendar *cal = [NSCalendar currentCalendar];
		NSDateComponents *fromComp = [cal components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:from];
		NSDateComponents *toComp = [cal components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:to];
		
		// same year
		if ([fromComp year] == [toComp year]) {
			
			// same month
			if ([fromComp month] == [toComp month]) {
				/*
				 March 12-28, 2011						// Get format for dMMMMY, add "-d" after first "d"
				 12-28. March 2011
				 
				 Mar 12-28, 2011						// Get format for dMMMY, add "-d" after first "d"
				 12-28. Mar 2011
				 */
				NSString *standardFormat = [NSDateFormatter dateFormatFromTemplate:@"dMMMMY" options:0 locale:dateFormatter.locale];
				NSString *ourFormat = [standardFormat stringByReplacingOccurrencesOfString:@"d" withString:@"d-##"];
				self.dateFormatter.dateFormat = ourFormat;
				NSString *fromString = [dateFormatter stringFromDate:from];
				formatted = [fromString stringByReplacingOccurrencesOfString:@"-##" withString:[NSString stringWithFormat:@"-%d", [toComp day]]];
				
				if (aFont && [formatted sizeWithFont:aFont].width > maxWidth) {
					standardFormat = [NSDateFormatter dateFormatFromTemplate:@"dMMMY" options:0 locale:dateFormatter.locale];
					ourFormat = [standardFormat stringByReplacingOccurrencesOfString:@"d" withString:@"d-##"];
					self.dateFormatter.dateFormat = ourFormat;
					fromString = [dateFormatter stringFromDate:from];
					formatted = [fromString stringByReplacingOccurrencesOfString:@"-##" withString:[NSString stringWithFormat:@"-%d", [toComp day]]];
				}
			}
			else {
				/*
				 March 28 - September 12, 2011			// dMMMM - dMMMMY
				 28. March - 12. September 2011
				 
				 Mar 28 - Sep 12, 2011					// dMMM - dMMMY
				 28. Mar - 12. Sep 2011
				 
				 3/28 - 9/12/11							// dM - dMy
				 28.3 - 12.9.11
				 */
				self.dateFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"dMMMM" options:0 locale:dateFormatter.locale];
				NSString *fromString = [dateFormatter stringFromDate:from];
				self.dateFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"dMMMMY" options:0 locale:dateFormatter.locale];
				NSString *toString = [dateFormatter stringFromDate:to];
				formatted = [NSString stringWithFormat:@"%@ - %@", fromString, toString];
				
				if (aFont && [formatted sizeWithFont:aFont].width > maxWidth) {
					self.dateFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"dMMM" options:0 locale:dateFormatter.locale];
					fromString = [dateFormatter stringFromDate:from];
					self.dateFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"dMMMY" options:0 locale:dateFormatter.locale];
					toString = [dateFormatter stringFromDate:to];
					formatted = [NSString stringWithFormat:@"%@ - %@", fromString, toString];
					
					if (aFont && [formatted sizeWithFont:aFont].width > maxWidth) {
						self.dateFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"dM" options:0 locale:dateFormatter.locale];
						fromString = [dateFormatter stringFromDate:from];
						self.dateFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"dMY" options:0 locale:dateFormatter.locale];
						toString = [dateFormatter stringFromDate:to];
						formatted = [NSString stringWithFormat:@"%@ - %@", fromString, toString];
					}
				}
			}
		}
		else {
			/*
			 March 28, 2010 - September 12, 2011		// NSDateFormatterLongStyle - NSDateFormatterLongStyle
			 28. March 2010 - 12. September 2011
			 
			 Mar 28, 2010 - Sep 12, 2011				// NSDateFormatterMediumStyle - NSDateFormatterMediumStyle
			 28. Mar 2010 - 12. Sep 2011
			 
			 3/28/10 - 9/12/11							// NSDateFormatterShortStyle - NSDateFormatterShortStyle
			 28.3.10 - 12.9.11
			 */
			NSString *formatString = @"%@ - %@";
			NSDateFormatterStyle styles[3] = { NSDateFormatterLongStyle, NSDateFormatterMediumStyle, NSDateFormatterShortStyle };
			NSUInteger i = 0;
			do {
				dateFormatter.dateStyle = styles[i];
				formatted = [NSString stringWithFormat:formatString, [dateFormatter stringFromDate:from], [dateFormatter stringFromDate:to]];
				i++;
			}
			while (aFont && i < 3 && [formatted sizeWithFont:aFont].width > maxWidth);
		}
	}
	else if (from || to) {
		/*
		 Since March 28, 2011							// NSDateFormatterLongStyle
		 Since 28. March 2011
		 
		 Since Mar 28, 2011								// NSDateFormatterMediumStyle
		 Since 28. Mar 2011
		 
		 Since 3/28/11									// NSDateFormatterShortStyle
		 Since 28.3.11
		 */
		NSString *string = from ? self.sinceString : self.untilString;
		NSDate *date = from ? from : to;
		NSString *formatString = @"%@ %@";
		NSDateFormatterStyle styles[3] = { NSDateFormatterLongStyle, NSDateFormatterMediumStyle, NSDateFormatterShortStyle };
		NSUInteger i = 0;
		do {
			dateFormatter.dateStyle = styles[i];
			formatted = [NSString stringWithFormat:formatString, string, [dateFormatter stringFromDate:date]];
			i++;
		}
		while (aFont && i < 3 && [formatted sizeWithFont:aFont].width > maxWidth);
	}
	else {
		// we have no dates
	}
	
	return formatted;
}




#pragma mark - KVC
- (NSString *)sinceString
{
	if (!sinceString) {
		self.sinceString = NSLocalizedString(@"Since", nil);
	}
	return sinceString;
}

- (NSString *)untilString
{
	if (!untilString) {
		self.untilString = NSLocalizedString(@"Until", nil);
	}
	return untilString;
}

- (NSDateFormatter *)dateFormatter
{
	if (!dateFormatter) {
		self.dateFormatter = [NSDateFormatter new];
		dateFormatter.dateStyle = NSDateFormatterLongStyle;
		dateFormatter.timeStyle = NSDateFormatterNoStyle;
	}
	return dateFormatter;
}

- (NSLocale *)locale
{
	if (!locale) {
		return [NSLocale currentLocale];
	}
	return locale;
}


@end
