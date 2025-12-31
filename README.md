# Google SignIn SDK in Appcelerator Titanium

<img src="example/demo.gif" height="300" alt="Google SignIn" />   
   
## Summary

Ti.GoogleSignIn is an open-source project to support the Google SignIn SDK in Appcelerator's Titanium.

## Requirements

  * Titanium SDK 9.2.0+
  * Ti.PlayServices (Android)

### Download

[Releases page](https://github.com/hansemannn/titanium-google-signin/releases)

### Setup

#### iOS Setup

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

#### Android Setup

The Android setup is made possible by the excellent work from [chmiiller](https://github.com/chmiiller) and [AppWerft](https://github.com/AppWerft) in the [Ti.GoogleSignIn](https://github.com/AppWerft/Ti.GoogleSignIn) repository. Thank you!

##### Permissions in manifest

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.GET_ACCOUNTS" />
<uses-permission android:name="android.permission.USE_CREDENTIALS" />
```

##### ⚠️ PLEASE NOTE!

**You will need to use the Web ClientID from Google instead of an Android one.**

<img src="example/webkey.png" alt="Google Play Console" />

##### Obtaining a SHA-1 with Titanium

##### ⚠️ HELPER!
You can use the [titanium-google-signin-diagnose.sh](https://github.com/hansemannn/titanium-google-signin/blob/master/android/example/titanium-google-signin-diagnose.sh) to assist you on creating the fingerprints for the Firebase Console.

A comprehensive diagnostic tool that automatically extracts SHA-1/SHA-256 fingerprints from all Android keystores (debug, Titanium SDK, and production) and provides step-by-step Firebase Console setup instructions for Google Sign-In integration in Titanium apps.

##### If you want to it manually:
In order to use Google Sign In in your app you will need to provide an SHA-1 certificate fingerprint to Firebase Console.
You will need to provide a debug and a distribution SHA-1 fingerprint for your app. 

On Titanium, the debug SHA-1 has to be generated from the `dev_keystore` file from your Titanium SDK android folder located at "mobilesdk/<platform>/<sdk_version>/android/dev_keystore".

On macOS, for example, it would rely on: "~/Library/Application\ Support/Titanium/mobilesdk/osx/13.0.0.GA/android/dev_keystore".   

And an command line example for it would be:   
```
keytool -list -v -keystore ~/Library/Application\ Support/Titanium/mobilesdk/osx/13.0.0.GA/android/dev_keystore
```   

You can also follow same instructions used to configure a map in your Android app from [Titanium Docs](https://titaniumsdk.com/guide/Titanium_SDK/Titanium_SDK_How-tos/Location_Services/Google_Maps_v2_for_Android.html#obtain-and-add-a-google-api-key).   

This repo also [includes a video](https://www.youtube.com/watch?v=eNE-sLmcJGs) on how to create an Android app on Firebase to better explain the process.   

As Titanium's documentation recommends, when submitting your app to Google Play Store you will need to create a production .keystore file, so don't forget to create another SHA-1 for this key and remember to add it also as another "fingerprint" on Firebase.   

Note that some users have reported problems when submitting new apps to the Play Store, where the Google Login stop working on production. A solution found was to get another SHA-1 fingerprint from the Google Play app's dashboard and add this fingerprint to Firebase.

These fingerprints could be found on your Google Play Console, under the "Release Management" menu on the left and then on "App signing".
Here is an example on how it looks like:   
<img src="example/play_store_sha1.png" width="483" alt="Google Play Console" />   

#### Example

Initialize the module by setting the Google SignIn API key you can get from the Google API Console.
```javascript
import GoogleSignIn from 'ti.googlesignin';

GoogleSignIn.initialize({
    // Required properties
    clientID: '<client-id>',

    // Optional properties:
    serverClientID: '<server-client-id>',
    scopes: ['https://www.googleapis.com/auth/plus.login'], // See https://developers.google.com/identity/protocols/googlescopes for more
    loginHint: 'Titanium rocks!',
    hostedDomain: 'https://my-hosted-domain.com',
    openIDRealm: 'my-openID-realm',
});
```
#### Methods

- [x] `signIn()`
- [x] `signInSilently()`
- [x] `signOut()`
- [x] `disconnect()`
- [x] `hasAuthInKeychain` -> Boolean
- [x] `currentUserImageURLWithSize(size)` -> String (iOS only)

#### Properties

* [x] `language` (String, `get|set`, iOS, only)
* [x] `currentUser` (Dictionary, `get`)
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
- [x] `logout`

The login event also includes the current user via the `user` property.

### Android Module v8.0.0 Changes:
- **Breaking**: Requires `compileSdkVersion: 34`, supported by Titanium SDK `12.7.0.GA`, or backported to `12.6.x` via [this PR](https://github.com/tidev/titanium-sdk/pull/14200).
- Added `cancel() –> Boolean` method to cancel the ongoing sign-in flow. Returns `true` if cancelled successfully.
- `signIn()` now supports following properties:
    - `loginType`
        - `LOGIN_TYPE_DIALOG` - to show old dialog based sign-in.
        - `LOGIN_TYPE_SHEET` - to show new bottom sheet based sign-in.
    - `filterByAuthorizedAccounts` - [read more here](https://developers.google.com/identity/android-credential-manager/android/reference/com/google/android/libraries/identity/googleid/GetGoogleIdOption.Builder) for these new properties
    - `autoSelectEnabled`
    - `requestVerifiedPhoneNumber`
    - `nonce`
- Removed:
   - `hasAuthInKeychain()`
   - `signInSilently()`
   - `disconnect()`
   - `currentUser` property
   - `error` event, use `success` property from `login` event (parity with iOS).
- `login` event changes:
    - use `success` property to check for a successful sign-in or an error.
    - `user.profile` only have:
        - name
        - email
        - image
        - givenName
        - familyName
        - displayName
    - `user.authentication` only have:
        - idToken
    - Added new `errorType`:
        - `ERROR_TYPE_UNKNOWN`
        - `ERROR_TYPE_NO_CREDENTIAL`
        - `ERROR_TYPE_TOKEN_PARSING`
        - `ERROR_TYPE_INTERRUPTED`
        - `ERROR_TYPE_CANCELLED`

### Build

If you want to build the module from the source, you need to check some things beforehand:
- Set the `TITANIUM_SDK_VERSION` inside the `ios/titanium.xcconfig` file to the Ti.SDK version you want to build with.
- Build the project with `appc run -p ios --build-only`
- Check the [releases tab](https://github.com/hansemannn/titanium-google-signin/releases) for stable pre-packaged versions of the module

### Example

For a basic example, check the demo in `example/app.js`. For a full sample-app, check out the demo in `example/sample-app`.

### Author

Hans Knoechel ([@hansemannnn](https://twitter.com/hansemannnn) / [Web](http://hans-knoechel.de))

### License

Apache 2.0

### Contributing

Code contributions are greatly appreciated, please submit a new [pull request](https://github.com/hansemannn/titanium-google-signin/pull/new/master)!
