//
//  AppDelegate.h
//  ClassGenerator
//
//  Created by Pascal Pfiffner on 1/20/12.
//  Copyright (c) 2012 Children's Hospital Boston. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (nonatomic, assign) IBOutlet NSTextField *inDirField;
@property (nonatomic, assign) IBOutlet NSTextField *outDirField;
@property (nonatomic, assign) IBOutlet NSTextView *output;

- (IBAction)run:(id)sender;
- (void)addLog:(NSString *)aString;


@end
