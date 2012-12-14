/*
 {{ CLASS_NAME }}.m
 IndivoFramework
 
 Created by {{ AUTHOR }} on {{ DATE }}.
 Copyright (c) {{ YEAR }} Boston Children's Hospital
 
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

#import "{{ CLASS_NAME }}.h"
#import "IndivoDocument.h"


@implementation {{ CLASS_NAME }}
{% if CLASS_SYNTHESIZE %}
@synthesize {{ CLASS_SYNTHESIZE }};
{% endif %}

+ (NSString *)nodeName
{
	return @"{{ CLASS_NODENAME }}";
}

+ (NSString *)nodeType
{
	return @"{{ CLASS_TYPENAME }}";
}

+ (void)load
{
	[IndivoDocument registerDocumentClass:self];
}

{% if CLASS_PROPERTY_MAP %}
+ (NSDictionary *)propertyClassMapper
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
			{{ CLASS_PROPERTY_MAP }},
			nil];
}
{% endif %}

{% if CLASS_ATTRIBUTE_NAMES %}
+ (NSArray *)attributeNames
{
	NSArray *myAttributes = [NSArray arrayWithObjects:{{ CLASS_ATTRIBUTE_NAMES }}, nil];
	NSArray *superAttr = [super attributeNames];
	if (superAttr) {
		myAttributes = [superAttr arrayByAddingObjectsFromArray:myAttributes];
	}
	return myAttributes;
}
{% endif %}

@end
