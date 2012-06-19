IndivoFramework for iOS
=======================

## NOTE  ##
The instructions have been updated for Indivo 2.0, but the framework source that works with 2.0 has not yet been merged into master. If you follow the instructions under *Getting the Framework* you will checkout the `dev_two` branch and all is going to be fine. Don't worry. We got you covered. Breathe.

## 

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
[techdoc]: http://docs.indivohealth.org/projects/indivo-x-ios-framework/en/latest/


## Getting the Framework ##

The best way to get the framework is to check out the project via [git][]. Open Terminal, navigate to the desired directory, and execute:

	$ git clone git://github.com/chb/IndivoFramework-ios.git
	$ cd IndivoFramework-ios
	$ git checkout dev_two
	$ git submodule init
	$ git submodule update

You now have the latest source code of the framework as well as the subprojects we use and the Medications Sample App.

**NOTE** that the step `git checkout dev_two` is required while the 2.0 framework version has not been merged into the master branch. Once 2.0 is final this step is no longer required.

[git]: http://git-scm.com/


## Running the Medications Sample App ##

The framework repo contains a sample application as a submodule ([https://github.com/chb/IndivoMedicationsExample-ios][meds]), thus if you followed above instructions correctly you should now also have the sample app code.

Make sure you open the **IndivoFramework.xcworkspace** file in Xcode and not the lonely IndivoFramework.xcproject file. In Xcode, in the file manager to the left, you now see the README at top, the med sample project and below the framework project itself (the latter two in blue). Expand the framework project and the `IndivoFramework` folder inside it.

You should see a red file `IndivoConfig.h` and below the file `IndivoConfig-default.h`; the red file is where the server settings go and required by the framework (though you CAN change these settings in code via properties later). You can simply right-click the default file, select "Show in Finder" and in the Finder duplicate and rename it to `IndivoConfig.h`. Back in Xcode you'll notice that the file is no longer red. You can now edit its contents to hit your own Indivo server or use our public sandbox, for which you use these settings:

	#define kIndivoFrameworkServerURL = @"http://sandbox.indivohealth.org:8000"
	#define kIndivoFrameworkUIServerURL = @"http://sandbox.indivohealth.org:80"
	#define kIndivoFrameworkAppId = @"sampleios@apps.indivo.org"
	#define kIndivoFrameworkConsumerKey = @"sampleiosapp@apps.indivo.org"
	#define kIndivoFrameworkConsumerSecret = @"youriosapp"

After that, choose the target **Medications Sample** and hit the **Run** button and the sample app should run and be ready to connect to the sandbox.

[meds]: https://github.com/chb/IndivoMedicationsExample-ios


## Server Side Setup ##

The Indivo Server you want to connect to needs to know your app. This means you will have to tell the server to add your app as a **user_app**. You will get a **consumer_key** and a **consumer_secret** which you need during Framework Setup, without these your app will not receive any data from the server. Keep your consumer_key and consumer_secret safe in order to prevent somebody posing as your App. For general installation instructions see the [Indivo Installation Instructions][installation].

As of Indivo 1.0, the setup for an App using the framework in `server/utils/indivo_data.xml` will look like this:

    <user_app name='Medications Mobile' email='medsample@apps.indivo.org'>
        <consumer_key>medsample@apps.indivo.org</consumer_key>
        <secret>your-crazy-secure-secret-string</secret>
        <frameable>False</frameable>
        <has_ui>False</has_ui>
        <start_url_template>
          	indivo-framework:///did_select_record?record_id={record_id}&amp;carenet_id={carenet_id}
        </start_url_template>
        <callback_url></callback_url>
    </user_app>

The `has_ui` setting currently means "show up in the UI Server sidebar", so we want to set this to false. We may rework the App manifest in the future so these settings may change.

When the server knows about your App, you're ready to use the framework.
	

[installation]: http://docs.indivohealth.org/en/latest/index.html#indivo-administrators


## Framework Setup ##

These are the instructions if you want to add the framework to **your own** app, these steps were already performed for the medications sample app.

1. Add the IndivoFramework project to your Xcode **workspace**

2. Link your App with the necessary frameworks and libraries:  
	Open your project's build settings, under "Link Binary With Libraries" add:
	
	`libIndivoFramework.a`  
	`Security.framework`
	
	Do **not** add `libMPOAuthMobile.a` as this will result in a linker error

3. Make sure the compiler finds the header files:  
	Open your project's build settings, look for **User Header Search Paths** (USER_HEADER_SEARCH_PATHS), and add:
	
	`$(BUILT_PRODUCTS_DIR)`, with the checkbox to the left checked (which means *recursive* search)

4. The linker needs an additional flag:  
	Still in your project's build settings, look for **Other Linker Flags** (OTHER_LDFLAGS), and add:
	
	`-ObjC`  
	
	This must be added so IndivoFramework can be used as a static library, otherwise class categories will not work and your app will crash.

5. You will have to provide initial server settings in the configuration file, but you can always change the properties in code later on (e.g. if your App can connect to different servers).  
	Copy the file `IndivoConfig-default.h` in the **framework** project (not your own app) to `IndivoConfig.h` and adjust it to suit your needs. The setting names should define NSStrings and are named:
	- `kIndivoFrameworkServerURL`  (The Server URL)
	- `kIndivoFrameworkUIServerURL`  (The UI Server URL)
	- `kIndivoFrameworkAppId`  (The App id)
	- `kIndivoFrameworkConsumerKey`  (Your consumerKey)
	- `kIndivoFrameworkConsumerSecret`  (Your consumerSecret)

6. Add `IndivoConfig.h` to the Indivo Framework target. (In the default project Xcode should already know the file but show it in red because it's not in the repository. As soon as you create it, Xcode should find it and you're all good).

7. In your code, include the header files (where needed) as user header files:

		import "IndivoServer.h"
		import "IndivoDocuments.h"

You are now ready to go!


## Using the Framework ##

### Instantiating the server ###

Make your app delegate (or some other class) the server delegate and instantiate an `IndivoServer`:  

	IndivoServer *indivo = [IndivoServer serverWithDelegate:<# your server delegate #>];
	
Make sure you implement the required delegate methods in your server delegate! This **indivo** instance is now your connection to the Indivo server.


### Selecting a record ###
	
Add a button to your app which calls `IndivoServer`'s `selectRecord:` method when tapped. Like all server methods in the framework, this method receives a callback once the operation completed. If record selection was successful, the `activeRecord` property on your indivo server instance will be set (an object of class `IndivoRecord`) and you can use the activeRecord object to receive and create documents for this record.

Here's an example that shows the record-selection page and upon completion alerts an error (if there is one) and does nothing otherwise:

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
		                                 callback:^(BOOL success, NSDictionary *userInfo) {
		
		// error fetching medications
		if (!success) {
			NSError *error = [userInfo objectForKey:INErrorKey];
			// handle the error. If error is nil, the operation was cancelled
		}
		
		// successfully fetched medications, reload table view
		else  {
			self.medications = [userInfo objectForKey:INResponseArrayKey];
			[self.tableView reloadData];
		}
	}];


### Adding record documents ###

To create new documents, you create a new instance of a given document type and, once all properties are set, push it to the server:

	NSError *error = nil;
	IndivoMedication *newMed = (IndivoMedication *)[self.indivo.activeRecord addDocumentOfClass:[IndivoMedication class] error:&error];
	if (!newMed) {
		NSLog(@"Error: %@", [error localizedDescription]);
	}
	else {
		// edit medication properties
		newMed.name = [INCodedValue new];
		newMed.name.text = @"L-Ascorbic Acid";
		newMed.brandName = [INCodedValue new];
		newMed.brandName.text = @"Vitamin C";
		newMed.brandName.abbrev = @"vitamin-c";
		// ...
		
		// push to the server
		[newMed push:^(BOOL didCancel, NSString *errorString) {
			if (errorString) {
				// handle the error
			}
			
			// successfully pushed
			else if (!userDidCancel) {
			}
		}];
	}


### Changing status, archiving, updating (replacing) and more

`IndivoDocument` has methods to allow you to archive, void and replace documents in the same fashion. Note that **replacing** is Indivo's process for updating a document since no data is ever destroyed.
	
	// update the name of our newly created medication
	newMed.name.text = @"L-Ascorbic Acid Tablets";
	[newMed replace:^(BOOL didCancel, NSString *errorString) {
		if (errorString) {
			// handle the error
		}
	}];


### Sending Messages to records

You can send messages to a record's inbox like follows:

	[activeRecord sendMessage:@"New Medication"
					 withBody:@"A new medication has just been added to your record"
					   ofType:INMessageTypePlaintext
					 severity:INMessageSeverityLow
				  attachments:[NSArray arrayWithObject:newMed]
					 callback:^(BOOL userDidCancel, NSString *__autoreleasing errorMessage) {
						 if (errorMessage) {
							 // handle error message
						 }
					 }];


Of course there's more you can do, see the [technical API documentation][techdoc] for more.


Acknowledgements
----------------

This work was supported by a grant from the **[Novartis Foundation, formerly Ciba-Geigy-Jubilee-Foundation](http://www.jubilaeumsstiftung.novartis.com/)**.

