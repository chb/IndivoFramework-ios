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

@synthesize window, inDirField, outDirField, output;


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gotLog:) name:INClassGeneratorDidProduceLogNotification object:nil];
	
	// setup
	output.font = [NSFont fontWithName:@"Monaco" size:12.f];
	output.textColor = [NSColor whiteColor];
	
	// get directories from settings
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	inDirField.stringValue = [defaults objectForKey:@"lastInputDirectory"];
	outDirField.stringValue = [defaults objectForKey:@"lastOutputDirectory"];
}


/**
 *	Lets an INClassGenerator instance run over all XSDs it finds
 */
- (IBAction)run:(id)sender
{
	if ([sender respondsToSelector:@selector(setEnabled:)]) {
		[sender setEnabled:NO];
	}
	
	// start
	[output setString:@"Starting up...\n"];
	INClassGenerator *generator = [INClassGenerator new];
	[generator runFrom:inDirField.stringValue into:outDirField.stringValue callback:^(BOOL userDidCancel, NSString *__autoreleasing errorMessage) {
		if (errorMessage) {
			[self addLog:errorMessage];
		}
		if (userDidCancel) {
			[self addLog:@"Cancelled"];
		}
		else {
			NSString *doneString = [NSString stringWithFormat:@"Done. %d schemas parsed, %d classes generated", generator.numSchemasParsed, generator.numClassesGenerated];
			[self addLog:doneString];
		}
		if ([sender respondsToSelector:@selector(setEnabled:)]) {
			[sender setEnabled:YES];
		}
	}];
}



#pragma mark - GUI
- (void)chooseInputDir:(id)sender
{
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	[panel setAllowsMultipleSelection:NO];
	[panel setCanChooseDirectories:YES];
	[panel setCanChooseFiles:YES];
	
	// run
	[panel beginSheetModalForWindow:window completionHandler:^(NSInteger result) {
		if (NSOKButton == result) {
			NSString *path = [[panel URL] path];
			[[NSUserDefaults standardUserDefaults] setObject:path forKey:@"lastInputDirectory"];
			inDirField.stringValue = path;
		}
	}];
}

- (void)chooseOutputDir:(id)sender
{
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	[panel setAllowsMultipleSelection:NO];
	[panel setCanChooseDirectories:YES];
	[panel setCanChooseFiles:NO];
	
	// run
	[panel beginSheetModalForWindow:window completionHandler:^(NSInteger result) {
		if (NSOKButton == result) {
			NSString *path = [[panel URL] path];
			[[NSUserDefaults standardUserDefaults] setObject:path forKey:@"lastOutputDirectory"];
			outDirField.stringValue = path;
		}
	}];
}



#pragma mark - Logging
- (void)gotLog:(NSNotification *)aNotification
{
	NSString *log = [[aNotification userInfo] objectForKey:INClassGeneratorLogStringKey];
	if ([log length] > 0) {
		[self addLog:log];
	}
}

- (void)addLog:(NSString *)aString
{
	NSRange range = NSMakeRange([[output string] length], 0);
	[output replaceCharactersInRange:range withString:[NSString stringWithFormat:@"%@\n", aString]];
}


@end
