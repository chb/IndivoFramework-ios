//
//  AppDelegate.m
//  ClassGenerator
//
//  Created by Pascal Pfiffner on 1/20/12.
//  Copyright (c) 2012 Children's Hospital Boston. All rights reserved.
//

#import "AppDelegate.h"
#import "INClassGenerator.h"


@interface AppDelegate ()

- (void)gotLog:(NSNotification *)aNotification;

@end


@implementation AppDelegate

@synthesize window, directoryField, output;


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gotLog:) name:INClassGeneratorDidProduceLogNotification object:nil];
	directoryField.stringValue = @"/Library/Indivo/indivo_server/schemas/doc_schemas/";
	
	output.font = [NSFont fontWithName:@"Monaco" size:12.f];
	output.textColor = [NSColor whiteColor];
}

- (IBAction)run:(id)sender
{
	[output setString:@""];
	[[INClassGenerator new] run];
}


- (void)gotLog:(NSNotification *)aNotification
{
	NSString *log = [[aNotification userInfo] objectForKey:INClassGeneratorLogStringKey];
	if ([log length] > 0) {
		NSRange range = NSMakeRange([[output string] length], 0);
		
		[output replaceCharactersInRange:range withString:[NSString stringWithFormat:@"%@\n", log]];
	}
}


@end
