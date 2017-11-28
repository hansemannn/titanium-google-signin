# Google SignIn iOS SDK in Appcelerator Titanium
[![Build Status](https://travis-ci.org/hansemannn/titanium-google-signin.svg?branch=master)](https://travis-ci.org/hansemannn/titanium-google-signin) [![License](http://hans-knoechel.de/shields/shield-license.svg?v=1)](./LICENSE) [![Contact](http://hans-knoechel.de/shields/shield-twitter.svg?v=1)](http://twitter.com/hansemannnn)

<img src="example/demo.gif" height="300" alt="Google SignIn" />   
   
## Summary
Ti.GoogleSignIn is an open-source project to support the Google SignIn iOS-SDK in Appcelerator's Titanium Mobile. The Android version of this module is linked as a sub-module from [AppWerft/Ti.GoogleSignIn](https://github.com/AppWerft/Ti.GoogleSignIn) in `android/`. Thanks for that!

## Requirements
  * Titanium SDK 5.5.1.GA or later
  * iOS 7.1 or later

### Download
  * [Stable release](https://github.com/hansemannn/Ti.GoogleSignIn/releases)
  * [![gitTio](http://hans-knoechel.de/shields/shield-gittio.svg)](http://gitt.io/component/ti.googlesignin)

### Setup
Unpack the module and place it inside the `modules/iphone/` folder of your project.
Edit the modules section of your `tiapp.xml` file to include this module:
```xml
<modules>
    <module platform="iphone">ti.googlesignin</module>
</modules>
```
Add the following URL types to your plist section of the tiapp.xml:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>google</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <!-- Example: com.googleusercontent.apps.123456789-xxxxxxxx -->
            <string>YOUR_REVERSE_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

Initialize the module by setting the Google SignIn API key you can get from the Google API Console.
```javascript
var Google = require('ti.googlesignin');
Google.initialize({
    clientID: '<client-id>',

    // Optional properties:
    serverClientID: '<server-client-id>',
    scopes: ['https://www.googleapis.com/auth/plus.login'], // See https://developers.google.com/identity/protocols/googlescopes for more
    language: 'de', // Or 'de-DE', 'en-US', etc.
    loginHint: 'Titanium rocks!',
    hostedDomain: 'https://my-hosted-domain.com',
    shouldFetchBasicProfile: false, // Default: true
    openIDRealm: 'my-openID-realm',
});
```
#### Methods
- [x] `signIn()`
- [x] `signInSilently()`
- [x] `signOut()`
- [x] `disconnect()`
- [x] `hasAuthInKeychain` -> Boolean
- [x] `currentUserImageURLWithSize(size)` -> String

#### Properties
* [x] `currentUser` (Dictionary)
    * `id` (String) 
    * `scopes` (Array<String>) 
    * `serverAuthCode` (String) 
    * `hostedDomain` (String) 
    * `profile` (Dictionary)
        * `name` (String)
        * `givenName` (String)
        * `familyName` (String)
        * `email` (String)
        * `hasImage` (Boolean)
    * `authentication` (Dictionary)
        * `clientID` (String)
        * `accessToken` (String)
        * `accessTokenExpirationDate` (Date)
        * `refreshToken` (String)
        * `idToken` (String)
        * `idTokenExpirationDate` (Date)

#### Events
- [x] `login`
- [x] `disconnect`
- [x] `cancel`
- [x] `error`
- [x] `load`
- [x] `open`
- [x] `close`

The `login`- and `disconnect` events include a `user` key that includes the following user-infos:
```
id, scopes, serverAuthCode, hostedDomain, profile, authentication
```

### Build
If you want to build the module from the source, you need to check some things beforehand:
- Ensure to build the module with Titanium SDK 6.1.0 and later in order to use the new `TI_MODULE_VERSION` macro that generates the framework-search-paths
- Set the `TITANIUM_SDK_VERSION` inside the `ios/titanium.xcconfig` file to the Ti.SDK version you want to build with.
- Build the project with `appc run -p ios --build-only`
- Check the [releases tab](https://github.com/hansemannn/ti.googlesignin/releases) for stable pre-packaged versions of the module

### Example
For a full example, check the demo in `example/app.js`.

### Author
Hans Knoechel ([@hansemannnn](https://twitter.com/hansemannnn) / [Web](http://hans-knoechel.de))

### License
Apache 2.0

### Contributing
Code contributions are greatly appreciated, please submit a new [pull request](https://github.com/hansemannn/titanium-google-signin/pull/new/master)!
