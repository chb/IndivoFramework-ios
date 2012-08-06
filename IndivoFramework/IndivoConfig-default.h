/*
 IndivoConfig.h
 IndivoFramework
 
 Created by Pascal Pfiffner on 1/9/12.
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


/**
 *	This file should be named "IndivoConfig.h" and added to your project. It contains the information necessary so the Indivo Framework
 *	can connect to your server.
 */

/// The URL to your server, with port number (if other than 80)
#define kIndivoFrameworkServerURL @"http://sandbox.indivohealth.org:8000"

/// The URL to the UI (!) server, with port number (if other than 80)
#define kIndivoFrameworkUIServerURL @"http://sandbox.indivohealth.org"

/// Your App's id, consumer key and -secret
#define kIndivoFrameworkAppId @"sampleios@apps.indivo.org"
#define kIndivoFrameworkConsumerKey @"sampleiosapp@apps.indivo.org"
#define kIndivoFrameworkConsumerSecret @"youriosapp"

/// Your pillbox API key, needed for some medication functions (you can make it an empty string or nil if you don't have one)
#define kPillboxAPIKey @""

