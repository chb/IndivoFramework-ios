IndivoFramework for iOS
=======================

These are the developer instructions on how to use [IndivoFramework][self], an iOS framework to interface with **[Indivo X][indivo]**, an open-source **personally controlled health record** (PCHR) system.

### Requirements ###

- #### Objective-C ####
The Indivo Framework is an Objective-C framework using **ARC** ([Automatic Reference Counting][arc]), requiring **iOS 4.0 or greater**. You can use it as a static library (or directly import the code files into your App project) as documented below.  
The framework utilizes a fork of [MPOAuth][], an OAuth framework by Karl Adam (matrixPointer):

- #### Indivo Server ####
For most operations the framework talks to the [Indivo Server][] directly, however for login and record selection needs to talk to the corresponding [Indivo UI Server][]. Indivo X 1.0 will support Apps running the framework out of the box.

[self]: https://github.com/chb/IndivoFramework-ios
[indivo]: http://www.indivohealth.org/
[arc]: http://clang.llvm.org/docs/AutomaticReferenceCounting.html
[mpoauth]: https://github.com/chb/MPOAuth
[indivo server]: https://github.com/chb/indivo_server
[indivo ui server]: https://github.com/chb/indivo_ui_server


## Technical Documentation ##

This README contains setup and a few basic usage instructions, however the code itself is fully documented using [Doxygen][] and a technical documentation is [available online][techdoc]. A Doxyfile is included so you can generate the documentation by yourself.

The easiest way to do this is to open the Doxyfile with DoxyWizard and press "Run". This will create an HTML documentation in `Docs/html` and a ready-to-build LaTeX documentation in `Docs/latex`.

#### Embedding the documentation into Xcode ####
After building the documentation like mentioned above, you just need to install it:
    $ cd IndivoFramework-ios/Docs/html
    $ make install
After you relaunch Xcode, the documentation should be available in the Organizer and can be accessed like the standard Cocoa documentation by `ALT`-clicking code parts.

[doxygen]: http://www.doxygen.org/
[techdoc]: javascript:alert('URL TBD')


## App Setup ##

1. The best way to get the framework is to check out the project via [git][]. Open Terminal, navigate to the desired directory, and execute:
	- `git clone <HOST>/IndivoFramework.git`
	- `cd IndivoFramework`
	- `git submodule init`
	- `git submodule update`

	You now have the latest source code of the framework as well as the subprojects we use.

2. Add the IndivoFramework project to your Xcode workspace

3. Link your App with the necessary frameworks and libraries:  
	Open your project's build settings, under "Link Binary With Libraries" add:
	- `libIndivoFramework.a`
	- `Security.framework`
	- `libxml2.dylib`  
	Do **not** add `libMPOAuthMobile.a` as this will result in a linker error

4. Make sure the compiler finds the header files:  
	Open your project's build settings, look for **User Header Search Paths** (USER_HEADER_SEARCH_PATHS), and add:

	`$(BUILT_PRODUCTS_DIR)`, with *recursive* checked

5. The linker needs an additional flag:  
	Still in your project's build settings, look for **Other Linker Flags** (OTHER_LDFLAGS), and add:
	
	`-ObjC`
	
	This must be added so IndivoFramework can be used as a static library, otherwise class categories will not work and your app will crash.

6. In your code, include the header files (where needed) as user header files:
	
	`#import "IndivoServer.h"`

[git]: http://git-scm.com/


## Server Side Setup ##

The Indivo Server you want to connect to needs to know your app. This means you'll have to tell the server to add your app as a **user_app**. You'll get a **consumer_key** and a **consumer_secret** which you need in Framework Setup.
	
>>>> ADD INSTRUCTIONS


## Framework Use ##

Once setup is complete, you're ready to use the Indivo framework in your App. There are five settings that the framework must know in order to work with your server:

- The Server URL
- The UI Server URL
- The app id
- Your consumerKey
- Your consumerSecret

You will have to provide initial settings for these in the configuration file (see below), but you can always change the properties in code later on (e.g. if your App can connect to different servers).


### Setup a server instance ###

1. Update the file `IndivoSetup.h` in the **framework** project (not your own app) to suit your needs. The setting names should define NSStrings and are named:
	- `kIndivoFrameworkServerURL`
	- `kIndivoFrameworkUIServerURL`
	- `kIndivoFrameworkAppId`
	- `kIndivoFrameworkConsumerKey`
	- `kIndivoFrameworkConsumerSecret`

2. In your app delegate (or some other class), instantiate an `IndivoServer` object and set the delegate:  

		IndivoServer *indivo = [IndivoServer serverWithDelegate:<% your server delegate %>];
	
	Make sure you implement the required delegate methods in your server delegate! This **indivo** instance is now your connection to the Indivo server.


### Selecting a record ###
	
Add a button to your app which calls `IndivoServer`'s `selectRecord:` method when tapped. Like all server methods in the framework, this method receives a callback once the operation completed. If record selection was successful, the `activeRecord` property on your indivo server instance will be set (an object of class `IndivoRecord`) and you can use the activeRecord object to receive and create documents for this record.

Here's an example that shows the record-selection page and upon completion alerts an error (if there is one) and does nothing else:

	[self.indivo selectRecord:^(BOOL userDidCancel, NSString *errorMessage) {

		// there was an error selecting the record
		if (errorMessage) {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed to connect"
															message:errorMessage
														   delegate:nil
												  cancelButtonTitle:@"OK"
												  otherButtonTitles:nil];
			[alert show];
		}
		
		// did successfully select a record
		else if (!userDidCancel) {
		}
	}];


### Retrieving record documents ###

The methods that send or load data to/from the server all sport a **callback block**. Here's a simple example on how you get a patient's current medications into an `NSArray`:

	[self.indivo.activeRecord fetchReportsOfClass:[IndivoMedication class]
	                                   withStatus:INDocumentStatusActive
		                                 callback:^(BOOL userDidCancel, NSString *errorMessage) {
		
		// error fetching medications
		if (!success) {
			NSString *errorMessage = [[userInfo objectForKey:INErrorKey] localizedDescription];
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed to get medications"
	                                                        message:errorMessage
	                                                       delegate:nil
	                                              cancelButtonTitle:@"OK"
	                                              otherButtonTitles:nil];
			[alert show];
		}
		
		// successfully fetched medications, reload table view
		else if (!userDidCancel) {
			self.medications = [userInfo objectForKey:INResponseArrayKey];
			[self.tableView reloadData];
		}
	}];


### Adding record documents ###

To create new documents, you create a new instance of a given document type and, once all properties are set, push it to the server:

	NSError *error = nil;
	IndivoMedication *newMed = (IndivoMedication *)[self.indivo.activeRecord addDocumentOfClass:[IndivoMedication class] error:&error];
	if (!newMed) {
		DLog(@"Error: %@", [error localizedDescription]);
	}
	else {
		// ... edit medication properties
		
		// push to the server
		[newMed push:^(BOOL didCancel, NSString *errorString) {
			if (errorString) {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error pushing to server"
				                                                message:errorString
				                                               delegate:nil
				                                      cancelButtonTitle:@"OK"
				                                      otherButtonTitles:nil];
				[alert show];
			}
			
			// successfully pushed
			else if (!userDidCancel) {
			}
		}];
	}


### Changing status, archiving, updating (replacing) and more

Of course there's more you can do, see the [technical API documentation][techdoc] for more.

